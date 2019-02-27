---
title: Istio 1.0.5
publishdate: 2018-12-20
icon: notes
---

This release addresses some critical issues found by the community in prior releases.
This release note describes what's different between Istio 1.0.4 and Istio 1.0.5.

{{< relnote_links >}}

## Fixes

- Disabled the precondition cache in the `istio-policy` service as it lead to invalid results. The
cache will be reintroduced in a later release.

- Mixer now only generates spans when there is an enabled `tracespan` adapter, resulting in lower CPU overhead in normal cases.

- Fixed a problem that could lead Pilot to hang.
