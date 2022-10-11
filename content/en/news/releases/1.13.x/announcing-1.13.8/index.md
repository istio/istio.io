---
title: Announcing Istio 1.13.8
linktitle: 1.13.8
subtitle: Patch Release
description: Istio 1.13.8 patch release.
publishdate: 2022-09-12
release: 1.13.8
---

This release contains bug fixes to improve robustness.
This release note describes what’s different between Istio 1.13.7 and Istio 1.13.8.

{{< relnote >}}

## Changes

- **Fixed** an issue where Istio did not update the list of endpoints in `STRICT_DNS` clusters during workload instance updates.  ([Issue #39505](https://github.com/istio/istio/issues/39505))

- **Fixed** an issue where a service, with and without Virtual Service timeouts specified,
  is incorrectly setting the timeouts.  ([Issue #40299](https://github.com/istio/istio/issues/40299))

- **Fixed** an issue where `istiod` starts up very slowly when
  connectivity to GCP metadata service is only partially broken.
  ([Issue #40601](https://github.com/istio/istio/issues/40601))

- **Fixed** an issue causing TLS `ServiceEntries` to sometimes not work when created after TCP ones.

- **Fixed** an issue where `istioctl analyze` started showing invalid warning messages.

- **Fixed** potential memory leak when updating hostname of service entries.
