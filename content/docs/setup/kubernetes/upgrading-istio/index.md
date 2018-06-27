---
title: Upgrading Istio
description: This guide demonstrates how to upgrade the Istio control plane and data plane independently.
weight: 70
keywords: [kubernetes,upgrading]
---

This page describes how to upgrade an existing Istio deployment (including both control plane and sidecar proxy) to a new release of Istio.
The upgrade process could involve new binaries as well as other changes like configuration and API schemas. The upgrade process may involve
some service downtime. To minimize downtime, please ensure your Istio control plane components and your applications are highly available
with multiple replicas.

In the following steps, we assume that the Istio components are installed and upgraded in the `istio-system` namespace.

## Control plane upgrade

The Istio control plane components include: Citadel, Ingress gateway, Egress gateway, Pilot, Policy, Telemetry and
Sidecar injector. We can use Kubernetes’ rolling update mechanism to upgrade the
control plane components.

First, generate the desired Istio control plane yaml file, e.g.

```command
$ helm template --namespace istio-system --set global.proxy.image=proxy \
  --values @install/kubernetes/helm/istio/values-istio.yaml@ \
  @install/kubernetes/helm/istio@ >> install/kubernetes/istio.yaml
```

or

```command
$ helm template --namespace istio-system --set global.proxy.image=proxy \
  --values @install/kubernetes/helm/istio/values-istio-auth.yaml@ \
  @install/kubernetes/helm/istio@ >> install/kubernetes/istio-auth.yaml
```

If using Kubernetes versions prior to 1.9, you should add `--set sidecarInjectorWebhook.enabled=false`.

Second, simply apply the new version of the desired Istio control plane yaml file directly, e.g.

```command
$ kubectl apply -f @install/kubernetes/istio.yaml@
```

or

```command
$ kubectl apply -f @install/kubernetes/istio-auth.yaml@
```

The rolling update process will upgrade all deployments and configmaps to the new version. After this process finishes,
your Istio control plane should be updated to the new version. Your existing application should continue to work without
any change, using the Envoy v1 proxy and the v1alpha1 route rules. If there is any critical issue with the new control plane,
you can rollback the changes by applying the yaml files from the old version.

## Sidecar upgrade

After the control plane upgrade, the applications already running Istio will still be using an older sidecar. To upgrade the sidecar,
you will need to re-inject it.

If you're using automatic sidecar injection, you can upgrade the sidecar
by doing a rolling update for all the pods, so that the new version of the
sidecar will be automatically re-injected. There are some tricks to reload
all pods. E.g. There is a [bash script](https://gist.github.com/jmound/ff6fa539385d1a057c82fa9fa739492e)
which triggers the rolling update by patching the grace termination period.

If you're using manual injection, you can upgrade the
sidecar by executing:

```command
$ kubectl replace -f <(istioctl kube-inject -f $ORIGINAL_DEPLOYMENT_YAML)
```

If the sidecar was previously injected with some customized inject config
files, you will need to change the version tag in the config files to the new
version and re-inject the sidecar as follows:

```command
$ kubectl replace -f <(istioctl kube-inject \
     --injectConfigFile inject-config.yaml \
     --filename $ORIGINAL_DEPLOYMENT_YAML)
```

## Migrating to the new networking APIs

Once you've upgraded the control plane and sidecar, you can gradually update your deployment to use the new Envoy sidecar.  You can do this by using
one of the options below:

- Add the following to your pod annotation for your deployment:

    ```yaml
    kind: Deployment
    ...
    spec:
      template:
        metadata:
          annotations:
            sidecar.istio.io/proxyImage: docker.io/istio/proxyv2:0.8.0
    ```

    Then replace your deployment with your updated application yaml file:

    ```command
    $ kubectl replace -f $UPDATED_DEPLOYMENT_YAML
    ```

or

- Use an `injectConfigFile` that has `docker.io/istio/proxyv2:0.8.0` as the proxy image.  If you don't have an `injectConfigFile`, you can
[generate one](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection).   `injectConfigFile` is recommended if you need to add
the `sidecar.istio.io/proxyImage` annotations in multiple deployment definitions.

    ```command
    $ kubectl replace -f <(istioctl kube-inject --injectConfigFile inject-config.yaml -f $ORIGINAL_DEPLOYMENT_YAML)
    ```

Next, use `istioctl experimental convert-networking-config` to convert your existing ingress or route rules:

1. If your yaml file contains more than the ingress definition such as deployment or service definition, move the ingress definition out to a separate yaml file for the `
istioctl experimental convert-networking-config` tool to process.

1. Execute the following to generate the new network config file, where replacing FILE*.yaml with your ingress file or deprecated route rule files.
*Tip: Make sure to feed all the files using `-f` for one or more deployments.*

    ```command
    $ istioctl experimental convert-networking-config -f FILE1.yaml -f FILE2.yaml -f FILE3.yaml > UPDATED_NETWORK_CONFIG.yaml
    ```

1. Edit `UPDATED_NETWORK_CONFIG.yaml` to update all namespace references to your desired namespace.
There is a known issue with the `convert-networking-config` tool where the `istio-system` namespace
is used incorrectly. Further, ensure the `hosts` value is correct.

1. Deploy the updated network config file.

    ```command
    $ kubectl replace -f UPDATED_NETWORK_CONFIG.yaml
    ```

When all your applications have been migrated and tested, you can repeat the Istio upgrade process, removing the
`--set global.proxy.image=proxy` option.  This will set the default proxy to `docker.io/istio/proxyv2` for all
sidecars injected in the future.

## Migrating per-service mutual TLS enablement via annotations to authentication policy

If you use service annotations to override global mutual TLS enablement for a service, you need to replace it with [authentication policy](/docs/concepts/security/authn-policy/) and [destination rules](/docs/concepts/traffic-management/rules-configuration/#destination-rules).

For example, if you install Istio with mutual TLS enabled, and disable it for service `foo` using a service annotation like below:

```yaml
kind: Service
metadata:
  name: foo
  namespace: bar
  annotations:
    auth.istio.io/8000: NONE
```

You need to replace this with this authentication policy and destination rule (deleting the old annotation is optional)

```yaml
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "disable-mTLS-foo"
  namespace: bar
spec:
  targets:
  - name: foo
    ports:
    - number: 8000
  peers:
---
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "disable-mTLS-foo"
  namespace: "bar"
spec:
  host: "foo"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
    portLevelSettings:
    - port:
        number: 8000
      tls:
        mode: DISABLE
```

If you already have destination rules for `foo`, you must edit that rule instead of creating a new one.
When create a new destination rule, make sure to include other settings, i.e `load balancer`, `connection pool` and `outlier detection` if necessary.
Finally, If `foo` doesn't have sidecar, you can skip authentication policy, but still need to add destination rule.

If 8000 is the only port that service `foo` provides (or you want to disable mutual TLS for all ports), the policies can be simplified as:

```yaml
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "disable-mTLS-foo"
    namespace: bar
  spec:
    targets:
    - name: foo
    peers:
---
apiVersion: "networking.istio.io/v1alpha3"
kind: "DestinationRule"
metadata:
  name: "disable-mTLS-foo"
  namespace: "bar"
spec:
  host: "foo"
trafficPolicy:
  tls:
    mode: DISABLE
```

## Migrating `mtls_excluded_services` config to destination rules

If you installed Istio with mutual TLS enabled, and used mesh config `mtls_excluded_services` to disable mutual TLS when connecting to these services (e.g kubernetes API server), you need to replace this by adding a destination rule. For example:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: "kubernetes-master"
  namespace: "default"
spec:
  host: "kubernetes.default.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: DISABLE
```
