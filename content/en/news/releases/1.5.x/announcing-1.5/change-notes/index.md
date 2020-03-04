---
title: Change Notes
description: Istio 1.5 release notes.
weight: 10
---

## Traffic management

- **Improved** performance of the `ServiceEntry` resource by avoiding unnecessary full pushes #19305.
- **Improved** Envoy sidecar readiness probe to more accurate determine readiness #18164.
- **Improved** performance of Envoy proxy configuration updates via xDS by sending partial updates where possible #18354.
- **Added** an option to configure locality load balancing settings for each targeted service via destination rule #18406.
- **Fixed** an issue where pods crashing would trigger excessive Envoy proxy configuration pushes #18574.
- **Fixed** issues with applications such as headless services to call themselves directly without going through Envoy proxy #19308.
- **Added** detection of `iptables` failure when using Istio CNI #19534.
- **Added** `consecutiveGatewayErrors` and `consecutive5xxErrors` as outlier detection options within destination rule #19771.
- **Improved** `EnvoyFilter` matching performance #19786.
- **Added** support for `HTTP_PROXY` protocol #19919.
- **Improved** `iptables` setup to use `iptables-restore` by default #18847.
- **Improved** Gateway performance by filtering unused clusters. This setting is disabled by default #20124.

## Security

- **Added** Beta authentication API. The new API separates peer (i.e mutual TLS) and origin (JWT) authentication into `PeerAuthentication` and `RequestAuthentication` respectively. Both new APIs are workload-oriented, as opposed to service-oriented in alpha `AuthenticationPolicy`.
- **Added** [deny semantics](https://github.com/istio/api/blob/master/security/v1beta1/authorization.proto#L28) to Authorization Policy
- **Graduated** [auto mutual TLS](/docs/tasks/security/authentication/auto-mtls/) from alpha to beta. This feature is now enabled by default.
- **Improved** node level citadel agent by merging with pod level Istio agent. This improves the security posture by removing the requirement of a pod security policy.
- **Improved** Istio by including certificate provisioning functionality within istiod.
- **Improved** Support Kubernetes [`first-party-jwt`](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens) as a fallback token for CSR authentication in clusters that [`third-party-jwt`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) is not supported.
- **Added** Support Istio CA and Kubernetes CA to provision certificates for the control plane.
- **Added** Istio Agent provisions a key and certificates for Prometheus.
- **Graduated** SDS to stable and enabled by default. It provides identity provisioning for Istio Envoy proxies.

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
- **Added** `istioctl operator init` and `istioctl operator remove` commands.
- **Improved** reconciliation speed with caching #20344.


## `istioctl`
- **Added** mutual TLS analyzer - #18350
- **Added** `JwtAnalyzer` - #20812
- **Added** `ServiceAssociationAnalyzer` #19383
- **Added** `SercretAnalyzer` #19583
- **Added** sidecar `ImageAnalyzer`  #20929
- **Added** `PortNameAnalyzer` #19375
- **Added** `Policy DeprecatedAnalyzer` #20919
- **Updated** more validation rules for `RequestAuthentication` #19369.
- **Added** a new flag `-A|--all-namespaces` to `istioctl analyze` to analyze the entire cluster #19209.
- **Added** support for analyzing content passed via `stdin` to `istioctl analyze` #19393.
- **Added** `istioctl analyze -L` to show a list of all analyzers available #19200.
- **Added** the ability to suppress messages from `istioctl analyze` #19673.
- **Added** structured format options to `istioctl analyze` #18700.
- **Added** links to relevant documentation to `istioctl analyze` output #19105.
- **Updated** annotation methods provided by Istio API in analyzer #18829.
- **Updated** `istioctl analyze` now loads files from a directory #20718
- **Updated** `istioctl analyze` to try to associate message with their source filename
- **Updated** `istioctl analyze` to print the namespace that is being analyzed #20515
- **Updated** `istioctl analyze` to analyze in-cluster resources by default. #19647
- **Fixed** bug where analyzer suppressed cluster-level resource messages. #18935.
- **Added** support for multiple input files to `istioctl manifest` #20190.
- **Replaced** the `IstioControlPlane` API with the `IstioOperator` API.
- **Added** selector for `istioctl` dashboard #19191.
- **Added** support for slices and lists in `istioctl manifest --set` flag #20631.\
- **Graduated** `istioctl analyze` out of experimental  #19488.
- **Added** a `docker/istioctl` image #19079.
