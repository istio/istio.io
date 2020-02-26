---
title: Change Notes
description: Istio 1.5 release notes.
weight: 10
---

## Traffic management

- service entry: optimize service entry updates #19305.
- fix readiness probe inconsistency #18164.
- xDS push optimize #18354.
- Override locality load balancer settings per host #18406.
- eds: do not trigger continuous full pushes when a pod is in crash loop #18574.
- Disable redirect calls to app itself via envoy #19308.
- add an `iptables` failure detector, default off #19534.
- Istio: add consecutive `5xx` and gateway errors for outlier detection #19771.
- **Improved** `EnvoyFilter` matching performance optimization #19786.
- handle http proxy while generating routes #19919.
- Allow non-intercepting proxies `CAP_NET_BIND_SERVICE` via annotation #20378.
- Initial support for custom Istio topology label kind/enhancement #19192.
- `istio-iptables`: Use `iptables-restore` by default #18847.
- Pilot-agent for in-process Ingress SDS  #18999.
- turn on protocol sniffing for inbound #18666.

## Security

- **Added** Beta authentication API. The new API separates peer (i.e mutual TLS) and origin (JWT) authentication into `PeerAuthentication` and `RequestAuthenticaiton` respectively. Both new APIs are workload-oriented, as opposed to service-oriented in alpha `AuthenticationPolicy`.
- **Added** Authorization Policy supports deny action and exclusion semantics.
- **Added** Auto mutual TLS is in Beta. The feature is enabled by default.
- **Added** SDS is in Stable. SDS is enabled by default for identity provisioning.
- **Improved** Node agent is merged with Pilot agent. This removes the requirement of pod security policy and improves security posture.
- **Improved** Support two providers for Pilot (`istiod`) certificate: Kubernetes CA and Citadel.
- **Improved** Support two types of JWT for CSR authentication: `first-party-jwt` and `third-party-jwt`.
- **Improved** Provision key and cert to Prometheus through Istio Agent.

## Telemetry

- **Added** TCP protocol support for v2 telemetry.
- **Added** gRPC response status code support in metrics/logs.
- **Added** support for Istio Canonical Service.
- **Improved** stability of v2 telemetry pipeline.
- **Added** alpha-level support for configurable telemetry in v2 telemetry.

Triage done:
- **Added** support for populating AWS platform metadata in Envoy node metadata.
- **Improved** Updated the Stackdriver adapter for Mixer to support configurable flush intervals for tracing data.
- **Added** support for a headless collector service to the Jaeger addon.
- Fixed `kubernetesenv` adapter to provide proper support for pods that contain a dot in their name.
- Updated the Fluentd adapter for Mixer to provide millisecond-resolution in exported timestamps.

- fix(bootstrap): add time-bounded platform detection logic with fail-fast #19971.
- mixer: remove explicit flush in OpenCensus tracing adapter #18074.
- mixer: Allow configuration of trace flush interval #18109.
- Added jaeger-collector-headless service #18278.
- Fix mixer source namespace attribute when dot in pod name  #19022.
- Let Fluentd adapter encode timestamp with millisecond #19093.

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

- Allow multiple ICPS's as `istioctl` manifest/upgrade/profile input #20190.
- Translate ICP into IOP when `istioctl` upgrade gets ICP as input. #20252.

- Use different exit code on `istioctl` parse error #18131.
- `istioctl analyze -L` shows all analyzers #19200.
- Allow `istioctl analyze` to suppress messages via command line #19673.
- Add timeout for `istioctl analyze` getting resources #19890.
- Add annotation for `enableCoreDump` #20096.
- Check resources for analyze suppression codes #20174.
- Make it possible to run `bookinfo` without root and with `readOnlyFilesystem` #16326.
- Add `--output-threshold` flag to `istioctl analyze` #18438.
- Add structured format options to `istioctl analyze` #18700.
- Use annotation methods provided by Istio API in analyzer #18829.
- Fix bug where analyzer suppressed cluster-level resource messages. #18935.
- Analysis output includes doc links #19105.
- add selector for `istioctl` dashboard #19191.
- Add `--all-namespaces` support to `istioctl analyze` #19209.
- Add a reference marker to analyzer message doc URL #19327.
- Allow analyzing content passed via `stdin` #19393.
- Graduate `istioctl analyze` out of experimental  #19488.
- Describe examples explicitly for `istioctl` wait #19558.
- Update operator --set help text #20204 #20342.
- fix script rename in consul README #19613.
- Add location to generated `ServiceEntry` #19677.
- `istioctl`: Add explicit namespace to `SvcDescribeCmd`test #19698.
- Add link for how to set HUB and TAG #20053.
