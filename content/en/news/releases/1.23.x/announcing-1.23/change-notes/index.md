---
title: Istio 1.23.0 Change Notes
linktitle: 1.23.0
subtitle: Major Release
description: Istio 1.23.0 release notes.
publishdate: 2024-08-14
release: 1.23.0
weight: 10
aliases:
    - /news/announcing-1.23.0
---

## Deprecations

- **Deprecated** the in-cluster Operator.  Please check out [our deprecation announcement blog post](/blog/2024/in-cluster-operator-deprecation-announcement/) for more details on the change.

## Traffic Management

- **Added** support for proxying `100 Continue` headers. This can be disabled by setting `ENABLE_100_CONTINUE_HEADERS` to `false`.

- **Added** a way to read the traffic type for a waypoint from the `istio.io/waypoint-for` label on the parent Gateway class. This value overrides the global default and will be overridden if the label is applied to the waypoint resource.
  ([Issue #50933](https://github.com/istio/istio/issues/50933))

- **Added** support for matching multiple service VIPs in a waypoint proxy.
  ([Issue #51886](https://github.com/istio/istio/issues/51886))

- **Added** an experimental feature to enable cluster creation on worker threads inline during requests.
    This will save memory and CPU cycles in cases where there are lots of inactive clusters and > 1 worker thread.
    This can be disabled by setting `ENABLE_DEFERRED_CLUSTER_CREATION` to `false` in agent Deployment.

- **Added** support for the new `reset-before-request` retry policy added in Envoy 1.31.
  ([Issue #51704](https://github.com/istio/istio/issues/51704))

- **Fixed** a bug where UDP traffic in the `ISTIO_OUTPUT` iptables chain exits early.
  ([Issue #51377](https://github.com/istio/istio/issues/51377))

- **Fixed** `ServiceEntry` status addresses field not supporting IP address assignments to individual hosts, which led to an undesired divergence in behavior between the new and old implementations for automatic allocations. Added a "Host" field to the Address in order to support mapping allocated IP to a host.

- **Fixed** an issue where CORS filter forwarded preflight requests if the origin was not allowed.

- **Fixed** retry logic to make getting envoy metrics safer on `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` mode.
  ([Issue #50596](https://github.com/istio/istio/issues/50596))

- **Fixed** propagation of IPv6 config to the `istio-cni`. Note that IPv6 support is still unstable.
  ([Issue #50162](https://github.com/istio/istio/issues/50162))

- **Fixed** an issue where ZDS did not pass down `trust_domain`.
  ([Issue #51182](https://github.com/istio/istio/issues/51182))

- **Fixed** an issue with iptables rules for ambient when dealing with IPv6.

- **Fixed** IP auto allocation for `ServiceEntry` to allocate per-host rather than per-`ServiceEntry`.
  ([Issue #52319](https://github.com/istio/istio/issues/52319))

- **Fixed** `ServiceEntry` validation to suppress the "address required" warning when using the auto IP allocation controller.
  ([Issue #52422](https://github.com/istio/istio/issues/52422))

- **Fixed** an issue where TLS settings in `DestinationRule` are not respected when connecting from a gateway or sidecar to a backend enrolled using ambient mode.

- **Fixed** an issue preventing `DestinationRule` `proxyProtocol` from working when TLS is disabled.

- **Removed** the `ISTIO_ENABLE_OPTIMIZED_SERVICE_PUSH` feature flag.

- **Removed** the `ENABLE_OPTIMIZED_CONFIG_REBUILD` feature flag.

- **Removed** the experimental `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` feature flag and corresponding `istioctl experimental wait` command.

- **Updated** `istio-cni` config map to only expose environment variables that are user-configurable.

## Security

- **Added** stricter validation of CSRs when Istio is functioning as the RA and is configured with an external CA for workload certificate signing.
  ([Issue #51966](https://github.com/istio/istio/issues/51966))

- **Improved** the ability to use SPIRE for SDS by allowing a custom server socket filename. Previously, SPIRE docs forced the SPIRE SDS server be configured to use the Istio-default SDS socket name. This release introduces `WORKLOAD_IDENTITY_SOCKET_FILE` as an agent environment variable. If set to a non-default value, the agent will expect to find a non-Istio SDS server socket at the hard-coded path: `WorkloadIdentityPath/WORKLOAD_IDENTITY_SOCKET_FILE` and will throw an error if no healthy socket was found. Otherwise, it will listen to it. If this is unset, the agent will start and Istio default SDS server instance with a hard-coded path and hard-coded socket file of: `WorkloadIdentityPath/DefaultWorkloadIdentitySocketFile` and listen to it. This removes/replaces the agent environment variable `USE_EXTERNAL_WORKLOAD_SDS` (added in #45941)([Issue #48845](https://github.com/istio/istio/issues/48845))

## Telemetry

- **Added** [access log formatter](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/formatter/formatter) support for OpenTelemetry. Users can add `CEL`/`METADATA`/`REQ_WITHOUT_QUERY` commands after all proxies are upgraded to Istio 1.23+.

- **Fixed** an issue where the status code was unset when using OpenTelemetry tracing.
  ([Issue #50195](https://github.com/istio/istio/issues/50195))

- **Fixed** an issue where the span name was not set when using the OpenTelemetry tracing provider.

- **Fixed** `statsMatcher`'s regular expression not matching a route's `stat_prefix`.

- **Fixed** an issue where the `cluster_name` and `http_conn_manager_prefix` labels were incorrectly truncated for services without a `.svc.cluster.local` suffix.

- **Removed** Istio Stackdriver metrics from XDS.
  ([Issue #50808](https://github.com/istio/istio/issues/50808))

- **Removed** the OpenCensus tracer from Istio XDS.
  ([Issue #50808](https://github.com/istio/istio/issues/50808))

- **Removed** the feature flag `ENABLE_OTEL_BUILTIN_RESOURCE_LABELS`.

## Extensibility

- **Removed** internal multi-version protobuf files from the API. This is an internal change for most users. If you directly consume Istio APIs as protobufs, read the upgrade notes.
  ([Issue #3127](https://github.com/istio/api/issues/3127))

## Installation

- **Added** `.Values.pilot.trustedZtunnelNamespace` to the `istiod` Helm chart. Set this if installing ztunnel to a different namespace from `istiod`. This value supersedes `.Values.pilot.env.CA_TRUSTED_NODE_ACCOUNTS` (which is still respected if set).

- **Added** the `releaseChannel:extended` flag to non-GA features and APIs. ([Issue #173](https://github.com/istio/enhancements/issues/173))

- **Added** outlier log path configuration to the mesh proxy config which allows users to configure the path to the outlier detection log file.
  ([Issue #50781](https://github.com/istio/istio/issues/50781))

- **Added** an `ambient` umbrella Helm chart that wraps the baseline Istio components required for installing Istio with ambient support.

- **Added** support for readiness checks over https to istiod for use in clusters utilizing a remote control plane for sidecar injection.
  ([Issue #51506](https://github.com/istio/istio/issues/51506))

- **Fixed** an issue where the CNI plugin inherited the CNI agent log level.

- **Fixed** an issue with service account annotation formatting by removing dashes.
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **Fixed** an issue where custom annotations were not propagated to the ztunnel chart.

- **Fixed** an issue where `sidecar.istio.io/proxyImage` annotation was ignored during the gateway injection.
  ([Issue #51888](https://github.com/istio/istio/issues/51888))

- **Fixed** an issue where netlink errors were not be correctly parsed, leading to `istio-cni` not properly ignoring leftover ipsets.

- **Improved** CNI logging config.
  ([Issue #50958](https://github.com/istio/istio/issues/50958))

- **Improved** the Helm installation for Istiod multi-cluster for primary-remote. Now, Helm installations only require setting `global.externalIstiod`, instead of also requiring `pilot.env.EXTERNAL_ISTIOD` to be set.
  ([Issue #51595](https://github.com/istio/istio/issues/51595))

- **Removed** `values.cni.logLevel` is now deprecated. Use `values.{cni|global}.logging.level` instead.

- **Updated** the [`distroless`](/docs/ops/configuration/security/harden-docker-images/) images to be based on [Wolfi](https://wolfi.dev).
  This should have no user-facing impact.

- **Updated** Kiali addon to version 1.87.0.

- **Upgraded** base debug images to use the latest Ubuntu LTS, `ubuntu:noble`. Previously, `ubuntu:focal` was used.

## istioctl

- **Added** a status subcommand that prints out the status of gateway(s) for a given namespace.  ([Issue #51294](https://github.com/istio/istio/issues/51294))

- **Added** the ability for users to set the `seccompProfile.type` (e.g. to `RuntimeDefault`) for auto deployed waypoints by setting `values.gateways.seccompProfile.type` in the istiod injection config.

- **Added** an `overwrite` flag to `istioctl apply` command to allow overwriting existing resources in the cluster (initially, just namespace waypoint enrollments).
  ([Issue #51312](https://github.com/istio/istio/issues/51312))

- **Improved** the output for `istioctl version` to be more user-friendly.  ([Issue #51296](https://github.com/istio/istio/issues/51296))

- **Improved** the `istioctl proxy-status` command.
    - Each status now includes the time since the last change.
    - If a proxy is not subscribed to a resource, it will now be shown as `IGNORED` instead of `NOT SENT`. `NOT SENT` continues to be used for resources that are requested, but never sent.
    - Include a new `ERROR` status when configuration is rejected.

## Samples

- **Improved** the look and feel of the Bookinfo app.
