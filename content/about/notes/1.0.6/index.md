---
title: Istio 1.0.6
weight: 86
icon: notes
---

This release includes security vulnerability fixes and improvements to robustness.
This release note describes what's different between Istio 1.0.5 and Istio 1.0.6.

{{< relnote_links >}}

## Security vulnerability fixes

- Updated Go `requests` and `urllib3` libraries in Bookinfo sample code per [`CVE-2018-18074`](https://nvd.nist.gov/vuln/detail/CVE-2018-18074) and [`CVE-2018-20060`](https://nvd.nist.gov/vuln/detail/CVE-2018-20060).
- Fixed username and password being exposed in `Grafana` and `Kiali` ([Issue 7446](https://github.com/istio/istio/issues/7476), [Issue 7447](https://github.com/istio/istio/issues/7447)).
- Removed in-memory service registry in Pilot. This allowed adding endpoints to proxy configurations from within the cluster through a Pilot debug API.

## Robustness improvements

- Fixed Pilot failing to push configuration under load ([Issue 10360](https://github.com/istio/istio/issues/10360)).
- Fixed a race condition that would lead Pilot to crash and restart ([Issue 10868](https://github.com/istio/istio/issues/10868)).
- Fixed a memory leak in Pilot ([Issue 10822](https://github.com/istio/istio/issues/10822)).
- Fixed a memory leak in Mixer ([Issue 10393](https://github.com/istio/istio/issues/10393)).
