---
title: Announcing Istio 1.3.4
description: Istio 1.3.4 release announcement.
publishdate: 2019-11-1
attribution: The Istio Team
subtitle: Minor Update
release: 1.3.4
aliases:
    - /news/announcing-1.3.4
---

This release includes bug fixes to improve robustness. This release note describes what's different between Istio 1.3.3 and Istio 1.3.4.

{{< relnote >}}

## Bug fixes

- **Fixed** a crashing bug in the Google node agent provider. ([Pull Request #18296](https://github.com/istio/istio/pull/18260))
- **Fixed** Prometheus annotations and updated Jaeger to 1.14. ([Pull Request #18274](https://github.com/istio/istio/pull/18274))
- **Fixed** in-bound listener reloads that occur on 5 minute intervals. ([Issue #18138](https://github.com/istio/istio/issues/18088))
- **Fixed** validation of key and certificate rotation. ([Issue #17718](https://github.com/istio/istio/issues/17718))
- **Fixed** invalid internal resource garbage collection. ([Issue #16818](https://github.com/istio/istio/issues/16818))
- **Fixed** webhooks that were not updated on a failure. ([Pull Request #17820](https://github.com/istio/istio/pull/17820)
- **Improved** performance of OpenCensus tracing adapter. ([Issue #18042](https://github.com/istio/istio/issues/18042))

## Minor Enhancements

- **Improved** reliability of the SDS service. ([Issue #17409](https://github.com/istio/istio/issues/17409), [Issue #17905](https://github.com/istio/istio/issues/17905])
- **Added** stable versions of failure domain labels. ([Pull Request #17755](https://github.com/istio/istio/pull/17755))
- **Added** update of the global mesh policy on upgrades. ([Pull Request #17033](https://github.com/istio/istio/pull/17033))
