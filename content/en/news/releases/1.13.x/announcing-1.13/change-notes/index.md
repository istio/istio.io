---
title: Istio 1.13 Change Notes
linktitle: 1.13.0
subtitle: Minor Release
description: Istio 1.13.0 change notes.
publishdate: 2022-02-11
release: 1.13.0
weight: 10
aliases:
    - /news/announcing-1.13.0
---

## Traffic Management

- **Added** an API (CRD) for configuring `ProxyConfig` values containing a stable subset of the configuration from `MeshConfig.DefaultConfig`.

- **Added** support for hostname-based multi-network gateways for east-west traffic. The hostname will be resolved in
the control plane and each of the IPs will be used as an endpoint. This behavior can be disabled by setting
`RESOLVE_HOSTNAME_GATEWAYS=false` for istiod.  ([Issue #29359](https://github.com/istio/istio/issues/29359))

- **Added** support for rewriting gRPC probes.

- **Added** a feature flag `PILOT_LEGACY_INGRESS_BEHAVIOR`, default to false.
If this is set to true, Istio ingress will perform the legacy behavior, which does not meet the
[Kubernetes specification](https://kubernetes.io/docs/concepts/services-networking/ingress/#multiple-matches).
  ([Issue #35033](https://github.com/istio/istio/issues/35033))

- **Added** support for listeners to balance between Envoy worker threads via `proxyMetadata`. ([Issue #18152](https://github.com/istio/istio/issues/18152))

- **Promoted** `WorkloadGroup` to v1beta1.
  ([Issue #25652](https://github.com/istio/istio/issues/25652))

- **Improved** istio-agent health probe rewrite to not re-use connections, mirroring Kubernetes' probing behavior.
  ([Issue #36390](https://github.com/istio/istio/issues/36390))

- **Improved** the default `PILOT_MAX_REQUESTS_PER_SECOND`, which limits the number of **new** XDS connections per second,
to 25 (from 100). This has been shown to improve performance under high load.

- **Updated** the control plane to read `EndpointSlice` instead of `Endpoints`
for service discovery for Kubernetes 1.21 or later. To switch back to the old
`Endpoints` based behavior set `PILOT_USE_ENDPOINT_SLICE=false` in istiod.

- **Fixed** an issue where specifying conflict protocols for a service target port
will cause unstable protocol selection for that port.
  ([Issue #36462](https://github.com/istio/istio/issues/36462))

- **Fixed** an issue where scaling endpoint for a service from 0 to 1
might cause client side service account verification to be populated incorrectly.
  ([Issue #36465](https://github.com/istio/istio/issues/36465) and [#31534](https://github.com/istio/istio/issues/31534))

- **Fixed** an issue where the `TcpKeepalive` setting at mesh config is not honored.
  ([Issue #36499](https://github.com/istio/istio/issues/36499))

- **Fixed** an issue where stale endpoints can be configured when a service gets deleted and created again.
  ([Issue #36510](https://github.com/istio/istio/issues/36510))

- **Fixed** an issue where istiod crashes if prioritized leader election (controlled via `PRIORITIZED_LEADER_ELECTION` env variable) is disabled.  ([Issue #36541](https://github.com/istio/istio/issues/36541))

- **Fixed** an issue that sidecar iptables will cause intermittent connection reset due to the out of window packet.
Introduced a flag `meshConfig.defaultConfig.proxyMetadata.INVALID_DROP` to control this setting.
  ([Issue #36566](https://github.com/istio/istio/pull/36566))

- **Fixed** an issue where an in-place upgrade will cause TCP connections between a <1.12 proxy and a 1.12 proxy to fail.
  ([Issue #36797](https://github.com/istio/istio/pull/36797))

- **Fixed** an issue where `EnvoyFilter` with ANY patch context will skip adding new clusters and listeners at gateway.

- **Fixed** an issue causing HTTP/1.0 requests to be rejected (with a `426 Upgrade Required` error) in some cases.
  ([Issue #36707](https://github.com/istio/istio/issues/36707))

- **Fixed** an issue where using `ISTIO_MUTUAL` TLS mode in Gateways while also setting `credentialName` cause mutual TLS to not be configured.
This configuration is now rejected, as `ISTIO_MUTUAL` is intended to be used without `credentialName` set.
The old behavior can be retained by configuring the `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME=true` environment variable in Istiod.

- **Fixed** an issue where changes in a delegate VirtualService do not take effect when RDS cache is enabled.
  ([Issue #36525](https://github.com/istio/istio/issues/36525))

- **Fixed** an issue causing mTLS errors for traffic on port 22, by including port 22 in iptables by default.
  ([Issue #35733](https://github.com/istio/istio/issues/35733))

- **Fixed** an issue causing hostnames overlapping the cluster domain (such as `example.local`) to generate invalid routes.
  ([Issue #35676](https://github.com/istio/istio/issues/35676))

- **Fixed** an issue that if duplicated cipher suites were configured in Gateway, they were pushed to Envoy configuration. With this fix, duplicated cipher
suites will be ignored and logged.
  ([Issue #36805](https://github.com/istio/istio/issues/36805))

## Security

- **Added** TLS settings to the sidecar API in order to enable TLS/mTLS termination on the sidecar proxy for requests
coming from outside the mesh. ([Issue #35111](https://github.com/istio/istio/issues/35111))

- **Promoted** [authorization policy dry-run mode](/docs/tasks/security/authorization/authz-dry-run/) to Alpha. ([Issue #112](https://github.com/istio/enhancements/pull/112))

- **Fixed** a couple of issues in the ext-authz filter affecting the behavior of the gRPC check response API. Please
see the [Envoy release note](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.20.0#bug-fixes) for more
details of the bug fixes if you are using authorization policies with the ext-authz gRPC extension provider in Istio.
([Issue #35480](https://github.com/istio/istio/issues/35480))

## Telemetry

- **Added** configuration for selecting service name generation scheme in Envoy-generated trace spans.
  ([Issue #36162](https://github.com/istio/istio/issues/36162) and [#12644](https://github.com/istio/istio/issues/12644))

- **Added** Common Expression Language (CEL) filter support for access logs.
  ([Issue #36514](https://github.com/istio/istio/issues/36514))

- **Added** access logging providers and controls for access log filtering to
the Telemetry API.

- **Added** an option to set whether the Request ID generated by the sidecar should be used when determining the sampling strategy for tracing.

- **Added** configurable service-cluster naming scheme support.
([Issue #36162](https://github.com/istio/istio/issues/36162))

- **Improved** Istiod `JWTRule`: Failed `JWKS` requests are now logged with truncation to 100 characters.
  ([Issue #35663](https://github.com/istio/istio/issues/35663))

## Installation

- **Added** a privileged flag to Istio-CNI Helm charts to set `securityContext` flag.
  ([Issue #34211](https://github.com/istio/istio/issues/34211))

- **Removed** support for a number of nonstandard `kubeconfig` authentication methods when using multicluster secrets.

- **Updated** istiod deployment to respect `values.pilot.nodeSelector`.
  ([Issue #36110](https://github.com/istio/istio/issues/36110))

- **Fixed** an issue where the in-cluster operator can't prune resources when the Istio control plane has active proxies connected.
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **Fixed** omission of the `.Values.sidecarInjectiorWebhook.enableNamespacesByDefault` setting in the default revision mutating webhook, and added `--auto-inject-namespaces` flag to `istioctl tag` controlling this setting.
  ([Issue #36258](https://github.com/istio/istio/issues/36258))

- **Fixed** an issue where setting `includeInboundPorts` with Helm values did not take effect.
  ([Issue #36644](https://github.com/istio/istio/issues/36644))

- **Fixed** an issue that was preventing the Helm chart to be used as a chart dependency.
  ([Issue #35495](https://github.com/istio/istio/issues/35495))

- **Fixed** that the Helm chart generated an invalid manifest when given boolean or numeric values for environment variables.
  ([Issue #36946](https://github.com/istio/istio/issues/36946))

- **Fixed** detection of `prometheus.io.scrape` annotations when merging metrics.
  ([Issue #31187](https://github.com/istio/istio/issues/31187))

## istioctl

- **Added** `istioctl analyze` will display a warning when service of type ExternalName have invalid port name or port name is tcp.
  ([Issue #35429](https://github.com/istio/istio/issues/35429))

- **Added** log options to `istioctl install` to prevent unexpected messages.
  ([Issue #35770](https://github.com/istio/istio/issues/35770))

- **Added** `CLUSTER` column in the output of `istioctl ps` command.

- **Added** the global wildcard pattern match for the bug report `--include` and `--exclude` flag.

- **Added** the output format flag to `operator dump`.

- **Added** `--operatorFileName` flag to `kube-inject` to support `IstioOperator` files.
  ([Issue #36472](https://github.com/istio/istio/issues/36472))

- **Added** `istioctl analyze` now supports `--ignore-unknown`, which suppresses
errors when non-k8s yaml files are found in a file or directory.
  ([Issue #36471](https://github.com/istio/istio/issues/36471))

- **Added** stats command `istioctl experimental envoy-stats` for retrieving istio-proxy envoy metrics.

- **Fixed** the `--duration` flag never gets used in the `istioctl bug-report` command.

- **Fixed** using flags in `istioctl bug-report` results in errors.
  ([Issue #36103](https://github.com/istio/istio/issues/36103))

- **Fixed** `operator init --dry-run` creates unexpected namespaces.

- **Fixed** error format after json marshal in virtual machine config.
  ([Issue #36358](https://github.com/istio/istio/issues/36358))

## Documentation changes

- **Fixed** formatting of the telemetry configuration reference page.
