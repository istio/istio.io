---
title: 升级问题
description: 解决 Istio 升级遇到的常见问题。
weight: 60
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## EnvoyFilter 迁移 {#envoyfilter-migration}

`EnvoyFilter` 是一个与 Istio xDS 配置生成的实现细节紧密耦合的 Alpha API。
在升级 Istio 的控制面或数据面时，必须谨慎使用 `EnvoyFilter` Alpha API。
在许多情况下，您可以使用升级风险低的标准 Istio API 替换 `EnvoyFilter`。

### 使用 Telemetry API 自定义指标 {#use-telemetry-api-for-metrics- customization}

因为 `IstioOperator` 依赖于模板 `EnvoyFilter` 来更改指标过滤器配置，
所以使用 `IstioOperator` 自定义 Prometheus 指标生成的方式已经替换为
[Telemetry API](/zh/docs/tasks/observability/metrics/customize-metrics/)。
请注意，这两种方式互不兼容，Telemetry API 无法与 `EnvoyFilter` 或 `IstioOperator` 指标自定义配置一起使用。

例如，以下 `IstioOperator` 配置添加了一个 `destination_port` 标记：

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

以下 `Telemetry` 配置替换上述配置：

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

### 使用 WasmPlugin API 扩展 Wasm 数据面 {#use-wasmplugin-api-for-wasm-extensibility}

使用 `EnvoyFilter` 注入 Wasm 过滤器的做法已替换为
[WasmPlugin API](/zh/docs/tasks/extensibility/wasm-module-distribution)。
这是因为 WasmPlugin API 允许从镜像仓库、URL 或本地文件动态加载插件。
对于部署 Wasm 代码而言，“Null” 插件运行时不再是推荐的选项。

### 使用网关拓扑设置可信跳数 {#use-gateway-topology-to-set-the-number-of-trusted-hops}

使用 `EnvoyFilter` 在 HTTP 连接管理器中配置可信跳数的方式已替换为
[`ProxyConfig`](/zh/docs/ops/configuration/traffic-management/network-topologies)
中的 [`gatewayTopology`](/zh/docs/reference/config/istio.mesh.v1alpha1/#Topology)
字段。例如，以下 `EnvoyFilter` 配置应默认在 Pod 或网关上使用注解来替换：

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

使用等效的入口网关 Pod 代理配置注解：

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": 1 }}'
{{< /text >}}

### 使用网关拓扑在入口网关上启用 PROXY 协议 {#use-gateway-topology-to-enable-proxy-protocol}

使用 `EnvoyFilter` 在入口网关上启用
[PROXY 协议](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt)
已替换为 [`ProxyConfig`](/zh/docs/ops/configuration/traffic-management/network-topologies)
中的 [`gatewayTopology`](/zh/docs/reference/config/istio.mesh.v1alpha1/#Topology)
字段。例如，以下 `EnvoyFilter` 配置应默认在 Pod 或网格上使用注解来替换：

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

使用等效的入口网关 Pod 代理配置注解：

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "proxyProtocol": {} }}'
{{< /text >}}

### 使用代理注解自定义直方图桶大小 {#use-proxy-annotation-to-customize-buckets}

使用 `EnvoyFilter` 和实验性引导发现服务来配置直方图指标桶大小的方式已替换为代理注解
`sidecar.istio.io/statsHistogramBuckets`。例如，以下 `EnvoyFilter` 配置应在 Pod 上使用注解来替换：

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

使用等效的 Pod 注解：

{{< text yaml >}}
metadata:
  annotations:
    "sidecar.istio.io/statsHistogramBuckets": '{"istiocustom":[1,5,50,500,5000,10000]}'
{{< /text >}}
