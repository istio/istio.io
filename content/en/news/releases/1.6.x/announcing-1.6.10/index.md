---
title: Announcing Istio 1.6.10
linktitle: 1.6.10
subtitle: Patch Release
description: Istio 1.6.10 patch release.
publishdate: 2020-09-22
release: 1.6.10
aliases:
    - /news/announcing-1.6.10
    ---

    This release contains bug fixes to improve robustness. This release note describes
    what’s different between Istio 1.6.9 and Istio 1.6.10.

    {{< relnote >}}

    ## Changes

    - **Removed** deprecated help message for manifest migrate ([Istio #26230](https://github.com/istio/istio/issues/26230))
    - **Fixed** a bug that locality load balancer settings were applied inbound clusters unnecessarily ([Istio #27293](https://github.com/istio/istio/issues/27293))
    -  **Fixed** unbounded cardinality of Istio metrics for cron job workload ([Istio #24058](https://github.com/istio/istio/issues/24058))
    - **Improved** cache envoy readiness value
    - **Added** quotes in log sampling config and stackdriver test
    - **Fixed** gateways missing endpoint instances of headless service ([Istio #27041](https://github.com/istio/istio/issues/27041))
