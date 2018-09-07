---
title: Istio 1.0.2
weight: 90
icon: /img/notes.svg
---

This release addresses some critical issues found by the community when using Istio 1.0.1. This release note describes what's different between Istio 1.0.1 and
Istio 1.0.2.

{{< relnote_links >}}

## Miscellaneous

- Fixed bug in Envoy where the sidecar would crash if receiving normal traffic on the mutual TLS port.

- Fixed bug with Pilot propagating incomplete updates to Envoy in a multicluster environment.

- Added a few more Helm options for Grafana.

- Improved Kubernetes service registry queue performance.

- Fixed bug where `istioctl proxy-status` was not showing the patch version.

- Add validation of virtual service SNI hosts.
