---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.6.
weight: 20
---

When you upgrade from Istio 1.5.x to Istio 1.6.x, you need to consider the changes on this page.
These notes detail the instances, which purposefully break backwards compatibility with Istio 1.5.x.  
The notes also mention instances, which preserve backwards compatibility while introducing new behavior.
Instances are only included if the new behavior would be unexpected to a user of Istio 1.5.x.

Currently, Istio doesn't skip-level upgrades. If you are using Istio 1.4, upgrade to Istio 1.5 first, and then upgrade to Istio 1.6. If you upgrade from versions earlier than Istio 1.4, you should first disable Galley's configuration validation. Disable the validation with the following commands:

## Readiness port number change for Gateways

If you are using port 15020 to check the health of your Istio ingressgateway with your Kubernetes network load balancer, you will need to update the port number from 15020 to 15021.

## Removal of legacy Helm charts

Istio 1.4 introduced a [new way to install Istio](/blog/2019/introducing-istio-operator/) using the in-cluster Operator or `istioctl install` command. Part of this change meant deprecating the old Helm charts in 1.5. Many new Istio features rely on the new installation method. As a result, Istio 1.6 doesn't include the old Helm installation charts.

Go to the [Istio 1.5 Upgrade Notes](/news/releases/1.5.x/announcing-1.5/upgrade-notes/#control-plane-restructuring) before you continue because Istio 1.5 introduced several changes not present in the legacy installation method, such as Istiod and telemetry v2.

To safely upgrade from the legacy installation method that uses Helm charts, perform a [control plane revision](/blog/2020/multiple-control-planes/). Upgrading in-place is not supported. Upgrading could result in downtime unless you perform a [canary upgrade](/docs/setup/upgrade/#canary-upgrades).

## Support ended for `v1alpha1` security policy

Istio 1.6 no longer supports the following security policy APIs:

- [`v1alpha1` authentication policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/)
- [`v1alpha1` RBAC policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.rbac.v1alpha1/) 

Istio 1.6 starts ignoring these `v1alpha1` security policy APIs.

Istio 1.6 replaced the `v1alpha1` authentication policy with the following APIs:

- The [`v1beta1` request authentication policy](/docs/reference/config/security/request_authentication) 
- The [`v1beta1` peer authentication policy](/docs/reference/config/security/peer_authentication)

Istio 1.6 replaces the `v1alpha1` RBAC policy APIs  with the [`v1beta1` authorization policy APIs](/docs/reference/config/security/authorization-policy/). 


To check if there is any `v1alpha1` security policy in the cluster, run the following commands:

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
$ kubectl get meshpolicies.authentication.istio.io --all-namespaces
$ kubectl get rbacconfigs.rbac.istio.io --all-namespaces
$ kubectl get clusterrbacconfigs.rbac.istio.io --all-namespaces
$ kubectl get serviceroles.rbac.istio.io --all-namespaces
$ kubectl get servicerolebindings.rbac.istio.io --all-namespaces
{{< /text >}}

To make sure not to accidentally apply any `v1alpha1` security policy in the future, remove the CRD of the `v1alpha1` security policy using the following commands:

{{< text bash >}}
$ kubectl delete crd policies.authentication.istio.io
$ kubectl delete crd meshpolicies.authentication.istio.io
$ kubectl delete crd rbacconfigs.rbac.istio.io
$ kubectl delete crd clusterrbacconfigs.rbac.istio.io
$ kubectl delete crd serviceroles.rbac.istio.io
$ kubectl delete crd servicerolebindings.rbac.istio.io
{{< /text >}}

## Istio configuration during installation

Historically, Istio deployed certain configuration objects as part of the installation. This caused problems with upgrades, a confusing user experience, and makes the installation less flexible. As a result, we minimized the configurations we ship as part of the installation.

This includes a variety of configurations:

- `global.mtls.enabled`: Configuration removed to avoid confusion. Configure a peer authentication policy to enable [strict mTLS](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode) instead.
* The default `Gateway` object, and associated `Certificate` object, are no longer installed by default. See the [Ingress task](/docs/tasks/traffic-management/ingress/) for information on configuring a Gateway.
* `Ingress` objects for telemetry addons are no longer created. See [Remotely Accessing Telemetry Addons](/docs/tasks/observability/gateways/) for more information on exposing these externally.
* The default `Sidecar` configuration was previously defined with an automatically created `Sidecar` resource. This has been changed to an internal implementation detail and should have no visible impact.

## Communicating with Istiod using External Workloads

This release makes the Istiod host cluster-local by default. This means that the Istio control plane is not accessible to workloads that reside outside the cluster. It is now recommended that external workloads access Istiod via the ingress gateway. This change was needed in order to support multicluster master/remote configurations. Future releases will remove this limitation.

Users may override this behavior in `MeshConfig`:

{{< text yaml >}}
values:
  meshConfig:
    serviceSettings:
      - settings:
          clusterLocal: false
        hosts:
          - "istiod.istio-system.svc.cluster.local"
{{< /text >}}
