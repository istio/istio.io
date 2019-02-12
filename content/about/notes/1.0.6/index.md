---
title: Istio 1.0.6
weight: 86
icon: /img/notes.svg
---

This release includes security vulnerability fixes and improvements to robustness.
This release note describes what's different between Istio 1.0.5 and Istio 1.0.6.

{{< relnote_links >}}

## Security vulnerability fixes

- Update Go `requests` and `urllib3` libraries [#10551](https://github.com/istio/istio/pull/10551)
- Do not expose username and password in `Grafana` and `Kiali` [#10767](https://github.com/istio/istio/pull/10767)
- Remove in-memory service registry [#11543](https://github.com/istio/istio/pull/11543)

## Robustness improvements

- Fix potential concurrency problems [#10379](https://github.com/istio/istio/pull/10379), [#10970](https://github.com/istio/istio/pull/10970)
- Fix goroutine leak in pilot [#11134](https://github.com/istio/istio/pull/11134)
- Fix to `kubeenv` mixer adapter [#10880](https://github.com/istio/istio/pull/10880)
