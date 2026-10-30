---
title: Announcing Istio 1.32.0
linktitle: 1.32.0
subtitle: Major Release
description: Istio 1.32 Release Announcement.
publishdate: 2026-11-05
release: 1.32.0
aliases:
    - /news/announcing-1.32
    - /news/announcing-1.32.0
---

We are pleased to announce the release of Istio 1.32. Thank you to all our contributors, testers, users, and enthusiasts for helping us get the 1.32.0 release published!
We would like to thank the Release Managers for this release, **Jackson Greer** from Microsoft, **Jianpeng He** from Tetrate, and **Jack Kawell** from Solo.io.

{{< relnote >}}

{{< tip >}}
Istio 1.32.0 is officially supported on Kubernetes versions 1.33 to 1.37.
{{< /tip >}}

## What's new?

### Gateway API

- **`AuthorizationPolicy` targeting `HTTPRoute`.** As an experimental feature, `AuthorizationPolicy` can now target Gateway API `HTTPRoute` resources via `targetRefs`, so `ALLOW` and `DENY` rules apply only to traffic matched by that route.
- **TLS tuning on gateways.** TLS-terminating gateways can override the advertised ALPN protocols with `alpnProtocols` and configure ECDH curves with `ecdhCurves`.
- **Experimental `XBackend` support** for describing how clients must connect to specific destinations.
- **agentgateway** now honors Gateway API frontend client certificate validation.

### Traffic management

- **Utilization-based load balancing.** A new `backendUtilization` policy on `DestinationRule` uses backend-reported ORCA load reports to send fewer requests to busier endpoints.
- **Richer outlier detection.** `DestinationRule.OutlierDetection` adds `outlierDetectionHttpErrorCodes`, to choose which HTTP status codes count as errors, and `failurePercentageThreshold`, to eject hosts based on failure rate.
- **Configurable inbound retries.** The new `defaultInboundHttpRetryPolicy` mesh config field configures, or disables with `{}`, the default retry policy on sidecar inbound routes.
- **`EnvoyFilter` transport socket matching.** Filter chain matches can now select by `transportSocket`, so patches precisely target chains that terminate TLS.
- **Mesh-wide `ProxyConfig` with selectors.** `ProxyConfig` resources with workload selectors in the root namespace now apply to matching workloads in all namespaces.

### Security

- **`presence` for JWT rules.** `RequestAuthentication` `jwtRules` can be marked `REQUIRED`, rejecting requests that are missing that token even when other rules are satisfied.
- **`PILOT_DISABLE_SELF_SIGNED_CA`** makes istiod fail to start its CA instead of generating or reusing a self-signed root.

### Telemetry

- **Native Prometheus histograms.** pilot-agent's metrics merger passes through the Prometheus protobuf format when scrapers request it, with a new `istio_agent_scrape_format_total` counter reporting the negotiated format.

### Plus much more

- **Headless TCP services** can opt in to a single wildcard listener instead of one listener per pod IP
- **`IST0178`** analyzer warning when an `EnvoyFilter` inserts an HTTP filter alongside an `AuthorizationPolicy` that targets an `HTTPRoute`
- **`ServiceEntry` validation** warnings for catch-all and very broad addresses
- **Kubernetes API client timeouts** in Istio components, configurable via `ISTIO_KUBE_HEADER_TIMEOUT` and `ISTIO_KUBE_REQUEST_TIMEOUT`
- **`GOMAXPROCS`** removed from all charts, since Go now sets it from CPU limits automatically

Read about these and more in the full [release notes](change-notes/).

## Upgrading to 1.32

We would like to hear from you regarding your experience upgrading to Istio 1.32. You can provide feedback in the `#release-1_32` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
