---
title: Announcing Istio 1.11
linktitle: "1.11"
subtitle: Major Update
description: Istio 1.11 release announcement.
publishdate: 2021-08-12
release: 1.11.0
skip_list: true
aliases:
    - /news/announcing-1.11
    - /news/announcing-1.11.0
---

We are pleased to announce the release of Istio 1.11!

{{< relnote >}}

This is the third Istio release of 2021. We would like to thank the entire Istio community, and especially the release managers [Jonh Wendell](https://github.com/jwendell) from Red Hat, [Ryan King](https://github.com/ryantking) from Solo.io and [Steve Zhang](https://github.com/zhlsunshine) from Intel, for helping to get Istio 1.11.0 published.

{{< tip >}}
Istio 1.11.0 is officially supported on Kubernetes versions `1.18.0` to `1.22.x`.
{{< /tip >}}

Here are some highlights for this release:

## CNI plugin (Beta)

By default Istio injects an [init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) in pods deployed in the mesh. The `istio-init` container sets up the pod network traffic redirection to/from the Istio sidecar proxy using iptables. This requires the user or service account deploying pods in the mesh to have sufficient permissions to deploy [containers with the `NET_ADMIN` and `NET_RAW` capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container). Requiring Istio users to  have elevated Kubernetes privileges can be problematic for security compliance within an organization. The Istio CNI plugin is a replacement for the `istio-init` container that performs the same networking functionality, but without requiring Istio users to enable elevated Kubernetes permissions.

The CNI plugin can be chained with other plugins, and supports most hosted Kubernetes implementations.

In this release, we have promoted the CNI plugin functionality to Beta by improving our documentation and testing to ensure users can enable this feature safely in production. [Learn how to install Istio with the CNI plugin.](/docs/setup/additional-setup/cni/)

## External control plane (Beta)

Last year we introduced a [new deployment model for Istio](/blog/2020/new-deployment-model/) where the control plane for a cluster was managed outside of that cluster.  This allows for separation of concerns between a mesh owner, who administers the control plane, and the mesh users, who deploy and configure services in the mesh. An external control plane, running in a separate cluster, can control a single data plane cluster or more than one cluster of a multicluster mesh.

In 1.11, this feature has been promoted to Beta. [Learn how you can set up a mesh with an external control plane](/docs/setup/install/external-controlplane/).

## Gateway injection

Istio provides gateways as a way to interface with the outside world. You can deploy [ingress gateways](/docs/tasks/traffic-management/ingress/ingress-control/), for incoming traffic originating outside your cluster, and [egress gateways](/docs/tasks/traffic-management/egress/egress-gateway/), for outgoing traffic from your applications to services deployed outside your cluster.

In the past, an Istio version would deploy a gateway as a Deployment which had a completely separate proxy configuration to all the rest of the sidecar proxies in the cluster. This made management and upgrade of the gateway complex, especially when multiple gateways were deployed in the cluster. One common issue was that settings from the control plane passed down to sidecar proxies and the gateways could drift, causing unexpected issues.

Gateway injection moves the management of gateways to the same method as sidecar proxies. Configuration that you set on your proxies globally will apply to your gateways, and complex configurations that weren't possible (for example, running a gateway as a DaemonSet) are now easy. You can also update your gateways to the latest version after a cluster upgrade simply by restarting the pods.

In addition to these changes, we have released new [Installing Gateways](/docs/setup/additional-setup/gateway/) documentation, which covers best practices for installation, management, and upgrade of gateways.

## Updates to revision and tag deployments

In Istio 1.6 we added support for running multiple control planes simultaneously, which allows you to do a [canary deployment of a new Istio version](/blog/2020/multiple-control-planes/).  In 1.10, we introduced [revision tags](/blog/2021/revision-tags/), which lets you mark a revision as "production" or "testing" and minimizes the chance of error when upgrading.

The `istioctl tag` command has graduated out of experimental in 1.11. You can also now specify a default revision for the control plane. This helps further simplify the canary upgrade from a non-revisioned control plane to a new version.

We also fixed an [outstanding issue](https://github.com/istio/istio/issues/28880) with upgrades - you can safely perform a canary upgrade of your control plane regardless of whether or not it was installed using a revision.

To improve the sidecar injection experience, `istio-injection` and `sidecar.istio.io/inject` labels were introduced. We recommend you to switch to using injection labels, as they perform better than injection annotations. We intend to deprecate the injection annotations in a future release.

## Kubernetes Multi-cluster Services (MCS) support (Experimental)

The Kubernetes project is building an [multi-cluster services API](https://github.com/kubernetes/enhancements/tree/master/keps/sig-multicluster/1645-multi-cluster-services-api) that allows service owners or mesh admins to control the export of services and their endpoints across the mesh.

Istio 1.11 adds experimental support for multi-cluster services. Once enabled, the discoverability of service endpoints is determined by client location and whether the service has been exported. Endpoints residing within the same cluster as the client will always be discoverable. Endpoints within a different cluster, however, will only be discoverable by the client if they were exported to the mesh.

Note that Istio does not yet support the behavior for the `cluster.local` and `clusterset.local` hosts as defined by the MCS spec. Clients should continue to address services using either `cluster.local` or `svc.namespace`.

This is the first phase in [our plan](https://docs.google.com/document/d/1K8hvQ83UcJ9a7U8oqXIefwr6pFJn-VBEi40Ak-fwQtk/edit) to support MCS. Stay tuned!

## Sneak peek: new APIs

A number of Istio features can only be configured by [`EnvoyFilter`](/docs/reference/config/networking/envoy-filter/), which allows you to set proxy configuration. We're working on new APIs for common use cases - such as configuring telemetry settings and WebAssembly (Wasm) extension deployment, and you can expect to see these become available to users in the 1.12 release.  If you're interested in helping us test the implementations as they are built, [please join the appropriate working group meeting](https://github.com/istio/community/blob/master/WORKING-GROUPS.md).

## Join the Istio community

You can also join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/).

Would you like to get involved? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help improve Istio.

## Istio 1.11 Upgrade Survey

If you have completed your upgrade to Istio 1.11, we would like to hear from you! Please take a few minutes to respond to our brief [survey](https://forms.gle/pquMQs4Qxujus6jB9) to tell us how we’re doing.
