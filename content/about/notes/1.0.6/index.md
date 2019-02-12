---
title: Istio 1.0.6
weight: 86
icon: /img/notes.svg
---

This release includes security vulnerability fixes and improvements to robustness.
This release note describes what's different between Istio 1.0.5 and Istio 1.0.6.

{{< relnote_links >}}

## Security vulnerability fixes

- Update Go `requests` and `urllib3` libraries in Bookinfo sample code per [`CVE-2018-18074`](https://nvd.nist.gov/vuln/detail/CVE-2018-18074) and [`CVE-2018-20060`](https://nvd.nist.gov/vuln/detail/CVE-2018-20060).
- Do not expose username and password in `Grafana` and `Kiali` ([Issue 7446](https://github.com/istio/istio/issues/7476), [Issue 7447](https://github.com/istio/istio/issues/7447)).
- Remove in-memory service registry in Pilot. This allowed adding endpoints to proxy configurations from within the cluster through a Pilot debug API.

## Robustness improvements

- Fix Pilot failing to push configuration under load ([Issue 10360](https://github.com/istio/istio/issues/10360)).
- Fix concurrent read/write to map leading to Pilot restart ([Issue 10868](https://github.com/istio/istio/issues/10868)).
- Fix goroutine leak in pilot ([Issue 10822](https://github.com/istio/istio/issues/10822)).
- Fix to `kubeenv` mixer adapter memory leak ([Issue 10393](https://github.com/istio/istio/issues/10393)).
