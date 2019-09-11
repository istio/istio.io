---
title: Generate Istio Metrics Without Mixer
description: In-proxy generation of service-level metrics.
weight: 70
---

{{< warning >}}

This document describes **Alpha** quality features. They have been exposed *only* to enable further testing
and evaluation across the community.

The functionality described here is NOT considered stable. No performance or stability guarantees are provided
at this time.

{{< /warning>}}

Istio 1.3 adds experimental support to generate service-level HTTP metrics
directly in the Envoy proxies. This feature lets you continue to monitor your service meshes using the tools Istio provides
without needing Mixer. This support is the first step towards the new
extensibility architecture for Istio. This architecture puts Mixer-like functionality directly in the Envoy proxies.

The in-proxy generation of service-level metrics replaces the following HTTP metrics that Mixer currently
generates:

- `istio_requests_total`
- `istio_request_duration_*`
- `istio_request_size`

## Enable Service-level Metrics Generation in Envoy

To generate service-level metrics directly in the Envoy proxies, follow these steps:

1.  To prevent duplicate telemetry generation, turn off the `istio-telemetry` service to disable calls to `istio-telemetry` in the mesh:


    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system --set mixer.telemetry.enabled=false --set mixer.policy.enabled=false
    {{< /text >}}

        {{< tip >}}
        Alternatively, you can comment out `mixerCheckServer` and `mixerReportServer` in your mesh's configuration file.
        {{< /tip >}}

1. To generate service-level metrics, the proxies must exchange {{< gloss >}}workload{{< /gloss >}} metadata. 
   A custom filter handles this exchange. Enable the metadata exchange filter with the following command:


    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/master/extensions/stats/testdata/istio/metadata-exchange_filter.yaml
    {{< /text >}}

1. To actually generate the service-level metrics, you must apply the custom stats filter:

    A custom filter must also be applied to actually generate the service-level metrics.

    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/master/extensions/stats/testdata/istio/stats_filter.yaml
    {{< /text >}}

1. Go to the **Istio Mesh** dashboard Grafana. Verify that the dashboard displays the same telemetry as before but without
    any requests flowing through Istio's Mixer.


## Differences with Mixer-based generation

Small differences between the in-proxy generation and Mixer-based generation of service-level metrics
persist in Istio 1.3. We won't consider the functionality stable until in-proxy generation has full feature-parity with
Mixer-based generation.

Until then, please consider these differences:

- The `istio_request_duration_seconds` latency metric has the new name: `istio_request_duration_milliseconds`. 
  The new metric uses milliseconds instead of seconds. We updated the Grafana dashboards to
  account for these changes.
- The `istio_request_duration_milliseconds` metric uses more granular buckets inside the proxy.
 This change leads to lower latency measurements in the histograms than previously observed.

## Performance impact

{{< warning >}}

This release doesn't focus on performance optimization for this functionality.
We are working on several performance-related improvements for this experimental feature.

We won't consider this feature for promotion to **Beta** or **Stable** [status](/about/feature-stages/#feature-phase-definitions)
until we realize our performance goals.

The performance of your mesh depends on your configuration. To learn more, see our [performance best practices post](/blog/2019/performance-best-practices/).

{{< /warning >}}

1. The `istio-telemetry` deployment can be switched off. This should save ~0.5 vCPU per 1000 rps
   of mesh traffic. This also halves the CPU consumed by Istio while collecting Istio standard
   metrics.
- All new filters together use 10% less CPU resources for the `istio-proxy` containers than the Mixer filter.
1. The new filters add ~5ms P90 latency (1000 rps) as compared to a generic Envoy in the current
   implementation.

## Known limitations in 1.3

- You can only export these metrics to Prometheus.
- We provide no support to generate TCP metrics.
- We provide no proxy-side customization or configuration of the generated metrics.

## Implementation details

The implementation in Istio 1.3 uses the `WASM` sandbox API, but it doesn't run inside a `WASM VM`.
The implementation is natively-compiled in Envoy using `NullVM`. We are working to enable running
filters in the `V8 WASM VM` in future releases.

Currently you configure the filters using the Istio Envoy filter API. One of our goals for Istio 1.4 is to
we will introduce new ways of configuring extensions.
