---
title: Upgrade Problems
description: Resolve common problems with Istio upgrades
weight: 40
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## EnvoyFilter migration

`EnvoyFilter` is an alpha API that is tightly coupled to the implementation
details of Istio xDS configuration generation. Production use of the alpha API
must be carefully curated during the upgrade of Istio's control or data plane.
In many instances, `EnvoyFilter` can be replaced with a first-class Istio API
which carry substantially lower upgrade risks.

### Use Telemetry API for metrics customization

The usage of `IstioOperator` to customize Prometheus metrics generation has been
replaced by [Telemetry API](/docs/tasks/observability/metrics/customize-metrics/),
because `IstioOperator` relies on a template `EnvoyFilter` to change the
metrics filter configuration.

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

Prefer the following `Telemetry` configuration instead:

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

### Use WasmPlugin API for Wasm data plane extensibility

The usage of `EnvoyFilter` to inject Wasm filters has been replaced by
[WasmPlugin API](/docs/tasks/extensibility/wasm-module-distribution). Wasm API
allows dynamic loading of the plugins from artifact registries, URLs, or local
files. "Null" plugin runtime is no longer a recommended option for deployment
of Wasm code.

### Use `gatewayTopology` to set the number of the trusted hops

The usage of `EnvoyFilter` to configure the number of the trusted hops in the
HTTP connection manager has been replaced by `gatewayTopology` field in
[ProxyConfig](/docs/reference/config/networking/proxy-config/). For example,
the following `EnvoyFilter` configuration should use an annotation on the pod
or the mesh default instead:

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

The equivalent ingress gateway proxy configuration annotation is the following:

{{< text yaml >}}
  metadata:
    annotations:
      "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": 1 }'
{{< /text >}}
