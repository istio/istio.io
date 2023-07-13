---
title: Announcing Istio 1.17.4
linktitle: 1.17.4
subtitle: Patch Release
description: Istio 1.17.4 patch release.
publishdate: 2023-07-14
release: 1.17.4
---

This release note describes what’s different between Istio 1.17.3 and 1.17.4.

{{< relnote >}}

## Security update

- __[CVE-2023-35945](https://github.com/envoyproxy/envoy/security/advisories/GHSA-jfxv-29pc-x22r)__: (CVSS Score 7.5, High):
HTTP/2 memory leak in `nghttp2` codec

# Changes

- **Added** rolling update max unavailable to CNI Helm chart to speed up deploys.

- **Fixed** an issue where the cert validity was not accurate for `istioctl pc secret` command.

- **Fixed** an issue where Istiod might crash when a cluster is deleted and xDS cache is disabled.
  ([Issue #45798](https://github.com/istio/istio/issues/45798))

- **Fixed** an issue where specifying multiple include conditions by `--include` in bug report
  didn't work as expected. ([Issue #45839](https://github.com/istio/istio/issues/45839))

- **Fixed** an issue where disabling a log provider through Istio telemetry API would not work.

- **Fixed** an issue where `Telemetry` would not be fully disabled unless `match.metric=ALL_METRICS` was
  explicitly specified; matching all metrics is now correctly considered as the default.
