---
title: Generate Istio Metrics Without Mixer [Alpha]
description: How to enable in-proxy generation of HTTP service-level metrics.
weight: 20
aliases:
  - /docs/ops/telemetry/in-proxy-service-telemetry
---

Istio 1.4 adds alpha support to generate service-level HTTP metrics
directly in the Envoy proxies. This feature lets you continue to monitor your
service meshes using the tools Istio provides without needing Mixer.

The in-proxy generation of service-level metrics replaces the following HTTP
metrics that Mixer currently generates:

- `istio_requests_total`
- `istio_request_duration_seconds`
- `istio_request_size`

## Enable service-level metrics generation in Envoy

To generate service-level metrics directly in the Envoy proxies, follow these steps:

Option 1:

    {{< text bash >}}
    $ istioctl manifest apply --set values.telemetry.enabled=true,values.telemetry.v2.enabled=true
    {{< /text >}}

Option 2:

Follow these steps manually:

1. To disable Mixer http reporting, set `disableMixerHttpReports` to true in your mesh configuration

    Check the existing status:

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o jsonpath="{@.data.mesh}" | grep disableMixerHttpReports
    disableMixerHttpReports: true
    {{< /text >}}

    If disableMixerHttpReports is set to false, update your mesh configuration:

    {{< text bash >}}
    $ kubectl -n istio-system get cm istio -o yaml | sed -e 's/disableMixerHttpReports: false/disableMixerHttpReports: true/g' | kubectl replace -f -
    {{< /text >}}

1. To generate service-level metrics, the proxies must exchange {{< gloss >}}workload{{< /gloss >}} metadata.
   A custom filter handles this exchange. Enable the metadata exchange filter with the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f @tests/integration/telemetry/stats/prometheus/testdata/metadata_exchange_filter.yaml@
    {{< /text >}}

1. To actually generate the service-level metrics, you must apply the custom stats filter.

    {{< text bash >}}
    $ kubectl -n istio-system apply -f @tests/integration/telemetry/stats/prometheus/testdata/stats_filter.yaml@
    {{< /text >}}

Go to the **Istio Mesh** Grafana dashboard. Verify that the dashboard displays the same telemetry as before but without
    any requests flowing through Istio's Mixer.

## Differences with Mixer-based generation

Small differences between the in-proxy generation and Mixer-based generation of service-level metrics
persist in Istio 1.3. We won't consider the functionality stable until in-proxy generation has full feature-parity with
Mixer-based generation.

Until then, please consider these differences:

- The `istio_request_duration_seconds` latency metric has the new name: `istio_request_duration_milliseconds`.
  The new metric uses milliseconds instead of seconds. We updated the Grafana dashboards to
  account for these changes.
- The `istio_request_duration_milliseconds` metric uses more granular buckets inside the proxy, providing
  increased accuracy in latency reporting.

## Performance impact

{{< warning >}}

As this work is currently experimental, our primary focus has been on establishing
the base functionality. We have identified several performance optimizations based
on our initial experimentation, and expect to continue to improve the performance
and scalability of this feature as it develops.

We won't consider this feature for promotion to **Beta** or **Stable** [status](/about/feature-stages/#feature-phase-definitions)
until performance and scalability assessments and improvements have been made.

The performance of your mesh depends on your configuration.
To learn more, see our [performance best practices post](/blog/2019/performance-best-practices/).

{{< /warning >}}

Here's what we've measured so far:

- All new filters together use 10% less CPU resources for the `istio-proxy` containers
  than the Mixer filter.
- The new filters add ~5ms P90 latency at 1000 rps compared to Envoy proxies
  configured with no telemetry filters.
- If you only use the `istio-telemetry` service to generate service-level metrics,
  you can switch off the `istio-telemetry` service. This could save up to ~0.5 vCPU per
  1000 rps of mesh traffic, and could halve the CPU consumed by Istio while collecting
  [standard metrics](/docs/reference/config/policy-and-telemetry/metrics/).

## Known limitations

- We only provide support for exporting these metrics via Prometheus.
- We provide no support to generate TCP metrics.
- We provide no proxy-side customization or configuration of the generated metrics.
