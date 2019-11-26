---
title: Announcing Istio 1.3.5
linktitle: 1.3.5
description: Istio 1.3.5 patch release.
publishdate: 2019-11-11
attribution: The Istio Team
subtitle: Minor Update
release: 1.3.5
aliases:
    - /zh/news/2019/announcing-1.3.5
    - /zh/news/announcing-1.3.5
---

This release contains fixes for the security vulnerability described in [our November 11, 2019 news post](/zh/news/security/istio-security-2019-006)  as well as bug fixes to improve robustness. This release note describes what's different between Istio 1.3.4 and Istio 1.3.5.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2019-006** A DoS vulnerability has been discovered in Envoy.

__[CVE-2019-18817](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18817)__: An infinite loop can be triggered in Envoy if the option `continue_on_listener_filters_timeout` is set to True, which is the case in Istio. This vulnerability could be leveraged for a DoS attack. If you applied the mitigation mentioned in [our November 11, 2019 news post](/zh/news/security/istio-security-2019-006), you can remove the mitigation once you upgrade to Istio 1.3.5 or newer.

## Bug fixes

- **Fixed** Envoy listener configuration for TCP headless services. ([Issue #17748](https://github.com/istio/istio/issues/17748))
- **Fixed** an issue which caused stale endpoints to remain even when a deployment was scaled to 0 replicas. ([Issue #14436](https://github.com/istio/istio/issues/14336))
- **Fixed** Pilot to no longer crash when an invalid Envoy configuration is generated. ([Issue 17266](https://github.com/istio/istio/issues/17266))
- **Fixed** an issue with the `destination_service_name` label not getting populated for TCP metrics related to BlackHole/Passthrough clusters. ([Issue 17271](https://github.com/istio/istio/issues/17271))
- **Fixed** an issue with telemetry not reporting metrics for BlackHole/Passthrough clusters when fall through filter chains were invoked. This occurred when explicit `ServiceEntries` were configured for external services. ([Issue 17759](https://github.com/istio/istio/issues/17759))

## Minor enhancements

- **Added** support for Citadel to periodically check the root certificate remaining lifetime and rotate expiring root certificates. ([Issue 17059](https://github.com/istio/istio/issues/17059))
- **Added** `PILOT_BLOCK_HTTP_ON_443` boolean environment variable to Pilot. If enabled, this flag prevents HTTP services from running on port 443 in order to prevent conflicts with external HTTP services. This is disabled by default. ([Issue 16458](https://github.com/istio/istio/issues/16458))
