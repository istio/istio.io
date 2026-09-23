---
title: Announcing Istio 1.26.1
linktitle: 1.26.1
subtitle: Patch Release
description: Istio 1.26.1 patch release notes.
publishdate: 2025-05-29
release: 1.26.1
---

This release contains bug fixes to improve robustness. This release note describes what is different between Istio 1.26.0 and 1.26.1.

## Traffic Management

- **Updated** Gateway API version to `1.3.0` from `1.3.0-rc.1`. ([Issue #56310](https://github.com/istio/istio/issues/56310))

- **Fixed** a regression in Istio 1.26.0 that caused a panic in istiod when processing Gateway API hostnames. ([Issue #56300](https://github.com/istio/istio/issues/56300))

## Security

- **Fixed** an issue in the `pluginca` feature where `istiod` would silently fallback to the self-signed CA if the provided `cacerts` bundle was incomplete. The system now properly validates the presence of all required CA files and fails with an error if the bundle is incomplete.

## Installation

- **Fixed** a panic in `istioctl manifest translate` when the `IstioOperator` config contains multiple gateways. ([Issue #56223](https://github.com/istio/istio/issues/56223))

## istioctl

- **Fixed** false positives when `istioctl analyze` raised error `IST0134` even when `PILOT_ENABLE_IP_AUTOALLOCATE` was set to `true`. ([Issue #56083](https://github.com/istio/istio/issues/56083))
