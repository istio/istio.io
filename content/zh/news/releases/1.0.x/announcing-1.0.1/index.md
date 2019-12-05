---
title: Announcing Istio 1.0.1
linktitle: 1.0.1
subtitle: Patch Release
description: Istio 1.0.1 patch release.
publishdate: 2018-08-29
release: 1.0.1
aliases:
    - /zh/about/notes/1.0.1
    - /zh/blog/2018/announcing-1.0.1
    - /zh/news/2019/announcing-1.0.1
    - /zh/news/announcing-1.0.1
---

We're pleased to announce the availability of Istio 1.0.1. Please see below for what's changed.

{{< relnote >}}

## Networking

- Improved Pilot scalability and Envoy startup time.

- Fixed virtual service host mismatch issue when adding a port.

- Added limited support for [merging multiple virtual service or destination rule definitions](/zh/docs/ops/traffic-management/deploy-guidelines/#multiple-virtual-services-and-destination-rules-for-the-same-host) for the same host.

- Allow [outlier](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/cluster/outlier_detection.proto) consecutive gateway failures when using HTTP.

## Environment

- Made it possible to use Pilot standalone, for those users who want to only leverage Istio's traffic management functionality.

- Introduced the convenient `values-istio-gateway.yaml` configuration that enables users to run standalone gateways.

- Fixed a variety of Helm installation issues, including an issue with the `istio-sidecar-injector` configmap not being found.

- Fixed the Istio installation error with Galley not being ready.

- Fixed a variety of issues around mesh expansion.

## Policy and telemetry

- Added an experimental metrics expiration configuration to the Mixer Prometheus adapter.

- Updated Grafana to 5.2.2.

### Adapters

- Ability to specify sink options for the Stackdriver adapter.

## Galley

- Improved configuration validation for health checks.
