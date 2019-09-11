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

To enable the generation of service-level metrics in Envoy, execute the following steps:

1. Disable calls to `istio-telemetry` in the mesh

    In order to prevent duplicate telemetry generation, turn off the use of the `istio-telemetry` service
    for telemetry generation.

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system --set mixer.telemetry.enabled=false --set mixer.policy.enabled=false
    {{< /text >}}

    Alternatively, comment out `mixerCheckServer` and `mixerReportServer` from the mesh config
    (the `istio` config map).

1. Enable the metadata exchange filter

    For the generation of service-level metrics, proxies must exchange workload metadata. This exchange
    is handled by a custom filter.

    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/master/extensions/stats/testdata/istio/metadata-exchange_filter.yaml
    {{< /text >}}

1. Enable the custom stats filter

    A custom filter must also be applied to actually generate the service-level metrics.

    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/master/extensions/stats/testdata/istio/stats_filter.yaml
    {{< /text >}}

1. See the results

    Visit Grafana "Istio Mesh" dashboard. It will display the same telemetry as before -- without
    any requests flowing through Istio's Mixer.

## Differences with Mixer-based generation

There are some small differences between the in-proxy generation of the service-level metrics and
the Mixer-based generation in the 1.3.0 release. Full feature-parity is a requirement before this
functionality can be considered stable.

In the meantime, please be aware of these differences:

1. The latency metric uses a new name and is recorded in different units. The new metric is called
   `istio_request_duration_milliseconds` (instead of `istio_request_duration_seconds`). The Grafana
   dashboards are updated to account for the new metric.
1. The `istio_request_duration_milliseconds` metric uses more granular buckets inside the proxy.
   This results in lower latency measurements in the histograms than before.

## Performance impact

{{< warning >}}

The focus of the initial release of this functionality has not been on performance optimization.
We have several planned performance-related improvements in the pipeline at this time.

This feature will not be considered for promotion to Beta or Stable status until our performance
goals have been realized.

{{< /warning >}}

1. The `istio-telemetry` deployment can be switched off. This should save ~0.5 vCPU per 1000 rps
   of mesh traffic. This also halves the CPU consumed by Istio while collecting Istio standard
   metrics.
1. The new filters together use 10% less CPU for `istio-proxy` containers than the Mixer filter.
1. The new filters add ~5ms P90 latency (1000 rps) as compared to a generic Envoy in the current
   implementation.

## Known limitations in 1.3

1. Only Prometheus export of these metrics is supported.
1. No support for TCP metrics generation is provided.
1. No proxy-side customization or configuration of the generated metrics is provided.

## Implementation Details

The implementation in Istio 1.3 uses the `WASM` sandbox API, but it doesn't run inside a `WASM VM`.
The implementation is natively-compiled in Envoy using `NullVM`. We are working to enable running
filters in the `V8 WASM VM` in future releases.

Currently you configure the filters using the Istio Envoy filter API. One of our goals for Istio 1.4 is to
we will introduce new ways of configuring extensions.
