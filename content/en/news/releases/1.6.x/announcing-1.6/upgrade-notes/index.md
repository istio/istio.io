---
title: Istio 1.6 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.6.
weight: 20
release: 1.6
subtitle: Minor Release
linktitle: 1.6 Upgrade Notes
publishdate: 2020-05-21
---

When you upgrade from Istio 1.5.x to Istio 1.6.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.5.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.5.x.

Currently, Istio doesn't support skip-level upgrades. If you are using Istio 1.4, you must upgrade to Istio 1.5 first, and then upgrade to Istio 1.6. If you upgrade from versions earlier than Istio 1.4, you should first disable Galley's configuration validation.

Update the Galley deployment using the following steps:

1. To edit the Galley deployment configuration, run the following command:

    {{< text bash >}}
    $ kubectl edit deployment -n istio-system istio-galley
    {{< /text >}}

1. Add the `--enable-validation=false` option to the `command:` section as shown below:

    {{< text yaml >}}
    apiVersion: extensions/v1beta1
    kind: Deployment
    ...
    spec:
    ...
      template:
        ...
        spec:
          ...
          containers:
          - command:
            ...
            - --log_output_level=default:info
            - --enable-validation=false
    {{< /text >}}

1. Save and quit the editor to update the deployment configuration in the cluster.

Remove the `ValidatingWebhookConfiguration` Custom Resource (CR) with the following command:

{{< text bash >}}
$ kubectl delete ValidatingWebhookConfiguration istio-galley -n istio-system
{{< /text >}}

## Change the readiness port of gateways

If you are using the `15020` port to check the health of your Istio ingress gateway with your Kubernetes network load balancer, change the port from `15020` to `15021`.

## Removal of legacy Helm charts

Istio 1.4 introduced a [new way to install Istio](/blog/2019/introducing-istio-operator/) using the in-cluster Operator or `istioctl install` command. Part of this change meant deprecating the old Helm charts in 1.5. Many new Istio features rely on the new installation method. As a result, Istio 1.6 doesn't include the old Helm installation charts.

Go to the [Istio 1.5 Upgrade Notes](/news/releases/1.5.x/announcing-1.5/upgrade-notes/#control-plane-restructuring) before you continue because Istio 1.5 introduced several changes not present in the legacy installation method, such as Istiod and telemetry v2.

To safely upgrade from the legacy installation method that uses Helm charts, perform a [control plane revision](/blog/2020/multiple-control-planes/). Upgrading in-place is not supported. Upgrading could result in downtime unless you perform a [canary upgrade](/docs/setup/upgrade/#canary-upgrades).

## Support ended for `v1alpha1` security policy

Istio 1.6 no longer supports the following security policy APIs:

- [`v1alpha1` authentication policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/)
- [`v1alpha1` RBAC policy](https://archive.istio.io/v1.4/docs/reference/config/security/istio.rbac.v1alpha1/)

Starting in Istio 1.6, Istio ignores these `v1alpha1` security policy APIs.

Istio 1.6 replaced the `v1alpha1` authentication policy with the following APIs:

- The [`v1beta1` request authentication policy](/docs/reference/config/security/request_authentication)
- The [`v1beta1` peer authentication policy](/docs/reference/config/security/peer_authentication)

Istio 1.6 replaces the `v1alpha1` RBAC policy APIs  with the [`v1beta1` authorization policy APIs](/docs/reference/config/security/authorization-policy/).

Verify that there are no `v1alpha1` security policies in your clusters the following commands:

{{< text bash >}}
$ kubectl get policies.authentication.istio.io --all-namespaces
$ kubectl get meshpolicies.authentication.istio.io --all-namespaces
$ kubectl get rbacconfigs.rbac.istio.io --all-namespaces
$ kubectl get clusterrbacconfigs.rbac.istio.io --all-namespaces
$ kubectl get serviceroles.rbac.istio.io --all-namespaces
$ kubectl get servicerolebindings.rbac.istio.io --all-namespaces
{{< /text >}}

If there are any `v1alpha1` security policies in your clusters, migrate to the new APIs before upgrading.

## Istio configuration during installation

Past Istio releases deployed configuration objects during installation. The presence of those objects caused the following issues:

- Problems with upgrades
- A confusing user experience
- A less flexible installation

To address these issues, Istio 1.6 minimized the configuration objects deployed during installation.

The following configurations are impacted:

- `global.mtls.enabled`: Configuration removed to avoid confusion. Configure a peer authentication policy to enable [strict mTLS](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode) instead.
- No default `Gateway` and associated `Certificate` custom resources are deployed during installation. Go to the [Ingress task](/docs/tasks/traffic-management/ingress/) to configure a gateway for your mesh.
- Istio no longer creates `Ingress` custom resources  for telemetry addons. Visit [remotely accessing telemetry addons](/docs/tasks/observability/gateways/) to learn how to reach the addons externally.
- The default sidecar configuration is no longer defined through the automatically generated `Sidecar` custom resource. The default configuration is implemented internally and the change should have no impact on deployments.

## Reach Istiod through external workloads

In Istio 1.6, Istiod is configured to be `cluster-local` by default.  With `cluster-local` enabled, only workloads running on the same cluster can reach Istiod. Workloads on another cluster can only access the Istiod instance through the Istio gateway. This configuration prevents the ingress gateway of the master cluster from incorrectly forwarding service discovery requests to Istiod instances in remote clusters. The Istio team is actively investigating alternatives to no longer require `cluster-local`.

To override the default `cluster-local` behavior, modify the configuration in the `MeshConfig` section as shown below:

{{< text yaml >}}
values:
  meshConfig:
    serviceSettings:
      - settings:
          clusterLocal: false
        hosts:
          - "istiod.istio-system.svc.cluster.local"
{{< /text >}}
