---
title: Upgrade Notes
description: Important Changes to consider when upgrading to Istio 1.6.
weight: 20
---

This page describes changes you need to be aware of when upgrading from Istio
1.5.x to Istio 1.6.x. Here, we detail cases where we intentionally broke backwards
compatibility. We also mention cases where backwards compatibility was preserved
but new behavior was introduced that would be surprising to someone familiar with
the use and operation of Istio 1.5.

## Removal of legacy Helm charts

In Istio 1.4 we introduced a [new way to install Istio](/blog/2019/introducing-istio-operator/), utilizing the in-cluster Operator or `istioctl install` command. As part of this effort, we deprecated the old Helm charts. Over time, many of the new features added to Istio have been implemented only in these new installation methods. As a result, we have decided to remove the old installation Helm charts in Istio 1.6.

Because there have been a number of changes introduced in Istio 1.5 that were not present in the legacy installation method, such as Istiod and Telemetry V2, we recommend reviewing the [Istio 1.5 Upgrade Notes](/news/releases/1.5.x/announcing-1.5/upgrade-notes/#control-plane-restructuring) before continuing.

Upgrade from the legacy Helm charts can now be safely done using a [Control Plane Revision](/blog/2020/multiple-control-planes/). In place upgrade is not supported and may result in downtime, so please follow the [Canary Upgrade](/docs/setup/upgrade/#canary-upgrades) steps.

{{< tip >}}
Istio does not currently support skip-level upgrades. If you are still using Istio 1.4, we recommend first upgrading to Istio 1.5. However, if you do choose to upgrade from previous version, you must first disable Galley configuration validation. This can be done by adding `--enable-validation=false` to the Galley deployment and removing the `istio-galley` `ValidatingWebhookConfiguration`
{{< /tip >}}

## v1alpha1 security policy is not supported anymore

Istio 1.6 no longer supports the [`v1alpha1` authentication policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/) and [`v1alpha1` RBAC policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.rbac.v1alpha1/), the `v1alpha1` API will have no effect and will be ignored starting 1.6.

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

To make sure not to apply any `v1alpha1` security policy accidentally in the future, remove the CRD of the `v1alpha1` security policy with the following commands:

{{< text bash >}}
$ kubectl delete crd policies.authentication.istio.io
$ kubectl delete crd meshpolicies.authentication.istio.io
$ kubectl delete crd rbacconfigs.rbac.istio.io
$ kubectl delete crd clusterrbacconfigs.rbac.istio.io
$ kubectl delete crd serviceroles.rbac.istio.io
$ kubectl delete crd servicerolebindings.rbac.istio.io
{{< /text >}}

# Istio configuration during installation

Historically, Istio has deployed certain configuration objects as part of the installation. This has caused problems with upgrades, confusing user experience, and makes the installation less flexible. As a result, we have minimized the configurations we ship as part of the installation.

This includes a variety of different configurations:

* The `global.mtls.enabled` previously enabled strict mTLS. This should instead be done by directly configuring a `PeerAuthentication` policy for [strict mTLS](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode)
* The default `Gateway` object, and associated `Certificate` object, are no longer installed by default. See the [Ingress task](/docs/tasks/traffic-management/ingress/) for information on configuring a Gateway.
* `Ingress` objects for telemetry addons are no longer created. See [Remotely Accessing Telemetry Addons](/docs/tasks/observability/gateways/) for more information on exposing these externally.
* Removed the default `Sidecar` configuration. This should have no impact.

