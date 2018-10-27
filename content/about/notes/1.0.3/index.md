---
title: Istio 1.0.3
weight: 89
icon: notes
---

This release addresses some critical issues found by the community when using Istio 1.0.2. 
This release note describes what's different between Istio 1.0.2 and Istio 1.0.3.

{{< relnote_links >}}

## Behavior Changes

- [Validating Webhook](/help/ops/setup/validation) is now mandatory. Disabling it may result in Pilot crashes.

- [ServiceEntry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) does not allow wildcard (`*`) DNS resolution. The API has never allowed this, however `ServiceEntry` was erroneously excluded from validation in the previous release.

- Core dump path for `istio-proxy` has changed to `/var/lib/istio`.

## Networking

- `mTLS` Permissive mode is enabled by default.
 
- Major performance improvement in Pilot by incremental EDS.

- Default trace sampling is set to `1%`.

## Policy and Telemetry

- Mixer (`istio-telemetry`) supports load shedding based on request rate and expected latency.

- Mixer client (`istio-policy`) supports `FAIL_OPEN` setting.

- Istio Performance dashboard added to grafana.

- All `ValueTypes` supported by OOP adapters.

- Reduced `istio-telemetry` CPU by `10%`.

- Eliminated `stasd-to-prometheus` deployment. Prometheus directly scrapes from `istio-proxy`.
