---
title: Announcing Istio 1.9.1
linktitle: 1.9.1
subtitle: Patch Release
description: Istio 1.9.1 patch release.
publishdate: 2021-03-01
release: 1.9.1
aliases:
    - /news/announcing-1.9.1
---

This release fixes the security vulnerability described in [our March 1st, 2021 news post](/news/security/istio-security-2021-001)
as well as bug fixes to improve robustness.

This release note describes what’s different between Istio 1.9.0 and Istio 1.9.1.

{{< tip >}}
Qualification testing for this release completed successfully on March 3rd, 2021.
{{< /tip >}}

{{< relnote >}}

## Security update

A [zero-day security vulnerability](https://groups.google.com/g/envoy-security-announce/c/Hp16L27L00Q) was fixed in the version of Envoy shipped with Istio 1.9.0.  This vulnerability was fixed on February 26th, 2021. 1.9.0 is the only version of Istio that includes the vulnerable version of Envoy. This vulnerability can only be exploited
on misconfigured systems.

## Changes

- **Improved** sidecar injection to automatically specify the `kubectl.kubernetes.io/default-logs-container`. This ensures `kubectl logs`
  defaults to reading the application container's logs, rather than requiring explicitly setting the container.
  ([Issue #26764](https://github.com/istio/istio/issues/26764))

- **Improved** the sidecar injector to better utilize pod labels to determine if injection is required. This is not enabled
  by default in this release, but can be tested using `--set values.sidecarInjectorWebhook.useLegacySelectors=false`.  ([Issue #30013](https://github.com/istio/istio/issues/30013))

- **Updated** Prometheus metrics to include `source_cluster` and `destination_cluster` labels by default for all scenarios. Previously, this was only enabled for multi-cluster scenarios.
  ([Issue #30036](https://github.com/istio/istio/issues/30036))

- **Updated** default access log to include `RESPONSE_CODE_DETAILS` and `CONNECTION_TERMINATION_DETAILS` for proxy version >= 1.9.
  ([Issue #27903](https://github.com/istio/istio/issues/27903))

- **Updated** Kiali addon to the latest version `v1.29`.
  ([Issue #30438](https://github.com/istio/istio/issues/30438))

- **Added**  `enableIstioConfigCRDs` to `base` to allow users to specify whether the Istio CRDs will be installed.  ([Issue #28346](https://github.com/istio/istio/issues/28346))

- **Added** support for `DestinationRule` inheritance for mesh/namespace level rules. Enable feature with the `PILOT_ENABLE_DESTINATION_RULE_INHERITANCE` environment variable.
  ([Issue #29525](https://github.com/istio/istio/issues/29525))

- **Added** support for applications that bind to their pod IP address, rather than wildcard or localhost address, through the `Sidecar` API.
  ([Issue #28178](https://github.com/istio/istio/issues/28178))

- **Added** flag to enable capture of DNS traffic to the `istio-iptables` script.
  ([Issue #29908](https://github.com/istio/istio/issues/29908))

- **Added** canonical service tags to Envoy-generated trace spans.
  ([Issue #28801](https://github.com/istio/istio/issues/28801))

- **Fixed** an issue causing the timeout header `x-envoy-upstream-rq-timeout-ms` to not be honored.
  ([Issue #30885](https://github.com/istio/istio/issues/30885))

- **Fixed** an issue where access log service causes Istio proxy to reject configuration.
  ([Issue #30939](https://github.com/istio/istio/issues/30939))

- **Fixed** an issue causing an alternative Envoy binary to be included in the Docker image. The binaries are functionally equivalent.
  ([Issue #31038](https://github.com/istio/istio/issues/31038))

- **Fixed** an issue where the TLS v2 version was enforced only on HTTP ports. This option is now applied to all ports.

- **Fixed** an issue where Wasm plugin configuration update will cause requests to fail.
  ([Issue #29843](https://github.com/istio/istio/issues/29843))

- **Removed** support for reading Istio configuration over the Mesh Configuration Protocol (MCP).
  ([Issue #28634](https://github.com/istio/istio/issues/28634))
