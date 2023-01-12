---
title: Istio 1.9 Change Notes
description: Istio 1.9.0 release notes.
weight: 10
release: 1.9
subtitle: Minor Release
linktitle: 1.9 Change Notes
publishdate: 2021-02-09
---

## Known Issues

- Wasm extension configuration updates can be disruptive (see [Issue #29843](https://github.com/istio/istio/issues/29843)).

## Traffic Management

- **Added** Add [pprof](https://github.com/google/pprof) endpoint to pilot-agent.
  ([Issue #28040](https://github.com/istio/istio/issues/28040))

- **Added** Allow enabling gRPC logging with --log_output_level for pilot.
  ([Issue #28482](https://github.com/istio/istio/issues/28482))

- **Added** a new experimental proxy option [DNS_AUTO_ALLOCATE](/docs/ops/configuration/traffic-management/dns-proxy), to control auto allocation of ServiceEntry addresses. Previously,
this option was tied to `DNS_CAPTURE`. Now, `DNS_CAPTURE` can be enabled without auto allocation. See [Smart DNS Proxying](/blog/2020/dns-proxy/) for more info.
  ([Issue #29324](https://github.com/istio/istio/issues/29324))

- **Fixed** istiod will no longer generate listeners for privileged gateway ports (<1024) if the gateway Pod does not have sufficient permissions.
  ([Issue #27566](https://github.com/istio/istio/issues/27566))

- **Fixed** an issue that caused very high memory usage with a large number of `ServiceEntries`.
  ([Issue #25531](https://github.com/istio/istio/issues/25531))

- **Removed** support for reading Istio configuration over the Mesh Configuration Protocol (MCP). ([Pull Request #28634](https://github.com/istio/istio/pull/28634))

## Security

- **Added** option to allow users to enable token exchange for their XDS flows, which exchanges a k8s token for a token that can be authenticated by their XDS servers.
  ([Issue #29943](https://github.com/istio/istio/issues/29943))

- **Added** OIDC JWT authenticator that supports both JWKS-URI and OIDC discovery. The OIDC JWT authenticator will be used when configured through the JWT_RULE env variable.  ([Issue #30295](https://github.com/istio/istio/issues/30295))

- **Added** support of PeerAuthentication per-port-level configuration on pass through filter chains.
  ([Issue #27994](https://github.com/istio/istio/issues/27994))

- **Added** an experimental [`CUSTOM` action](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action)
  in AuthorizationPolicy for integration with external authorization systems like OPA, OAuth2 and more. See [the blog on this feature](/blog/2021/better-external-authz/)
  for more info. ([Issue #27790](https://github.com/istio/istio/issues/27790))

## Telemetry

- **Added** Istio Grafana Dashboards Query Reporter Dropdown.
  ([Issue #27595](https://github.com/istio/istio/issues/27595))

- **Added** canonical service tags to Envoy-generated trace spans. ([Pull Request #28801](https://github.com/istio/istio/pull/28801))

- **Fixed** an issue to allow nested JSON structure in `meshConfig.accessLogFormat`.
  ([Issue #28597](https://github.com/istio/istio/issues/28597))

- **Updated** Prometheus metrics to include `source_cluster` and `destination_cluster` labels by default for all scenarios. Previously, this was only enabled for multi-cluster scenarios. ([Pull Request #30036](https://github.com/istio/istio/pull/30036))

- **Updated** default access log to include `RESPONSE_CODE_DETAILS` and `CONNECTION_TERMINATION_DETAILS` for proxy version >= 1.9. ([Pull Request #27903](https://github.com/istio/istio/pull/27903))

## Extensibility

- **Added** [Reliable Wasm module remote load](/docs/tasks/extensibility/wasm-module-distribution) with Istio agent. ([Issue #29989](https://github.com/istio/istio/issues/29989))

## Networking

- **Added** Correctly iptables rules and listener filters setting to support original src ip preserve in TPROXY mode within a cluster.  ([Issue #23369](https://github.com/istio/istio/issues/23369))

- **Fixed** a bug where locality weights are only applied when outlier detection is enabled. ([Issue #28942](https://github.com/istio/istio/issues/28942))

## Installation

- **Added** post-install/in-place upgrade verification of control plane health. Use `--verify` flag with `istioctl install` or `istioctl upgrade`. ([Issue #21715](https://github.com/istio/istio/issues/21715))

- **Added** Add [pprof](https://github.com/google/pprof) endpoint to pilot-agent. ([Issue #28040](https://github.com/istio/istio/issues/28040))

- **Added**  `enableIstioConfigCRDs` to `base` to allow user specify whether the Istio CRDs will be installed. ([Pull Request #28346](https://github.com/istio/istio/pull/28346))

- **Added** Istio 1.9 supports Kubernetes versions 1.17 to 1.20.
  ([Issue #30176](https://github.com/istio/istio/issues/30176))

- **Added** support for applications that bind to their pod IP address, rather than wildcard or localhost address, through the `Sidecar` API. ([Pull Request #28178](https://github.com/istio/istio/pull/28178))

- **Fixed** revision is not applied to the scale target reference of `HorizontalPodAutoscaler` when helm values for `hpa` are specified explicitly.
  ([Issue #30203](https://github.com/istio/istio/issues/30203))

- **Improved** the sidecar injector to better utilize pod labels to determine if injection is required. This is not enabled
by default in this release, but can be tested using `--set values.sidecarInjectorWebhook.useLegacySelectors=false`. ([Pull Request #30013](https://github.com/istio/istio/pull/30013))

- **Updated** Kiali addon to the latest version v1.29 . ([Pull Request #30438](https://github.com/istio/istio/pull/30438))

## istioctl

- **Added** `istioctl install` will detect different Istio version installed (istioctl, control plan version) and display warning.
  ([Issue #18487](https://github.com/istio/istio/issues/18487))

- **Added** `istioctl apply` as an alias for `istioctl install`.
  ([Issue #28753](https://github.com/istio/istio/issues/28753))

- **Added** `--browser` flag to `istioctl dashboard`, which controls whether you want to open a browser to view the dashboard.
  ([Issue #29022](https://github.com/istio/istio/issues/29022))

- **Added** `istioctl verify-install` will indicate errors in red and expected configuration in green.
  ([Issue #29336](https://github.com/istio/istio/issues/29336))

- **Added** the severity level for each analysis message in the `validationMessages` field within the `status` field.  ([Issue #29445](https://github.com/istio/istio/issues/29445))

- **Added** `WorkloadEntry` resources will be read from all clusters in multi-cluster installations and do not need to be duplicated.
Makes Virtual Machine auto-registration compatible with multi-primary multi-cluster. This feature is disabled by default and can be
enabled by setting the `PILOT_ENABLE_CROSS_CLUSTER_WORKLOAD_ENTRY` environment variable in istiod.
  ([Issue #29026](https://github.com/istio/istio/issues/29026))

- **Added** `istioctl analyze` now informs if deprecated or alpha-level annotations are present.
(These checks can be disabled using `--suppress "IST0135=*"` and `--suppress "IST0136=*"`
respectively.)
  ([Issue #29154](https://github.com/istio/istio/issues/29154))

- **Added** `istioctl x injector list` command to show which namespaces have Istio sidecar injection
and, for control plane canaries, show all Istio injectors and the namespaces they control.
  ([Issue #23892](https://github.com/istio/istio/issues/23892))

- **Fixed** `istioctl` wait now tracks resource's `metadata.generation` field, rather than `metadata.resourceVersion`.
Command line arguments have been updated to reflect this.
  ([Issue #28797](https://github.com/istio/istio/issues/28797))

- **Fixed** namespace shorthand flag missing in dashboard subcommand.
  ([Issue #28970](https://github.com/istio/istio/issues/28970))

- **Fixed** `istioctl dashboard controlz` could not port forward to istiod pod.
  ([Issue #30208](https://github.com/istio/istio/issues/30208))

- **Fixed** installation issue in which `--readiness-timeout` flag is not honored.
  ([Issue #30221](https://github.com/istio/istio/issues/30221))

- **Improved** `verify-install` detects Istio injector without control plane.
  ([Issue #29607](https://github.com/istio/istio/issues/29607))

- **Removed** `istioctl convert-ingress` command.
  ([Issue #29153](https://github.com/istio/istio/issues/29153))

- **Removed** `istioctl experimental multicluster` command.
  ([Issue #29153](https://github.com/istio/istio/issues/29153))

- **Removed** `istioctl experimental post-install` webhook command.
  ([Issue #29153](https://github.com/istio/istio/issues/29153))

- **Removed** `istioctl register` and `deregister` commands.
  ([Issue #29153](https://github.com/istio/istio/issues/29153))

- **Updated** `istioctl proxy-config log` to allow filtering logs based on label.
  ([Issue #27490](https://github.com/istio/istio/issues/27490))

## Documentation

- **Added** The locality load balancing docs have been re-written into a
formal traffic management task. The new docs describe in more detail
how locality load balancing works as well as how to configure both
failover and weighted distribution. In addition, the new docs are now
automatically verified for correctness. ([Pull Request #29651](https://github.com/istio/istio/pull/29651))
