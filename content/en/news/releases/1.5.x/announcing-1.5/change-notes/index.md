---
title: Change Notes
description: Istio 1.5 release notes.
weight: 10
---

## Traffic management

- **Improved** performance of `ServiceEntry` updates #19305.
- **Improved**fix readiness probe inconsistency #18164.
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

- **Added** Beta authentication API. The new API separates peer (i.e mutual TLS) and origin (JWT) authentication into `PeerAuthentication` and `RequestAuthenticaiton` respectively. Both new APIs are workload-oriented, as opposed to service-oriented in alpha `AuthenticationPolicy`.
- **Added** Authorization Policy supports deny action and exclusion semantics.
- **Added** Auto mutual TLS is in Beta. The feature is enabled by default.
- **Added** SDS is in Stable. SDS is enabled by default for identity provisioning.
- **Improved** Node agent is merged with Pilot agent. This removes the requirement of pod security policy and improves security posture.
- **Improved** Merge Citadel certificate provisioning functionality into Pilot.
- **Improved** Support Kubernetes `first-party-jwt` as a fallback token for CSR authentication in clusters that `third-party-jwt` is not supported.
- **Improved** Provision key and cert to Prometheus through Istio Agent.
- **Improved** Support Citadel to provision the control plane certificate.

## Telemetry

- **Added** TCP protocol support for v2 telemetry.
- **Added** gRPC response status code support in metrics/logs.
- **Added** support for Istio Canonical Service.
- **Improved** stability of v2 telemetry pipeline.
- **Added** alpha-level support for configurability in v2 telemetry.
- **Added** support for populating AWS platform metadata in Envoy node metadata.
- **Improved** Updated the Stackdriver adapter for Mixer to support configurable flush intervals for tracing data.
- **Added** support for a headless collector service to the Jaeger addon.
- **Fixed** `kubernetesenv` adapter to provide proper support for pods that contain a dot in their name.
- **Improved** the Fluentd adapter for Mixer to provide millisecond-resolution in exported timestamps.


## Configuration management

- Simplify CRD files #18340.
- Adding `ServiceRoleServicesAnalyzer` #18160.
- Add analyzers for Sidecar workload selectors #18600.
- Add analyzer rules for `VirtualService` destination ports #18674.
- Use `k8s.io/apimachinery` yaml decoder in `kubesource` #19045.
- Local analysis gets mesh configuration from the cluster (if available) or a specific file if provided #19055.
- Order analyzer tests by package name, not name #19243.
- Analysis functions for getting mesh configuration #19274.
- Add analyzer for missing `credentialName` on Gateway #19583.
- Remove --discovery flag and default `--use-kube` to true #19647.
- Add default resource definition support for analyzers #19808.
- Refactor messages to track resource rather than origin #20006.
- Add Envoy filter types so `typed_config` can be used when configuring `EnvoyFilters` #20156.
- Add Kubernetes dry-run test for galley #18145.
- Include `virtualservice` mirror destinations in analysis #18476.
- minor cleanup & added more tests for `resource.Name` #18524.
- Remove endpoints/ingresses/nodes from annotations analyzer  #18930.
- Skip Analyzers that require inputs not in the current snapshot  #18961.
- Fix `mcpc` tools error #19032.
- Use specific message when sidecar is missing #19428.
- Update analyzer `IsIstioControlPlane` filter to also look for `release=istio` #19906.
- Fixing race conditions in Analyzing Distributor tests  #20136.
- Implement extra environment variables from `ProxyMetadata` #20447.
- Check for err when adding policy in tests #18478.
- Add unit test for validation analyzer wrapper #18801.
- Require the namespace for the webhook secret #18901.
- add test to help enforce that new analyzers are added to All() #19239.
- Analyzer test harness supports custom mesh configuration, add test case for … #19508.
- Don't validate `credentialName` in gateway secrets analyzer if it isn't specified  #19905.
- Make headless service passthrough resolution optional #19992.
- Put chunk count back into error message in `kubesource` #19358.
- clean up logging for service port conversion  #19479.
- Fix typo in analyzer name #19557.
- Don't instruct users to delete the pod  #19584.
- Update analysis `readme` to match #19729 #19760.
- add quotation marks for PATH #19433  #19774.
- Allow re-use of `base.yaml` #19858.


## `area/perf and scalability`

- **Improved** Skip unused services while generate clusters for the gateways #20124.
- **Improved** Skip calling `updateEDS` for headless service #18952.
- disable `SNI-DNAT` at ingress gateway by default #18431.
- The declaration of err overrides #19473.
- create slice with capacity, when capacity is known #18504.

## `area/test and release` - Triage done

- Build a docker image for `istioctl` #19079.

## `istioctl`
- **Added** Introduce mutual TLS analyzer #18917.
- **Added** `ServiceAssociation` Analyzer #19383.
- **Added** add `PortNameAnalyzer` #19375.
- **Added** more validation rules for `RequestAuthentication` #19369.

- **Added** support for multiple input files to `istioctl manifest` #20190.
- **Replaced** the `IstioControlPlane` API with the `IstioOperator` API.
- **Added** `istioctl analyze -L` to show a list of all analyzers available #19200.
- **Added** the ability to suppress messages from `istioctl analyze` #19673.
- **Improved** the `bookinfo` demo to run without root permissions #16326.
- **Added** structured format options to `istioctl analyze` #18700.
- Use annotation methods provided by Istio API in analyzer #18829.
- Fix bug where analyzer suppressed cluster-level resource messages. #18935.
- **Added** links to relevant documentation to `istioctl analyze` output #19105.
- add selector for `istioctl` dashboard #19191.
- **Added** a new flag `--all-namespaces` to `istioctl analyze` to analyze the entire cluster #19209.
- **Added** support for analyzing content passed via `stdin` to `istioctl analyze` #19393.
- **Graduated** `istioctl analyze` out of experimental  #19488.
