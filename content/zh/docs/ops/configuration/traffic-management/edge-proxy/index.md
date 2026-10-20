---
title: 边缘代理配置
description: 为入口网关配置 Envoy 边缘代理最佳实践默认值。
weight: 65
keywords: [traffic-management,ingress,gateway,edge,security,hardening]
owner: istio/wg-networking-maintainers
test: n/a
---

当 Istio 网关作为边缘代理部署、直接暴露给不受信任的客户端流量时，
Envoy 针对缓冲区限制、超时、HTTP/2 调优、标头清理和连接限制
[推荐了特定的设置](https://www.envoyproxy.io/docs/envoy/latest/configuration/best_practices/edge)。

借助 Istio 的 `ProxyConfig.ConnectionSettings` API，您可以通过 `EDGE`
配置文件一次性应用这些建议，也可以为任意代理单独配置各项设置。

有关完整的字段参考，请参阅
[`ProxyConfig.ConnectionSettings`](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig-ConnectionSettings)。

## 应用 `EDGE` 配置文件 {#applying-the-edge-profile}

在 `connectionSettings` 中设置 `profile: EDGE`，即可将 Envoy
推荐的边缘代理默认值应用到网关。该配置文件既可以通过 `MeshConfig`
全局设置，也可以使用 Pod 注解针对单个网关设置。

### 全局配置 {#global-configuration}

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
{{< /text >}}

### 针对单个网关的注解 {#per-gateway-annotation}

{{< text syntax=yaml snip_id=none >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"connectionSettings": {"profile": "EDGE"}}'
{{< /text >}}

### `EDGE` 配置文件默认值 {#edge-profile-defaults}

`EDGE` 配置文件会应用以下默认值。显式设置的任何字段始终优先于配置文件默认值。

| 设置 | 默认值 |
|---------|---------------|
| `listenerPerConnectionBufferLimitBytes` | `32768 (32 KiB)` |
| `clusterPerConnectionBufferLimitBytes` | `32768 (32 KiB)` |
| `httpIdleTimeout` | `3600s`（1 小时） |
| `httpRequestTimeout` | `300s`（5 分钟） |
| `httpStreamIdleTimeout` | `300s`（5 分钟） |
| `httpMaxConcurrentStreams` | 100 |
| `http2InitialStreamWindowSize` | `65536 (64 KiB)` |
| `http2InitialConnectionWindowSize` | 1048576 (1 MiB) |
| `httpRequestHeadersTimeout` | `60s`（1 分钟） |
| `httpHeadersWithUnderscoresAction` | `REJECT_REQUEST` |
| `httpMergeSlashes` | true |
| `httpPathWithEscapedSlashesAction` | `UNESCAPE_AND_REDIRECT` |

{{< tip >}}
即使通过 `MeshConfig` 全局应用该设置，`EDGE` 配置文件的默认值也仅适用于网关（Router）代理。
不过，显式设置的 `connectionSettings` 字段（不依赖配置文件默认值）适用于所有类型的代理，
包括 Sidecar。
{{< /tip >}}

## 覆盖配置文件默认值 {#overriding-profile-defaults}

您可以在设置 `profile: EDGE` 的同时覆盖特定设置。例如，要提高最大并发流数量的限制：

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
        httpMaxConcurrentStreams: 200
{{< /text >}}

或者通过 Pod 注解进行设置：

{{< text syntax=yaml snip_id=none >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"connectionSettings": {"profile": "EDGE", "httpMaxConcurrentStreams": 200}}'
{{< /text >}}

## 不使用配置文件单独配置各项设置 {#configuring-individual-settings-without-a-profile}

您可以在不使用配置文件的情况下单独设置各个 `connectionSettings` 字段。
如果您只需要对连接进行特定调优，而不需要整套边缘默认值，这种方式会很有用。

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        httpIdleTimeout: 600s
        httpMaxConcurrentStreams: 50
{{< /text >}}

未设置配置文件时，不会应用任何额外的默认值，只有显式设置的字段才会生效。

## 全局下游连接数限制 {#global-downstream-connection-limit}

`globalDownstreamConnectionLimit` 字段用于配置代理可接受的最大下游连接数。
该字段通过 Bootstrap 配置中的 Envoy 过载管理器实现。

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      connectionSettings:
        profile: EDGE
        globalDownstreamConnectionLimit: 10000
{{< /text >}}

此字段的优先级高于代理元数据 `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS` 的值，
而后者的优先级又高于已弃用的运行时标志 `overload.global_downstream_max_connections`。

## 与其他 API 的关系 {#relationship-with-other-apis}

**DestinationRule**：`ConnectionSettings` 配置的是代理的下游侧（侦听器和 HTTP 连接管理器），
而 DestinationRule 的 `connectionPoolSettings` 配置的是上游集群侧。
两者在不同的跃点上独立生效，互不覆盖。

**路径规范化**：设置 `ConnectionSettings` 中的 `httpMergeSlashes` 和
`httpPathWithEscapedSlashesAction` 字段后，这些字段的优先级高于 `MeshConfig`
中等效的 `pathNormalization` 设置。有关如何选择路径规范化选项的指导，
请参阅[安全最佳实践](/zh/docs/ops/best-practices/security/#understand-path-normalization-in-authorization-policy)。
