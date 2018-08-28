---
title: Istio 1.0.1
weight: 91
icon: /img/notes.svg
---

We're proud to release Istio 1.0.1! Within this release, we have been addressing some critical issues found by the community when using Istio 1.0.

These release notes describe what's different between Istio 1.0 and Istio 1.0.1.

## Networking

- Pilot scability and Envoy sidecar startup improvement.
- Fixed virtual service host mismatch issue when port is added.
- Added limited support for [merging multiple virtual service or destination rule definitions](/help/ops/traffic-management/deploy-guidelines/#multiple-virtual-services-and-destination-rules-for-the-same-host) for the same host.
- Allow outliner ConsecutiveErrors for Gateway resources when using HTTP.

## Environment

- Ability to run Pilot only for users who wants to leverage traffic management feature of Istio. 
- Convenient values-istio-gateway.yaml for users to run standalone gateways.
- Various fixes for our helm based installation, including a prior issue with istio-sidecar-injector configmap not found.
- Fixed the Istio installation error with endpoint galley not ready.
- Various mesh expansion fixes.

## Policy and Telemtry

- Added an experimental metrics expiration configuration to the Mixer prometheus adapter.
- Updated Grafana to 5.2.2.

### Adapters

- Ability to specify sinkoptions for the stackdriver adapter.

## Galley

- Config validation improvement for healthchecks.
