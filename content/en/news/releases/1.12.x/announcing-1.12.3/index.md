---
title: Announcing Istio 1.12.3
linktitle: 1.12.3
subtitle: Patch Release
description: Istio 1.12.3 patch release.
publishdate: 2022-02-10
release: 1.12.3
aliases:
    - /news/announcing-1.12.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.12.2 and Istio 1.12.3.

{{< relnote >}}

## Changes

- **Fixed** an issue where scaling endpoint for a service from 0 to 1 might cause client side service account verification to be populated incorrectly.
  ([Issue #36456](https://github.com/istio/istio/issues/36456))

- **Fixed** an issue where in place upgrade will cause TCP connections between <1.12 proxies and 1.12 proxies to fail.
  ([Issue #36797](https://github.com/istio/istio/pull/36797))

- **Fixed** an issue that if duplicated cipher suites were configured in Gateway, they were pushed to Envoy configuration. With this fix, duplicated cipher
suites will be ignored and logged.
  ([Issue #36805](https://github.com/istio/istio/issues/36805))

- **Fixed** Helm chart generating an invalid manifest when given a boolean or numeric value for environment variables.
  ([Issue #36946](https://github.com/istio/istio/issues/36946))

- **Fixed** error format after json marshaling in virtual machine config.
  ([Issue #36358](https://github.com/istio/istio/issues/36358))

- **Fixed** an issue where using `ISTIO_MUTUAL` TLS mode in Gateways while also setting `credentialName` causes mutual TLS to not be configured. This configuration is now rejected, as `ISTIO_MUTUAL` is intended to be used without `credentialName` set. The old behavior can be retained by configuring the `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME=true` environment variable in Istiod.
