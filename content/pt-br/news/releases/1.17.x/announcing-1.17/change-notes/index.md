---
title: Istio 1.17.0 Change Notes
linktitle: 1.17.0
subtitle: Minor Release
description: Istio 1.17.0 change notes.
publishdate: 2023-02-14
release: 1.17.0
weight: 10
---

## Deprecation Notices

These notices describe functionality that will be removed in a future release according to [Istio's deprecation policy](/docs/releases/feature-stages/#feature-phase-definitions). Please consider upgrading your environment to remove the deprecated functionality.

- **Deprecated** setting `PILOT_CERT_PROVIDER` to `kubernetes` for Kubernetes versions less than 1.20. [PR #42233](https://github.com/istio/istio/pull/42233)

- **Deprecated** Lightstep provider. Please use OpenTelemetry provider instead. [Issue #40027](https://github.com/istio/istio/issues/40027)

## Traffic Management

- **Improved** `MostSpecificHostMatch` to prevent full scanning hosts when encountering wildcards. [Issue #41453](https://github.com/istio/istio/issues/41453)

- **Improved** Gateway naming conventions to be the concatenation of `Name` and `GatewayClassName`. Deployment also now deploys with its own Service Account, rather than using the `default` token. Naming convention affects name of Deployment, Service and Service Account. [PR #43103](https://github.com/istio/istio/pull/43103)

- **Added** dual stack support for `statefulsets/headless`, service entry and gateway and use `getWildcardsAndLocalHost` for inbound cluster building. [PR #42712](https://github.com/istio/istio/pull/42712)

- **Added** support for `ADD`, `REMOVE`, `REPLACE`, `INSERT_FIRST`, `INSERT_BEFORE`, `INSERT_AFTER` operations for `LISTENER_FILTER` in `EnvoyFilter`. [Issue #41445](https://github.com/istio/istio/issues/41445)

- **Added** validation to `Gateway` and `Sidecar` to prevent partial wildcards as Envoy does not support them in hostnames. [Issue #42094](https://github.com/istio/istio/issues/42094)

- **Added** support for k8s `ServiceInternalTrafficPolicy` (does not take `ProxyTerminatingEndpoints` into account). [Issue #42377](https://github.com/istio/istio/issues/42377)

- **Added** `excludeInterfaces` support to the CNI plugin. [Issue #42381](https://github.com/istio/istio/pull/42381)

- **Added** support for missing resource types to `/config_dump` API. [PR #42658](https://github.com/istio/istio/pull/42658)

- **Fixed** `istio-clean-iptables` to properly cleanup when `InboundInterceptionMode` is TPROXY. [PR #41431](https://github.com/istio/istio/pull/41431)

- **Fixed** `PrivateKeyProvider` may not be changed using proxy-config. [Issue #41760](https://github.com/istio/istio/issues/41760)

- **Fixed** issue where Istio and K8S Gateway API resources are not handled correctly when namespace is selected or deselected by discovery selectors or namespace label (`ENABLE_ENHANCED_RESOURCE_SCOPING=true`). [Issue #42173](https://github.com/istio/istio/issues/42173)

- **Fixed** ServiceEntries using `DNS_ROUND_ROBIN` being able to specify 0 endpoints. [Issue #42184](https://github.com/istio/istio/issues/42184)

- **Fixed** ServiceEntries with a different revision label (than the Istio version installed) were being processed and endpoints for them created. [Issue #42212](https://github.com/istio/istio/issues/42212)

- **Fixed** an issue where the sync timeout setting doesn't work on the remote clusters. [PR #42252](https://github.com/istio/istio/pull/42252)

- **Fixed** Kubernetes service `exportTo` annotation not working on gateways by fixing gateway service dependencies. [Issue #42400](https://github.com/istio/istio/issues/42400)

- **Fixed** locality label missing for a sidecar without service selected. [PR #42412](https://github.com/istio/istio/pull/42412)

- **Fixed** an issue where the network endpoints are incorrectly computed when network gateway changes. [Issue #42818](https://github.com/istio/istio/issues/42818)

- **Fixed** auto-passthrough gateways not getting XDS pushes on service updates if `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` is enabled. [PR #42721](https://github.com/istio/istio/pull/42721)

- **Fixed** VirtualService delegate behavior not working with `defaultVirtualServiceExportTo: ["."]` setting. [Issue #42602](https://github.com/istio/istio/issues/42602)

- **Fixed** Pilot push XDS panic when `PortLevelSettings[].Port` is nil leading to abnormal exit of Pilot. [Issue #42598](https://github.com/istio/istio/issues/42598)

- **Fixed** a bug that caused the Namespace's network label to have a higher priority than the Pod's network label. [Issue #42675](https://github.com/istio/istio/issues/42675)

- **Fixed** pilot status to not log too many errors when `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` is not enabled. [Issue #42612](https://github.com/istio/istio/issues/42612)

## Security

- **Added** validation warning message for L7 Deny rules which will block all TCP traffic under the scope of the policy having that rule. [PR #41802](https://github.com/istio/istio/pull/41802)

- **Added** support for using QAT (`QuickAssist Technology`) `PrivateKeyProvider` in SDS. [PR #42203](https://github.com/istio/istio/pull/42203)

- **Added** configuration for selecting QAT private key provider for gateways and sidecars. [PR #2565](https://github.com/istio/api/pull/2565)

- **Added** support to Copy JWT claims to HTTP request headers. [Issue #39724](https://github.com/istio/istio/issues/39724)

- **Fixed** an issue preventing istio-proxy to access root CA when `automountServiceAccountToken` is `false` and `PILOT_CERT_PROVIDER` is `kubernetes`. [PR #42233](https://github.com/istio/istio/pull/42233)

## Telemetry

- **Updated** the Telemetry API to use a new native extension (stats) for Prometheus stats instead of the Wasm-based extension. This improves CPU overhead and memory usage of the feature. Custom dimensions no longer require regex and bootstrap annotations. If customizations use CEL expressions with Wasm attributes, they are likely to be affected. [PR #41441](https://github.com/istio/istio/pull/41441)

- **Added** an analyzer for Telemetry resource. [Issue #41170](https://github.com/istio/istio/issues/41170) [PR #41785](https://github.com/istio/istio/pull/41785)

- **Added** support for `reporting_interval`. This allows end-users to configure `tcp_reporting_duration` (configuration of the time between calls) via the Telemetry API for metrics reporting. This currently supports TCP metrics only, but in the future we may use this for long duration HTTP streams. [Issue #41763](https://github.com/istio/istio/issues/41763)

- **Fixed** an issue with bad request `malformed Host header` in the Telemetry API when configuring `Datadog` tracing provider. [Issue #41829](https://github.com/istio/istio/issues/41829)

- **Fixed** OpenTelemetry tracer not working because of missing service name. [Issue #42080](https://github.com/istio/istio/issues/42080)

## Installation

- **Updated** Kiali addon from version `1.55.1` to `1.63.1`. [PR #43052](https://github.com/istio/istio/pull/43052), [PR #42193](https://github.com/istio/istio/pull/42193), [PR #41984](https://github.com/istio/istio/pull/41984)

- **Updated** minimum supported Kubernetes version to `1.23.x`. [PR #43252](https://github.com/istio/istio/pull/43252)

- **Added** `--purge` flag to `istioctl operator remove` which will remove all revisions of Istio operator. [Issue #41547](https://github.com/istio/istio/issues/41547)

- **Added** support for allowing CSR signers via Helm installation. [PR #41923](https://github.com/istio/istio/pull/41923)

- **Added** an input to the Gateway Helm deployment to explicitly set the `imagePullPolicy` of a gateway deployment. [Issue #42852](https://github.com/istio/istio/issues/42852)

- **Fixed** `istioctl install` fails when specifying `--revision default`. [PR #41912](https://github.com/istio/istio/pull/41912)

- **Fixed** inconsistent behavior of `istioctl verify-install` when `--revision` is not specified and when it is specified with `default`. [PR #41912](https://github.com/istio/istio/pull/41912)

- **Fixed** `mutatingwebhook` not being split when setting multiple revision tags. [Issue #42234](https://github.com/istio/istio/issues/42234)

- **Fixed** initialization of secure gRPC server of Pilot when serving certificates are provided in default location. [Issue #42249](https://github.com/istio/istio/issues/42249)

- **Fixed** `appProtocol` field not taking effect in IstioOperator `ServicePort`. [Issue #42759](https://github.com/istio/istio/issues/42759)

- **Fixed** an issue where gateway pods were not respecting the `global.imagePullPolicy` specified in the Helm values. [PR #42026](https://github.com/istio/istio/pull/42026)

- **Removed** warning if `istio-cni` is not the default CNI plugin when CNI is used as a standalone plugin. [PR #41858](https://github.com/istio/istio/pull/41858)

- **Removed** fetching charts from URLs in `istio-operator`. [Issue #41704](https://github.com/istio/istio/issues/41704)

## istioctl

- **Added** `revision` flag to admin log to switch controls between `Istiods`. [PR #41321](https://github.com/istio/istio/pull/41321)

- **Updated** `admin log`'s `-r` flag to be shorthand for `--revision` for consistency with other commands (originally `-r` was shorthand for `--reset`). [PR #41321](https://github.com/istio/istio/pull/41321)

- **Updated** `client-go` to `v1.26.1`, removing support for `azure` and `gcp` auth plugins. [PR #43101](https://github.com/istio/istio/pull/43101)

- **Added** `istioctl proxy-config ecds` to support retrieving typed extension configuration from Envoy for a specified pod. [PR #42365](https://github.com/istio/istio/pull/42365)

- **Added** the ability to set proxy log level for all pods in a deployment for `istioctl proxy-config log` command. [Issue #42919](https://github.com/istio/istio/issues/42919)

- **Added** `--revision` to `istioctl analyze` to specify a specific revision. [Issue #38148](https://github.com/istio/istio/issues/38148)

- **Fixed** manifest URL path (for downloading Istio version from a `Github` release) to support multi-arch instead of hard coding it. [PR #41483](https://github.com/istio/istio/pull/41483)

- **Fixed** the default behavior of generating manifests using the helm chart library when using `istioctl` without `--cluster-specific` option to instead use the minimum Kubernetes version defined by `istioctl`. [Issue #42441](https://github.com/istio/istio/issues/42441)

- **Fixed** the issue where `istioctl analyze` was throwing `SIGSEGV` when optional field `filter` was missing under `EnvoyFilter.ListenerMatch.FilterChainMatch` section. [Issue #42831](https://github.com/istio/istio/issues/42831)

- **Fixed** `istioctl proxy-config` failure when a user specifies a custom proxy admin port with `--proxy-admin-port`. [Issue #43063](https://github.com/istio/istio/issues/43063)

- **Fixed** `istioctl version` not compatible with custom versions. [PR #41650](https://github.com/istio/istio/pull/41650)

- **Fixed** `istioctl validate` not detecting service port `appProtocol`. [PR #41517](https://github.com/istio/istio/pull/41517)

- **Fixed** `istioctl proxy-config endpoint -f -` returns `Error: open -: no such file or directory`. [Issue #43045](https://github.com/istio/istio/issues/43045)

## Documentation changes

- **Fixed** incorrect `pilot-discovery` environment variable name from `VERIFY_CERT_AT_CLIENT` to `VERIFY_CERTIFICATE_AT_CLIENT`. [PR #2596](https://github.com/istio/api/pull/2596)

- **Removed** comment about not supporting regex for delegate VirtualService. [Issue #2527](https://github.com/istio/api/issues/2527)
