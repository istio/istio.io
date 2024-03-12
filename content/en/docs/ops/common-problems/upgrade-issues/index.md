---
title: Upgrade Problems
description: Resolve common problems with Istio upgrades.
weight: 60
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## EnvoyFilter migration

`EnvoyFilter` is an alpha API that is tightly coupled to the implementation
details of Istio xDS configuration generation. Production use of the
`EnvoyFilter` alpha API must be carefully curated during the upgrade of Istio's
control or data plane. In many instances, `EnvoyFilter` can be replaced with a
first-class Istio API which carries substantially lower upgrade risks.

### Use Telemetry API for metrics customization

The usage of `IstioOperator` to customize Prometheus metrics generation has been
replaced by the [Telemetry API](/docs/tasks/observability/metrics/customize-metrics/),
because `IstioOperator` relies on a template `EnvoyFilter` to change the
metrics filter configuration. Note that the two methods are incompatible, and
the Telemetry API does not work with `EnvoyFilter` or `IstioOperator` metric
customization configuration.

As an example, the following `IstioOperator` configuration adds a `destination_port` tag:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            inboundSidecar:
              metrics:
                - name: requests_total
                  dimensions:
                    destination_port: string(destination.port)
{{< /text >}}

The following `Telemetry` configuration replaces the above:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: namespace-metrics
spec:
  metrics:
  - providers:
    - name: prometheus
    overrides:
    - match:
        metric: REQUEST_COUNT
      mode: SERVER
      tagOverrides:
        destination_port:
          value: "string(destination.port)"
{{< /text >}}

### Use the WasmPlugin API for Wasm data plane extensibility

The usage of `EnvoyFilter` to inject Wasm filters has been replaced by the
[WasmPlugin API](/docs/tasks/extensibility/wasm-module-distribution).
WasmPlugin API allows dynamic loading of the plugins from artifact registries,
URLs, or local files. The "Null" plugin runtime is no longer a recommended option
for deployment of Wasm code.

### Use gateway topology to set the number of the trusted hops

The usage of `EnvoyFilter` to configure the number of the trusted hops in the
HTTP connection manager has been replaced by the
[`gatewayTopology`](/docs/reference/config/istio.mesh.v1alpha1/#Topology)
field in
[`ProxyConfig`](/docs/ops/configuration/traffic-management/network-topologies).
For example, the following `EnvoyFilter` configuration should use an annotation
on the pod or the mesh default. Instead of:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: ingressgateway-redirect-config
spec:
  configPatches:
  - applyTo: NETWORK_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
    patch:
      operation: MERGE
      value:
        typed_config:
          '@type': type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          xff_num_trusted_hops: 1
  workloadSelector:
    labels:
      istio: ingress-gateway
{{< /text >}}

Use the equivalent ingress gateway pod proxy configuration annotation:

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": 1 }}'
{{< /text >}}

### Use gateway topology to enable PROXY protocol on the ingress gateways

The usage of `EnvoyFilter` to enable [PROXY
protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) on the
ingress gateways has been replaced by the
[`gatewayTopology`](/docs/reference/config/istio.mesh.v1alpha1/#Topology)
field in
[`ProxyConfig`](/docs/ops/configuration/traffic-management/network-topologies).
For example, the following `EnvoyFilter` configuration should use an annotation
on the pod or the mesh default. Instead of:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
spec:
  configPatches:
  - applyTo: LISTENER_FILTER
    patch:
      operation: INSERT_FIRST
      value:
        name: proxy_protocol
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.listener.proxy_protocol.v3.ProxyProtocol"
  workloadSelector:
    labels:
      istio: ingress-gateway
{{< /text >}}

Use the equivalent ingress gateway pod proxy configuration annotation:

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "proxyProtocol": {} }}'
{{< /text >}}

### Use a proxy annotation to customize the histogram bucket sizes

The usage of `EnvoyFilter` and the experimental bootstrap discovery service to
configure the bucket sizes for the histogram metrics has been replaced by the
proxy annotation `sidecar.istio.io/statsHistogramBuckets`. For example, the
following `EnvoyFilter` configuration should use an annotation on the pod.
Instead of:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: envoy-stats-1
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: BOOTSTRAP
    patch:
      operation: MERGE
      value:
        stats_config:
          histogram_bucket_settings:
            - match:
                prefix: istiocustom
              buckets: [1,5,50,500,5000,10000]
{{< /text >}}

Use the equivalent pod annotation:

{{< text yaml >}}
metadata:
  annotations:
    "sidecar.istio.io/statsHistogramBuckets": '{"istiocustom":[1,5,50,500,5000,10000]}'
{{< /text >}}
