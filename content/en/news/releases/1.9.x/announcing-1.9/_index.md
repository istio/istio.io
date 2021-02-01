---
title: Announcing Istio 1.9.0
linktitle: 1.9
subtitle: Major Update
description: Istio 1.9 release announcement.
publishdate: 2021-02-09
release: 1.9.0
skip_list: true
aliases:
    - /news/announcing-1.9
    - /news/announcing-1.9.0
---

We are pleased to announce the release of Istio 1.9.

{{< relnote >}}

## Changes

- **Added** `istioctl install` will detect different Istio version installed (istioctl, control plan version) and display warning.
  ([Issue #18487](https://github.com/istio/istio/issues/18487))

- **Added** post-install/in-place upgrade verification of control plane health. Use `--verify` flag with `istioctl install` or `istioctl upgrade`  ([Issue #21715](https://github.com/istio/istio/issues/21715))

- **Added** Add pprof endpoint to pilot-agent.
  ([Issue #28040](https://github.com/istio/istio/issues/28040))

- **Added**  `enableIstioConfigCRDs` to `base` to allow user specify whether the istio crds will be installed. ([Pull Request #28346](https://github.com/istio/istio/pull/28346))

- **Added** Allow enabling gRPC logging with --log_output_level for pilot.
  ([Issue #28482](https://github.com/istio/istio/issues/28482))

- **Added** `istioctl apply` as an alias for `istioctl install`.
  ([Issue #28753](https://github.com/istio/istio/issues/28753))

- **Added** `--browser` flag to `istioctl dashboard`, which controls whether you want to open a browser to view the dashboard.
  ([Issue #29022](https://github.com/istio/istio/issues/29022))

- **Added** `istioctl verify-install` will indicate errors in red and expected configuration in green.
  ([Issue #29336](https://github.com/istio/istio/issues/29336))

- **Added** the severity level for each analysis message in the `validationMessages` field within the `status` field.  ([Issue #29445](https://github.com/istio/istio/issues/29445))

- **Added** `WorkloadEntry` resources will be read from all clusters in multi-cluster installations and do not need to be duplicated.
Makes Virtual Machine auto-registration compatible with multi-primary multi-cluster. This feature is diabled by default and can be
enaled by setting the `PILOT_ENABLE_CROSS_CLUSTER_WORKLOAD_ENTRY` environment variable in istiod.
  ([Issue #29026](https://github.com/istio/istio/issues/29026))

- **Added** `istioctl analyze` now informs if deprecated or alpha-level annotations are present.
(These checks can be disabled using `--suppress "IST0135=*"` and `--suppress "IST0136=*"`
respectively.)
  ([Issue #29154](https://github.com/istio/istio/issues/29154))

- **Added** option to enable STS token fetch and exchange for XDS flow.
  ([Issue #29943](https://github.com/istio/istio/issues/29943))

- **Added** OIDC JWT authenticator that supports both JWKS-URI and OIDC discovery. The OIDC JWT authenticator will be used when configured through the JWT_RULE env variable.  ([Issue #30295](https://github.com/istio/istio/issues/30295))

- **Added** a new experimental proxy option, `DNS_AUTO_ALLOCATE`, to control auto allocation of ServiceEntry addresses. Previously,
this option was tied to `DNS_CAPTURE`. Now, `DNS_CAPTURE` can be enabled without auto allocation.
  ([Issue #29324](https://github.com/istio/istio/issues/29324))

- **Added** support for backpressure on XDS pushes to avoid overloading Envoy during periods of high configuration
churn. This is disabled by default and can be enabled by setting the PILOT_ENABLE_FLOW_CONTROL environment variable in Istiod.
  ([Issue #25685](https://github.com/istio/istio/issues/25685))

- **Added** Istio Grafana Dashboards Query Reporter Dropdown.
  ([Issue #27595](https://github.com/istio/istio/issues/27595))

- **Added** `istioctl x injector list` command to show which namespaces have Istio sidecar injection
and, for control plane canaries, show all Istio injectors and the namespaces they control.
  ([Issue #23892](https://github.com/istio/istio/issues/23892))

- **Added** The locality load balancing docs have been re-written into a
formal traffic management task. The new docs describe in more detail
how locality load balancing works as well as how to configure both
failover and weighted distribution. In addition, the new docs are now
automatically verified for correctness.

- **Added** Istio 1.9 supports Kubernetes versions 1.17 to 1.20.
  ([Issue #30176](https://github.com/istio/istio/issues/30176))

- **Added** support of PeerAuthentication per-port-level configuration on pass through filter chains.
  ([Issue #27994](https://github.com/istio/istio/issues/27994))

- **Added** support for applications that bind to their pod IP address, rather than wildcard or localhost address, through the `Sidecar` API. ([Pull Request #28178](https://github.com/istio/istio/pull/28178))

- **Added** Correctly iptables rules and listener filters setting to support original src ip preserve within a cluster.  ([Issue #23369](https://github.com/istio/istio/issues/23369))

- **Added** flag to enable capture of dns traffic to the istio-iptables script. ([Pull Request #29908](https://github.com/istio/istio/pull/29908))

- **Added** Reliable Wasm module remote load with istio-agent.
  ([Issue #29989](https://github.com/istio/istio/issues/29989))

- **Added** canonical service tags to Envoy-generated trace spans. ([Pull Request #28801](https://github.com/istio/istio/pull/28801))

- **Fixed** istiod will no longer generate listeners for privileged gateway ports (<1024) if the gateway Pod does not have sufficient permissions
  ([Issue #27566](https://github.com/istio/istio/issues/27566))

- **Fixed** istioctl wait now tracks resource's metadata.generation field, rather than metadata.resourceVersion.
Command line arguments have been updated to reflect this.
  ([Issue #28797](https://github.com/istio/istio/issues/28797))

- **Fixed** a bug where locality weights are only applied when outlier detection is enabled.  ([Issue #28970](https://github.com/istio/istio/issues/28970))

- **Fixed** namespace shorthand flag missing in dashboard subcommand.
  ([Issue #28970](https://github.com/istio/istio/issues/28970))

- **Fixed** Prevent goroutine leak when using alpha status feature.
  ([Issue #29275](https://github.com/istio/istio/issues/29275))

- **Fixed** an bug if global sidecar is defined in root namespace, no xDS pushes happen when cluster scoped configs(EnvoyFilter, AuthorizationPolicy, RequestAuthentication) changes.
  ([Issue #29414](https://github.com/istio/istio/issues/29414))

- **Fixed** a bug where DNS agent preview produces malformed DNS responses
  ([Issue #29681](https://github.com/istio/istio/issues/29681))

- **Fixed** Modifying multi-network gateway configuration via Services with the label `topology.istio.io/network` will
now cause endpoints to be updated on all proxies.
  ([Issue #30054](https://github.com/istio/istio/issues/30054))

- **Fixed** revision is not applied to the scale target reference of HorizontalPodAutoscaler when helm values for hpa are specified explicitly.
  ([Issue #30203](https://github.com/istio/istio/issues/30203))

- **Fixed** dashboard controlz could not port forward to istiod pod.
  ([Issue #30208](https://github.com/istio/istio/issues/30208))

- **Fixed** installation issue in which `--readiness-timeout` flag is not honored.
  ([Issue #30221](https://github.com/istio/istio/issues/30221))

- **Fixed** namespace isn't resolved correctly in VirtualService delegation's short destination host.
  ([Issue #30387](https://github.com/istio/istio/issues/30387))

- **Fixed** an issue that caused very high memory usage with a large number of `ServiceEntries`.
  ([Issue #25531](https://github.com/istio/istio/issues/25531))

- **Fixed** an issue to allow nested JSON structure in `meshConfig.accessLogFormat`.
  ([Issue #28597](https://github.com/istio/istio/issues/28597))

- **Fixed** a bug where load assignments were added to passthrough subsets resulting in Envoy rejecting those subset clusters.
  ([Issue #25691](https://github.com/istio/istio/issues/25691))

- **Improved** the expose istiod example to use TLS passthrough for multicluster or external Istiod
**Added** an expose istiod example to use TLS termination for multicluster or external Istiod  ([Issue #27976](https://github.com/istio/istio/issues/27976))

- **Improved** 'verify-install' detects Istio injector without control plane.
  ([Issue #29607](https://github.com/istio/istio/issues/29607))

- **Improved** sidecar injection to automatically specify the `kubectl.kubernetes.io/default-logs-container`. This ensures `kubectl logs`
defaults to reading the application container's logs, rather than requiring explicitly setting the container.  ([Issue #26764](https://github.com/istio/istio/issues/26764))

- **Improved** the sidecar injector to better utilize pod labels to determine if injection is required. This is not enabled
by default in this release, but can be tested using `--set values.sidecarInjectorWebhook.useLegacySelectors=false`. ([Pull Request #30013](https://github.com/istio/istio/pull/30013))

- **Removed** support for reading Istio configuration over the Mesh Configuration Protocol (MCP). ([Pull Request #28634](https://github.com/istio/istio/pull/28634))

- **Removed** istioctl convert-ingress command
  ([Issue #29153](https://github.com/istio/istio/issues/29153))

- **Removed** istioctl experimental multicluster command
  ([Issue #29153](https://github.com/istio/istio/issues/29153))

- **Removed** istioctl experimental post-install webhook command
  ([Issue #29153](https://github.com/istio/istio/issues/29153))

- **Removed** istioctl register and deregister commands
  ([Issue #29153](https://github.com/istio/istio/issues/29153))

- **Updated** `istioctl proxy-config log` to allow filtering logs based on label.
  ([Issue #27490](https://github.com/istio/istio/issues/27490))

- **Updated** prometheus metrics to include `source_cluster` and `destination_cluster` labels by default for all scenarios. Previously, this was only enabled for multi-cluster scenarios. ([Pull Request #30036](https://github.com/istio/istio/pull/30036))

- **Updated** default access log to include `RESPONSE_CODE_DETAILS` and `CONNECTION_TERMINATION_DETAILS` for proxy version >= 1.9. ([Pull Request #27903](https://github.com/istio/istio/pull/27903))

- **Updated** Kiali addon to the latest version v1.29. ([Pull Request #30438](https://github.com/istio/istio/pull/30438))

- **Updated** the default installation of gateways to not configure clusters for `AUTO_PASSTHROUGH`, reducing memory costs.
  ([Issue #27749](https://github.com/istio/istio/issues/27749))

## Join the Istio community

Our [Community Meeting](https://github.com/istio/community#community-meeting) happens on the fourth Thursday of the month, at 10 AM Pacific. Due to US Thanksgiving, we've moved this month's meeting forward one week to the 19th of November. If you can't make it, why not join the conversation at [Discuss Istio](https://discuss.istio.io/), or join our [Slack workspace](https://slack.istio.io/)?

Would you like to get involved? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help make Istio even better.
