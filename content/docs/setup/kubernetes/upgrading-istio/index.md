---
title: Upgrading Istio
description: Demonstrates how to upgrade the Istio control plane and data plane independently.
weight: 37
keywords: [kubernetes,upgrading]
---

This page describes how to upgrade an existing Istio deployment (including both control plane and sidecar proxy) to a new release of Istio.
The upgrade process may install new binaries and may change configuration and API schemas. The upgrade process
may result in service downtime. To minimize downtime, please ensure your Istio control plane components and your applications
are highly available with multiple replicas.

In the following steps, we assume that the Istio components are installed and upgraded in the `istio-system` namespace.

## Upgrade steps

1. [Download the new Istio release](/docs/setup/kubernetes/download-release/)
and change directory to the new release directory.

1. Upgrade Istio's [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
via `kubectl apply`, and wait a few seconds for the CRDs to be committed to the Kubernetes API server:

{{< text bash >}}
$ kubectl apply -f @install/kubernetes/helm/istio/templates/crds.yaml@
{{< /text >}}

### Control plane upgrade

The Istio control plane components include: Citadel, Ingress gateway, Egress gateway, Pilot, Policy, Telemetry and
Sidecar injector.

#### Helm upgrade

If you installed Istio with [Helm](/docs/setup/kubernetes/helm-install/#option-2-install-with-helm-and-tiller-via-helm-install) the preferred upgrade option is to let Helm take care of the upgrade:

{{< text bash >}}
$ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system
{{< /text >}}

#### Kubernetes rolling update

You can also use Kubernetes’ rolling update mechanism to upgrade the control plane components. This is suitable for cases when Istio hasn't been installed using Helm.

First, generate the desired Istio control plane yaml file, e.g.

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio \
    --namespace istio-system > install/kubernetes/istio.yaml
{{< /text >}}

or

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio \
    --namespace istio-system --set global.mtls.enabled=true > install/kubernetes/istio-auth.yaml
{{< /text >}}

If using Kubernetes versions prior to 1.9, you should add `--set sidecarInjectorWebhook.enabled=false`.

Second, simply apply the new version of the desired Istio control plane yaml file directly, e.g.

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio.yaml
{{< /text >}}

or

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-auth.yaml
{{< /text >}}

The rolling update process will upgrade all deployments and configmaps to the new version. After this process finishes,
your Istio control plane should be updated to the new version. Your existing application should continue to work without
any change, using the Envoy v1 proxy and the v1alpha1 route rules. If there is any critical issue with the new control plane,
you can rollback the changes by applying the yaml files from the old version.

### Sidecar upgrade

After the control plane upgrade, the applications already running Istio will still be using an older sidecar. To upgrade the sidecar,
you will need to re-inject it.

If you're using automatic sidecar injection, you can upgrade the sidecar
by doing a rolling update for all the pods, so that the new version of the
sidecar will be automatically re-injected. There are some tricks to reload
all pods. E.g. There is a [bash script](https://gist.github.com/jmound/ff6fa539385d1a057c82fa9fa739492e)
which triggers the rolling update by patching the grace termination period.

If you're using manual injection, you can upgrade the
sidecar by executing:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}

If the sidecar was previously injected with some customized inject configuration
files, you will need to change the version tag in the configuration files to the new
version and re-inject the sidecar as follows:

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject \
     --injectConfigFile inject-config.yaml \
     --filename $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}

## Migrating per-service mutual TLS enablement via annotations to authentication policy

If you use service annotations to override global mutual TLS enablement for a service, you need to replace it with
[authentication policy](/docs/concepts/security/#authentication-policies) and [destination rules](/docs/concepts/traffic-management/#destination-rules).

For example, if you install Istio with mutual TLS enabled, and disable it for service `foo` using a service annotation like below:

{{< text yaml >}}
kind: Service
metadata:
  name: foo
  namespace: bar
  annotations:
    auth.istio.io/8000: NONE
{{< /text >}}

You need to replace this with this authentication policy and destination rule (deleting the old annotation is optional)

{{< text yaml >}}
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
{{< /text >}}

If you already have destination rules for `foo`, you must edit that rule instead of creating a new one.
When create a new destination rule, make sure to include other settings, i.e `load balancer`, `connection pool` and `outlier detection` if necessary.
Finally, If `foo` doesn't have sidecar, you can skip authentication policy, but still need to add destination rule.

If 8000 is the only port that service `foo` provides (or you want to disable mutual TLS for all ports), the policies can be simplified as:

{{< text yaml >}}
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
{{< /text >}}

## Migrating the `mtls_excluded_services` configuration to destination rules

If you installed Istio with mutual TLS enabled, and used the mesh configuration option `mtls_excluded_services` to
disable mutual TLS when connecting to these services (e.g Kubernetes API server), you need to replace this by adding a destination rule. For example:

{{< text yaml >}}
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
{{< /text >}}

## Migrating the `RbacConfig` to `ClusterRbacConfig`

The `RbacConfig` is deprecated due to a [bug](https://github.com/istio/istio/issues/8825). You must
migrate to `ClusterRbacConfig` if you are currently using `RbacConfig`. The bug reduces the scope of
the object to be namespace-scoped in some cases. The `ClusterRbacConfig` follows the exact same
specification as the `RbacConfig` but with the correct cluster scope implementation.

To automate the migration, we developed the `convert_RbacConfig_to_ClusterRbacConfig.sh` script.
The script is included in the [Istio installation package](/docs/setup/kubernetes/download-release).

Download and run the script with the following command:

{{< text bash >}}
$ curl -L {{% github_file %}}/tools/convert_RbacConfig_to_ClusterRbacConfig.sh | sh -
{{< /text >}}

The script automates the following operations:

1. The script creates the cluster RBAC configuration with same specification as the existing RBAC configuration
   because Kubernetes doesn't allow the value of `kind:` in a custom resource to change after it's created.

    For example, if you have the following RBAC configuration:

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: RbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]
    {{< /text >}}

    The script creates the following cluster RBAC configuration:

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]
    {{< /text >}}

1. The script applies the configuration and waits for a few seconds to let the configuration to take effect.

1. The script deletes the previous RBAC configuration custom resource after applying the cluster RBAC
   configuration successfully.
