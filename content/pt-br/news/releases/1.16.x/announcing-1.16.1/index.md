---
title: Announcing Istio 1.16.1
linktitle: 1.16.1
subtitle: Patch Release
description: Istio 1.16.1 patch release.
publishdate: 2022-12-12
release: 1.16.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.16.0 and Istio 1.16.1.

This release includes security fixes in Go 1.19.4 (released 2022-12-06) for the `os` and `net/http` packages.

{{< relnote >}}

## Changes

- **Deprecated** using `PILOT_CERT_PROVIDER=kubernetes` for Kubernetes versions less than 1.20.

- **Updated** Kiali addon to version 1.59.1.

- **Fixed** OpenTelemetry tracer not working. ([Issue #42080](https://github.com/istio/istio/issues/42080))

- **Fixed** case where `ValidatingWebhookConfiguration` would be different when installed using Helm versus istioctl.

- **Fixed** ServiceEntries using `DNS_ROUND_ROBIN` from being able to specify 0 endpoints. ([Issue #42184](https://github.com/istio/istio/issues/42184))

- **Fixed** an issue preventing `istio-proxy` from accessing the Root CA when `automountServiceAccountToken` was set to false and `PILOT_CERT_PROVIDER` environment variable is set to `kubernetes`.

- **Fixed** an issue where gateway pods were not respecting the `global.imagePullPolicy` specified in the Helm values.
