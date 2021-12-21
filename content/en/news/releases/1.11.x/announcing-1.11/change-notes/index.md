---
title: Istio 1.11 Change Notes
linktitle: 1.11.0
subtitle: Minor Release
description: Istio 1.11.0 release notes.
publishdate: 2021-08-12
release: 1.11.0
weight: 10
aliases:
    - /news/announcing-1.11.0
---

## Traffic Management

- **Promoted** [CNI](/docs/setup/additional-setup/cni/) to beta. ([Issue #86](https://github.com/istio/enhancements/issues/86))

- **Improved** resolution of headless services via in-agent DNS to include endpoints
from other clusters that are on the same network.
  ([Issue #27342](https://github.com/istio/istio/issues/27342))

- **Improved** usage of `AUTO_PASSTHROUGH` Gateways to no longer require configuring the `ISTIO_META_ROUTER_MODE` environment variable on the gateway deployment; instead, it is automatically detected.
  ([Issue #33127](https://github.com/istio/istio/issues/33127))

- **Improved** CNI network plugin to send logs to the CNI DaemonSet. This allows viewing CNI logs using `kubectl logs`, instead of looking at kubelet logs.
  ([Issue #32437](https://github.com/istio/istio/issues/32437))

- **Improved** service conflict resolution to favor Kubernetes Services over `ServiceEntries` with the same hostname.

- **Updated** CNI install container and race condition repair container are combined into one container.
  ([Issue #33712](https://github.com/istio/istio/issues/33712))

- **Updated** the Istiod debug interface to be only accessible over localhost or with proper authentication (mTLS or JWT).
The recommended way to access the debug interface is through `istioctl experimental internal-debug`, which handles
this automatically.

- **Added** the `shutdownDuration` flag to [pilot-discovery](/docs/reference/commands/pilot-discovery/) so that users can configure the duration istiod needs to terminate gracefully. The default value is 10s.

- **Added** an environment variable `PILOT_STATUS_UPDATE_INTERVAL` that is the interval to update the XDS distribution status and its default value is `500ms`.

- **Added** the HTTP endpoint localhost:15004/debug/\<`typeurl`\> to the Istio sidecar agent. GET requests
to that URL will be resolved by sending an xDS discovery "event" to istiod.  This can be disabled by setting
the following in the Istio Operator: `meshConfig.defaultConfig.proxyMetadata.PROXY_XDS_DEBUG_VIA_AGENT=false`.
  ([Issue #22274](https://github.com/istio/istio/issues/22274))

- **Added** support for overriding the locality of the `WorkloadGroup` template in
an auto registered `WorkloadEntry`. Locality overrides can be passed in through
Envoy bootstrap configuration.
  ([Issue #33426](https://github.com/istio/istio/pull/33426)),([Issue #33426](https://github.com/istio/istio/issues/33426))

- **Added** new metric for tracking distribution of configuration resource sizes being pushed by istiod.
  ([Issue #31772](https://github.com/istio/istio/issues/31772))

- **Added** experimental support for the Kubernetes Multi-Cluster Services (MCS) host (`clusterset.local`).
This feature is off by default, but can be enabled by setting the following environment variables for your Istiod deployment:
`ENABLE_MCS_HOST` and `ENABLE_MCS_SERVICE_DISCOVERY`. When enabled Istio will include the MCS host as a
domain in the service's HTTP route. Additionally, Istio will support the MCS host during a DNS lookup.
For now, the MCS host is just an alias for `cluster.local` and resolves to the same service IP.
Future work will give the MCS host a separate IP as is defined by the MCS spec.  ([Issue #33949](https://github.com/istio/istio/issues/33949))

- **Added** experimental support for controlling service endpoint discoverability with Kubernetes Multi-Cluster
Services (MCS). This feature is off by default, but can be enabled by setting the
`ENABLE_MCS_SERVICE_DISCOVERY` flag in Istio. When enabled, Istio will make service endpoints
only discoverable from within the same cluster by default. To make the service endpoints within a cluster
discoverable throughout the mesh, a `ServiceExport` CR must be created within the same cluster as the service
endpoints. this process can be automated by enabling the Istio flag `ENABLE_MCS_AUTOEXPORT`. With this enabled,
Istio will automatically create `ServiceExport` in all clusters for each service.
  ([Issue #29384](https://github.com/istio/istio/issues/29384))

- **Fixed** an issue to `enableCoreDump` using the sidecar annotation.
 ([reference]( https://istio.io/latest/docs/reference/config/annotations/)) ([Issue #26668](https://github.com/istio/istio/issues/26668))

- **Fixed** where both inbound and outbound apps were unable to intercept traffic when using `podIP` in TPROXY interception mode.
  ([Issue #31095](https://github.com/istio/istio/issues/31095))

- **Fixed** an issue where subject alternate names specified in service entry are not considered while building TLS context.
  ([Issue #32539](https://github.com/istio/istio/issues/32539))

- **Fixed** a bug where multiple gateways on the same port with `SIMPLE` and `PASSTHROUGH` modes was not working correctly.  ([Issue #33405](https://github.com/istio/istio/issues/33405))

- **Fixed** a bug where Istio config generation fails when the sum of endpoint weights was over uint32 max.  ([Issue #33536](https://github.com/istio/istio/issues/33536))

- **Fixed** smart DNS support in Istio CNI.
  ([Issue #29511](https://github.com/istio/istio/issues/29511))

- **Fixed** a bug in Kubernetes Ingress causing paths with prefixes of the form `/foo` to
match the route `/foo/` but not the route `/foo`.

- **Fixed** an issue allowing a `ServiceEntry` to act as an instance in other namespaces.

- **Fixed** an issue causing proxies to send `Transfer-Encoding` headers with `1xx` and `204` responses.

- **Fixed** reconciliation logic in the validation webhook controller to rate-limit
the retries in the loop. This should drastically reduce churn (and generated logs)
in cases of misconfiguration.
  ([Issue #32210](https://github.com/istio/istio/issues/32210))

- **Optimized** generated routing configuration to merge virtual hosts with the same routing configuration. This improves performance for Virtual Services with multiple hostnames defined.
  ([Issue #28659](https://github.com/istio/istio/issues/28659))

## Security

- **Added** validation for the `jwks` field in the request authentication policy. ([Issue #33053](https://github.com/istio/istio/issues/33053))

## Telemetry

- **Updated** Prometheus telemetry behavior for inbound traffic to disable host header fallback by default. This will
prevent traffic coming from out-of-mesh locations from potentially polluting the `destination_service` dimension in
metrics with junk data (and exploding metrics cardinality). With this change, it is possible that users relying on
host headers for labeling the destination service for inbound traffic from out-of-mesh workloads will see that traffic
labeled as `unknown`. The behavior can be restored by modifying Istio configuration to remove the `disable_host_header_fallback: true`
configuration.

- **Added** support for [Apache SkyWalking](https://skywalking.apache.org/) tracer. Now you can run the `istioctl dashboard skywalking` command to view SkyWalking dashboard UI.
  ([Issue #32588](https://github.com/istio/istio/pull/32588))

- **Added** a new metric to `istiod` to report server uptime.

- **Added** a new metric (`istiod_managed_clusters`) to `istiod` to track the number of clusters managed by an
`istiod` instance.

- **Fixed** Prometheus [metrics merging](/docs/ops/integrations/prometheus/#option-1-metrics-merging) to
correctly handle the case where the application metrics are exposed as [OpenMetrics](https://github.com/OpenObservability/OpenMetrics).
  ([Issue #33474](https://github.com/istio/istio/issues/33474))

## Installation

- **Promoted** [external control plane](/docs/setup/install/external-controlplane/) to beta.
  ([Pull Request #93](https://github.com/istio/enhancements/pull/93))

- **Improved** the installation of Istio on remote clusters using an external control plane.
The `istiodRemote` component now includes all of the resources needed for either a basic remote or config cluster.
  ([Issue #33455](https://github.com/istio/istio/issues/33455))

- **Improved** the size of container images, decreasing each image by up to 50Mb. As a result, the `linux-tools-generic` package, as well as dependencies (including `python`) are no longer installed.

- **Updated** the base image versions to be built on `ubuntu:focal` and `debian10` (for distroless).

- **Updated** Jaeger addon to version 1.22.

- **Fixed** the upgrade and downgrade message of the control plane.
  ([Issue #32749](https://github.com/istio/istio/issues/32749))

- **Removed** the empty `caBundle` default value from Chart to allow a GitOps approach.
  ([Issue #33052](https://github.com/istio/istio/issues/33052))

## istioctl

- **Promoted** the `istioctl experimental revision tag` command group to `istioctl tag`.

- **Added** `--workloadIP` flag to `istioctl x workload entry configure`, which sets the configuration for the workload IP that the sidecar proxy uses to auto register a workload Entry.
Usually required when the VM workloads aren't in the same network as the primary cluster to which they register.
  ([Issue #32462](https://github.com/istio/istio/issues/32462))

- **Added** `--dry-run` flag for `istioctl x uninstall`.
  ([Issue #32513](https://github.com/istio/istio/issues/32513))

- **Added** `istioctl proxy-config bootstrap` now has a short output option (`-o short`) that shows the Istio and Envoy version summary.
  ([Issue #21517](https://github.com/istio/istio/issues/21517))

- **Added** a new analyzer to check for `image: auto` in Pods and Deployments that will not be injected.

- **Added** support for auto-completion of the namespace for istioctl.

- **Added** istioctl now supports completion for Kubernetes pods, services.

- **Added** `--vklog` option to enable verbose logging in client-go.
  ([Issue #28231](https://github.com/istio/istio/issues/28231))

- **Fixed** user-agent in all Istio binaries to include version.
