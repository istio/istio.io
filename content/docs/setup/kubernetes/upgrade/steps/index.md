---
title: Upgrade Steps
description: Upgrade the Istio control plane and data plane independently.
weight: 25
keywords: [kubernetes,upgrading]
---

Follow this flow to upgrade an existing Istio deployment, including both the
control plane and the sidecar proxies, to a new release of Istio. The upgrade
process may install new binaries and may change configuration and API schemas.
The upgrade process may result in service downtime. To minimize downtime,
please ensure your Istio control plane components and your applications are
highly available with multiple replicas (as multi-replica Citadel is still
under development, Citadel should be deployed with one replica).

{{< warning >}}
Citadel does not support multiple instances. Running multiple Citadel instances
may introduce race conditions and lead to system outages.
{{< /warning >}}

This flow assumes that the Istio components are installed and upgraded in the
`istio-system` namespace.

{{< warning >}}
Be sure to check out the [upgrade notice](/docs/setup/kubernetes/upgrade/notice)
for a concise list of things you should know before upgrading your deployment to Istio 1.2.
{{< /warning >}}

{{< tip >}}
Istio does **NOT** support skip level upgrades.  Only upgrades from 1.1 to 1.2
are supported. If you are on an older version, please upgrade to 1.1 first.
{{< /tip >}}

## Upgrade steps

[Download the new Istio release](/docs/setup/kubernetes/#downloading-the-release)
and change directory to the new release directory.

### Control plane upgrade

Pilot, Galley, Policy, Telemetry and Sidecar injector.  Choose one of the following
two **mutually exclusive** options to update the control plane:

{{< tabset cookie-name="controlplaneupdate" >}}
{{< tab name="Kubernetes rolling update" cookie-value="k8supdate" >}}
You can use Kubernetes’ rolling update mechanism to upgrade the control plane components.
This is suitable for cases where `kubectl apply` was used to deploy the Istio components,
including configurations generated using
[helm template](/docs/setup/kubernetes/install/helm/#option-1-install-with-helm-via-helm-template).

1. Use `kubectl apply` to upgrade all of Istio's CRDs.  Wait a few seconds for the Kubernetes
   API server to commit the upgraded CRDs:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio-init/files/
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. Add Istio's core components to a Kubernetes manifest file, for example.

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio \
      --namespace istio-system > $HOME/istio.yaml
    {{< /text >}}

    If you want to enable [global mutual TLS](/docs/concepts/security/#mutual-tls-authentication),
    set `global.mtls.enabled` and `global.controlPlaneSecurityEnabled` to `true` for the last command:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --set global.mtls.enabled=true --set global.controlPlaneSecurityEnabled=true > $HOME/istio-auth.yaml
    {{< /text >}}

1. Upgrade the Istio control plane components via the manifest, for example:

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

    or

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-auth.yaml
    {{< /text >}}

The rolling update process will upgrade all deployments and configmaps to the new version.
After this process finishes, your Istio control plane should be updated to the new version.
Your existing application should continue to work without any change. If there is any
critical issue with the new control plane, you can rollback the changes by applying the
yaml files from the old version.
{{< /tab >}}

{{< tab name="Helm upgrade" cookie-value="helmupgrade" >}}
If you installed Istio using [Helm and Tiller](/docs/setup/kubernetes/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install),
the preferred upgrade option is to let Helm take care of the upgrade.

1. Upgrade the `istio-init` chart to update all the Istio [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) (CRDs).

    {{< text bash >}}
    $ helm upgrade --install --force istio-init install/kubernetes/helm/istio-init --namespace istio-system
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. Upgrade the `istio` chart:

    {{< text bash >}}
    $ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system
    {{< /text >}}

{{< /tab >}}
{{< /tabset >}}

### Sidecar upgrade

After the control plane upgrade, the applications already running Istio will
still be using an older sidecar. To upgrade the sidecar, you will need to re-inject it.

If you're using automatic sidecar injection, you can upgrade the sidecar
by doing a rolling update for all the pods, so that the new version of the
sidecar will be automatically re-injected. There are some tricks to reload
all pods. E.g. There is a sample [bash script](https://gist.github.com/jmound/ff6fa539385d1a057c82fa9fa739492e)
which triggers the rolling update by patching the grace termination period.

If you're using manual injection, you can upgrade the sidecar by executing:

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

## Migrating from `RbacConfig` to `ClusterRbacConfig`

The `RbacConfig` is deprecated due to a [bug](https://github.com/istio/istio/issues/8825). You must
migrate to `ClusterRbacConfig` if you are currently using `RbacConfig`. The bug reduces the scope of
the object to be namespace-scoped in some cases. The `ClusterRbacConfig` follows the exact same
specification as the `RbacConfig` but with the correct cluster scope implementation.

To automate the migration, we developed the `convert_RbacConfig_to_ClusterRbacConfig.sh` script.
The script is included in the [Istio installation package](/docs/setup/kubernetes/#downloading-the-release).

Download and run the script with the following command:

{{< text bash >}}
$ curl -L {{< github_file >}}/tools/convert_RbacConfig_to_ClusterRbacConfig.sh | sh -
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
