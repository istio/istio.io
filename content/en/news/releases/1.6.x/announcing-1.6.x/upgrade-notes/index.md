---
title: Upgrade Notes
description: Important Changes to consider when upgrading to Istio 1.6.
weight: 20
---

When you upgrade from Istio 1.5.x to Istio 1.6.x, you need to consider the changes on this page.
1.5.x to Istio 1.6.x. Here, we detail cases where we intentionally broke backwards
compatibility. We also mention cases where backwards compatibility was preserved
but new behavior was introduced that would be surprising to someone familiar with
the use and operation of Istio 1.5.

{{< tip >}}
Istio does not currently support skip-level upgrades. For example, if you are still using Istio 1.4, we recommend first upgrading to Istio 1.5. However, if you choose to upgrade from previous version, you must first disable Galley configuration validation. This can be done by adding `--enable-validation=false` to the Galley deployment and removing the `istio-galley` `ValidatingWebhookConfiguration`
{{< /tip >}}

## Readiness port number change for Gateways

If you are using port 15020 to check the health of your Istio ingressgateway with your Kubernetes network load balancer, you will need to update the port number from 15020 to 15021.

## Removal of legacy Helm charts

In Istio 1.4 we introduced a [new way to install Istio](/blog/2019/introducing-istio-operator/), using the in-cluster Operator or `istioctl install` command. As part of this effort, we deprecated the old Helm charts in 1.5. Over time, we implemented many of the new Istio features only in these new installation methods. As a result, we have decided to remove the old installation Helm charts in Istio 1.6.

We recommend reviewing the [Istio 1.5 Upgrade Notes](/news/releases/1.5.x/announcing-1.5/upgrade-notes/#control-plane-restructuring) before continuing, because we introduced several changes in Istio 1.5 that were not present in the legacy installation method, such as Istiod and Telemetry V2.

You can now safely upgrade from the legacy Helm charts using a [Control Plane Revision](/blog/2020/multiple-control-planes/). In place upgrade is not supported and may result in downtime, so please follow the [Canary Upgrade](/docs/setup/upgrade/#canary-upgrades) steps.

## v1alpha1 security policy is not supported anymore

Istio 1.6 no longer supports the [`v1alpha1` authentication policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/) and [`v1alpha1` RBAC policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.rbac.v1alpha1/), these `v1alpha1` APIs will be ignored starting 1.6.

Instead, Istio 1.6 has split the [`v1alpha1` authentication policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/) and [`v1alpha1` RBAC policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.rbac.v1alpha1/) into the [`v1beta1` Request Authentication Policy](/docs/reference/config/security/request_authentication) and the [`v1beta1` Peer Authentication Policy](/docs/reference/config/security/peer_authentication). The [`v1alpha1` RBAC policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.rbac.v1alpha1/) has been replaced by the [`v1beta1` Authorization Policy](/docs/reference/config/security/authorization-policy/). Please migrate to these new resources before upgrading.

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
