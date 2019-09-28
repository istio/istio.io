---
title: Generate Istio Metrics Without Mixer [Experimental]
description: How to enable in-proxy generation of HTTP service-level metrics.
weight: 70
---

{{< boilerplate experimental-feature-warning >}}

Istio 1.3 adds experimental support to generate service-level HTTP metrics
directly in the Envoy proxies. This feature lets you continue to monitor your
service meshes using the tools Istio provides without needing Mixer.

The in-proxy generation of service-level metrics replaces the following HTTP
metrics that Mixer currently generates:

- `istio_requests_total`
- `istio_request_duration_seconds`
- `istio_request_size`

## Enable service-level metrics generation in Envoy

To generate service-level metrics directly in the Envoy proxies, follow these steps:

1.  To prevent duplicate telemetry generation, disable calls to `istio-telemetry` in the mesh:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system --set mixer.telemetry.enabled=false --set mixer.policy.enabled=false
    {{< /text >}}

    {{< tip >}}
    Alternatively, you can comment out `mixerCheckServer` and `mixerReportServer` in your [mesh configuration](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig).
    {{< /tip >}}

1. To generate service-level metrics, the proxies must exchange {{< gloss >}}workload{{< /gloss >}} metadata.
   A custom filter handles this exchange. Enable the metadata exchange filter with the following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/master/extensions/stats/testdata/istio/metadata-exchange_filter.yaml
    {{< /text >}}

    {{< tip >}}
    Alternatively, if you have Istio 1.3.x, you can enable metadata exchange filter with WebAssembly sandbox using the
    following command:

    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/release-1.3/extensions/stats/testdata/istio/metadata-exchange_with_wasm_filter.yaml
    {{< /text >}}

    {{< /tip >}}

1. To actually generate the service-level metrics, you must apply the custom stats filter.

    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/master/extensions/stats/testdata/istio/stats_filter.yaml
    {{< /text >}}

1. Go to the **Istio Mesh** Grafana dashboard. Verify that the dashboard displays the same telemetry as before but without
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
