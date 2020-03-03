---
title: Change Notes
description: Istio 1.5 release notes.
weight: 10
---

## Traffic management

- **Improved** performance of `ServiceEntry` updates #19305.
- **Improved** fix readiness probe inconsistency #18164.
- **Improved** performance of configuration updates by sending partial updates where possible #18354.
- **Added** an option to control locality load balancer settings per host #18406.
- **Fixed** an issue where pods crashing would trigger excessive configuration pushes #18574.
- **Fixed** issues with applications that call themselves #19308.
- **Added** detection of `iptables` failure when using Istio CNI #19534.
- **Added** `consecutive_5xx` and `gateway_errors` as outlier detection options #19771.
- **Improved** `EnvoyFilter` matching performance optimization #19786.
- **Added** support for `HTTP_PROXY` protocol #19919.
- **Improved** `iptables` setup to use `iptables-restore` by default #18847.
- **Enabled** [automatic protocol detection](https://istio.io/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection-experimental) by default #18666.

## Security

- **Added** Beta authentication API. The new API separates peer (i.e mutual TLS) and origin (JWT) authentication into `PeerAuthentication` and `RequestAuthentication` respectively. Both new APIs are workload-oriented, as opposed to service-oriented in alpha `AuthenticationPolicy`.
- **Added** Authorization Policy supports deny action and exclusion semantics.
- **Added** auto mutual TLS. This beta feature is enabled by default.
- **Added** SDS is in Stable. SDS is enabled by default for identity provisioning.
- **Improved** node agent by merging with Pilot agent. This improves the security posture by removing the requirement of a pod security policy.
- **Improved** Istio by including certificate provisioning functionality within Pilot.
- **Improved** Support Kubernetes [`first-party-jwt`](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens) as a fallback token for CSR authentication in clusters that [`third-party-jwt`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) is not supported.
- **Improved** Istio's Pilot Agent by provisioning key and certificates for Prometheus consumption.

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

- **Improved** the alpha `IstioControlPlane` API by replacing with the `IstioOperator` API.
**Added** `istioctl operator init` and `istioctl operator remove` commands istio/operator#643.
**Improved** reconciliation speed with caching #20344.

## `area/perf and scalability`

- **Improved** Skip unused services while generate clusters for the gateways #20124.
- **Improved** Skip calling `updateEDS` for headless service #18952.
- disable `SNI-DNAT` at ingress gateway by default #18431.
- The declaration of err overrides #19473.
- create slice with capacity, when capacity is known #18504.

## `area/test and release`

- **Added** Publish a `docker/istioctl` image #19079.

## `istioctl`
- **Added** mTLS analyzer - #18350
- **Added** JwtAnalyzer - #20812
- **Added** ServiceAssociationAnalyzer #19383
- **Added** SercretAnalyaer #19583
- **Added** sidecar ImageAnalyzer  #20929
- **Added** PortNameAnalyzer #19375
- **Added** Policy DeprecatedAnalyzer #20919
- **Updated** more validation rules for `RequestAuthentication` #19369.

- **Graduated** `istioctl analyze` out of experimental  #19488.

- **Added** a new flag `-A|--all-namespaces` to `istioctl analyze` to analyze the entire cluster #19209.
- **Added** support for analyzing content passed via `stdin` to `istioctl analyze` #19393.
- **Added** `istioctl analyze -L` to show a list of all analyzers available #19200.
- **Added** the ability to suppress messages from `istioctl analyze` #19673.
- **Added** structured format options to `istioctl analyze` #18700.
- **Added** links to relevant documentation to `istioctl analyze` output #19105.
- **Updated** annotation methods provided by Istio API in analyzer #18829.
- **Updated** istioctl analyze now loads files from a directory #20718
- **Updated** istioctl analyze to try to associate message with their source filename
- **Updated** istioctl analyze to print the namespace that is being analyzed #20515
- **Updated** istioctl analyze to analyze in-cluster resources by default. #19647
- **Fixed** bug where analyzer suppressed cluster-level resource messages. #18935.


- **Added** support for multiple input files to `istioctl manifest` #20190.
- **Replaced** the `IstioControlPlane` API with the `IstioOperator` API.
- **Added** selector for `istioctl` dashboard #19191.
- **Added** support for slices and lists in `istioctl manifest --set` flag #20631.
