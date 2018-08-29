---
title: Istio 1.0.1
weight: 91
icon: /img/notes.svg
---

This release addresses some critical issues found by the community when using Istio 1.0. This release note describes what's different between Istio 1.0 and Istio 1.0.1.

{{< relnote_links >}}

## Networking

- Improved Pilot scalability and Envoy startup time.

- Fixed virtual service host mismatch issue when adding a port.

- Added limited support for [merging multiple virtual service or destination rule definitions](/help/ops/traffic-management/deploy-guidelines/#multiple-virtual-services-and-destination-rules-for-the-same-host) for the same host.

- Allow [outlier](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/cluster_outlier_detection.html) consecutive gateway failures when using HTTP.

## Environment

- Made it possible to use Pilot standalone, for those users who want to only leverage Istio's traffic management functionality.

- Introduced the convenient `values-istio-gateway.yaml` configuration that enables users to run standalone gateways.

- Fixed a variety of Helm installation issues, including an issue with the `istio-sidecar-injector` configmap not being found.

- Fixed the Istio installation error with Galley not being ready.

- Fixed a variety of issues around mesh expansion.

## Policy and Telemetry

- Added an experimental metrics expiration configuration to the Mixer Prometheus adapter.

- Updated Grafana to 5.2.2.

### Adapters

- Ability to specify sink options for the Stackdriver adapter.

## Galley

- Improved configuration validation for health checks.
