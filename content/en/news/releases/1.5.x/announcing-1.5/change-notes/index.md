---
title: Change Notes
description: Istio 1.5 release notes.
weight: 10
---

## Traffic management

- **Improved** performance of the `ServiceEntry` resource by avoiding unnecessary full pushes [#19305](https://github.com/istio/istio/pull/19305)
- **Improved** Envoy sidecar readiness probe to more accurate determine readiness [#18164](https://github.com/istio/istio/pull/18164).
- **Improved** performance of Envoy proxy configuration updates via xDS by sending partial updates where possible [#18354](https://github.com/istio/istio/pull/18354).
- **Added** an option to configure locality load balancing settings for each targeted service via destination rule[#18406](https://github.com/istio/istio/pull/18406).
- **Fixed** an issue where pods crashing would trigger excessive Envoy proxy configuration pushes [#18574](https://github.com/istio/istio/pull/18574).
- **Fixed** issues with applications such as headless services to call themselves directly without going through Envoy proxy [#19308](https://github.com/istio/istio/pull/19308).
- **Added** detection of `iptables` failure when using Istio CNI [#19534](https://github.com/istio/istio/pull/19534)
- **Added** `consecutiveGatewayErrors` and `consecutive5xxErrors` as outlier detection options within destination rule [#19771](https://github.com/istio/istio/pull/19771).
- **Improved** `EnvoyFilter` matching performance [#19786](https://github.com/istio/istio/pull/19786)
- **Added** support for `HTTP_PROXY` protocol [#19919](https://github.com/istio/istio/pull/19919).
- **Improved** `iptables` setup to use `iptables-restore` by default [#18847](https://github.com/istio/istio/pull/18847).
- **Improved** Gateway performance by filtering unused clusters. This setting is disabled by default [#20124](https://github.com/istio/istio/pull/20124).

## Security

- **Graduated** SDS to stable and enabled by default. It provides identity provisioning for Istio Envoy proxies.
- **Added** Beta authentication API. The new API separates peer (i.e mutual TLS) and origin (JWT) authentication into [`PeerAuthentication`](https://github.com/istio/api/blob/master/security/v1beta1/peer_authentication.proto) and [`RequestAuthentication`](https://github.com/istio/api/blob/master/security/v1beta1/request_authentication.proto) respectively. Both new APIs are workload-oriented, as opposed to service-oriented in alpha `AuthenticationPolicy`.
- **Added** [deny semantics](https://github.com/istio/api/blob/master/security/v1beta1/authorization.proto#L28) to Authorization Policy
- **Graduated** [auto mutual TLS](/docs/tasks/security/authentication/auto-mtls/) from alpha to beta. This feature is now enabled by default.
- **Improved** [SDS security](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret) by merging Node Agent with Pilot Agent as Istio Agent and removing cross-pod UDS, which no longer requires users to deploy Kubernetes pod security policies for UDS connections.
- **Improved** Istio by including certificate provisioning functionality within istiod.
- **Added** Support Kubernetes [`first-party-jwt`](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens) as a fallback token for CSR authentication in clusters where [`third-party-jwt`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) is not supported.
- **Added** Support Istio CA and Kubernetes CA to provision certificates for the control plane, configurable via `values.global.pilotCertProvider`.
- **Added** Istio Agent provisions a key and certificates for Prometheus.

## Telemetry

- **Added** TCP protocol support for v2 telemetry.
- **Added** gRPC response status code support in metrics/logs.
- **Added** support for Istio Canonical Service.
- **Improved** stability of v2 telemetry pipeline.
- **Added** alpha-level support for configurability in v2 telemetry.
- **Added** support for populating AWS platform metadata in Envoy node metadata.
- **Improved** Stackdriver adapter for Mixer to support configurable flush intervals for tracing data.
- **Added** support for a headless collector service to the Jaeger addon.
- **Fixed** `kubernetesenv` adapter to provide proper support for pods that contain a dot in their name.
- **Improved** the Fluentd adapter for Mixer to provide millisecond-resolution in exported timestamps.

## Configuration management

## Operator

- **Replaced** the alpha `IstioControlPlane` API with the new [`IstioOperator`](/docs/reference/config/istio.operator.v1alpha1/) API to align with existing `MeshConfig` API.
- **Added** `istioctl operator init` and `istioctl operator remove` commands.
- **Improved** reconciliation speed with caching [`operator#667`](https://github.com/istio/operator/pull/667).

## `istioctl`

- **Graduated** [`Istioctl Analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) out of experimental.
- **Added** various analyzers: mutual TLS, JWT, `ServiceAssociation`, Secret, sidecar image, port name and policy deprecated analyzers.
- **Updated** more validation rules for `RequestAuthentication`.
- **Added** a new flag `-A|--all-namespaces` to [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) to analyze the entire cluster.
- **Added** support for analyzing content passed via `stdin` to [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/).
- **Added** [`istioctl analyze -L`](/docs/ops/diagnostic-tools/istioctl-analyze/) to show a list of all analyzers available.
- **Added** the ability to suppress messages from [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/).
- **Added** structured format options to [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/).
- **Added** links to relevant documentation to [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) output.
- **Updated** annotation methods provided by Istio API in [`Istioctl Analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/).
- **Updated** [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) now loads files from a directory.
- **Updated** [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) to try to associate message with their source filename.
- **Updated** [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) to print the namespace that is being analyzed.
- **Updated** [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) to analyze in-cluster resources by default.
- **Fixed** bug where [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) suppressed cluster-level resource messages.
- **Added** support for multiple input files to `istioctl manifest`.
- **Replaced** the `IstioControlPlane` API with the `IstioOperator` API.
- **Added** selector for [`istioctl dashboard`](/docs/reference/commands/istioctl/#istioctl-dashboard).
- **Added** support for slices and lists in [`istioctl manifest --set`](/docs/reference/commands/istioctl/#istioctl-manifest) flag.
- **Added** a `docker/istioctl` image #19079.
