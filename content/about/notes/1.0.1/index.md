---
title: Istio 1.0.1
weight: 91
icon: /img/notes.svg
---

Within this release, we have been addressing some critical issues found by the community when using Istio 1.0.

This release note describes what's different between Istio 1.0 and Istio 1.0.1.

## Networking

- Pilot scalability and Envoy sidecar startup improvement.
- Fixed virtual service host mismatch issue when port is added.
- Added limited support for [merging multiple virtual service or destination rule definitions](/help/ops/traffic-management/deploy-guidelines/#multiple-virtual-services-and-destination-rules-for-the-same-host) for the same host.
- Allow [outlier](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/cluster_outlier_detection.html) consecutive gateway failures when using HTTP.

## Environment

- Ability to run Pilot only for users who wants to leverage traffic management feature of Istio.
- Convenient values-istio-gateway.yaml for users to run standalone gateways.
- Various fixes for our helm based installation, including a prior issue with istio-sidecar-injector configmap not found.
- Fixed the Istio installation error with endpoint galley not ready.
- Various mesh expansion fixes.

## Policy and Telemetry

- Added an experimental metrics expiration configuration to the Mixer Prometheus adapter.
- Updated Grafana to 5.2.2.

### Adapters

- Ability to specify sink options for the Stackdriver adapter.

## Galley

- Configuration  validation improvement for health checks.
