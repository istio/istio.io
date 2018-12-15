---
title: Istio 1.0.3
weight: 89
icon: notes
---

This release addresses some critical issues found by the community when using Istio 1.0.2.
This release note describes what's different between Istio 1.0.2 and Istio 1.0.3.

{{< relnote_links >}}

## Behavior changes

- [Validating webhook](/help/ops/setup/validation) is now mandatory. Disabling it may result in Pilot crashes.

- [Service entry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) validation now rejects the wildcard hostname (`*`) when configuring DNS resolution. The API has never allowed this, however `ServiceEntry` was erroneously excluded from validation in the previous release. Use of wildcards as part of a hostname, e.g. `*.bar.com`, remains unchanged.

- The core dump path for `istio-proxy` has changed to `/var/lib/istio`.

## Networking

- [Mutual TLS](/docs/tasks/security/mutual-tls) Permissive mode is enabled by default.

- Pilot performance and scalability has been greatly enhanced. Pilot now delivers endpoint updates to 500 sidecars in under 1 second.

- Default [trace sampling](/docs/tasks/telemetry/distributed-tracing/overview/#trace-sampling) is set to 1%.

## Policy and telemetry

- Mixer (`istio-telemetry`) now supports load shedding based on request rate and expected latency.

- Mixer client (`istio-policy`) now supports `FAIL_OPEN` setting.

- Istio Performance dashboard added to Grafana.

- Reduced `istio-telemetry` CPU usage by 10%.

- Eliminated `statsd-to-prometheus` deployment. Prometheus now directly scrapes from `istio-proxy`.
