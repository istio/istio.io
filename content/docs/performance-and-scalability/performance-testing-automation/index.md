---
title: Automation
description: How we ensure performance is tracked and improves or does not regress across releases.
weight: 50
---

Both the synthetic benchmarks (fortio based) and the realistic application (BluePerf)
are part of the nightly release pipeline and you can see the results on:

* [https://fortio-daily.istio.io/](https://fortio-daily.istio.io/)
* [https://ibmcloud-perf.istio.io/regpatrol/](https://ibmcloud-perf.istio.io/regpatrol/)

This enables us to catch regression early and track improvements over time.
