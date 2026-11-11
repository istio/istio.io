---
title: 升级说明
description: 升级到 Istio 1.32.0 时要考虑的重要变更。
weight: 20
---

当您从 Istio 1.31.0 升级到 Istio 1.32.0 时，需要注意此页面上的变更。
这些说明详细说明了有意破坏与 Istio 1.31.x 向后兼容性的变更。
此外，这些说明还提及了在保持向后兼容性的同时引入新行为的变更。
只有当新行为对 Istio 1.31.x 用户而言是意料之外的，才会包含这些变更。

## 按名称匹配网关 RBAC 过滤器的 EnvoyFilter 补丁 {#envoyfilter-patches-matching-the-gateway-rbac-filter-by-name}

当 `ENABLE_GATEWAY_API_HTTPROUTE_AUTH=true` 时，入口网关上 `ALLOW` 操作的 HTTP 过滤器
会以 `istio.authorization.allow` 而不是 `envoy.filters.http.rbac` 的名称生成。
需要使用不同的名称，以便路由作用域的配置可以单独指向 `ALLOW` 过滤器，
而不会同时影响仍使用 `envoy.filters.http.rbac` 名称的 `DENY` 和 `AUDIT` 过滤器。

这会影响任何按名称匹配 RBAC 过滤器的 `EnvoyFilter`，例如：

{{< text yaml >}}
match:
  context: GATEWAY
  listener:
    filterChain:
      filter:
        name: envoy.filters.http.http_connection_manager
        subFilter:
          name: envoy.filters.http.rbac
{{< /text >}}

此类补丁将不再匹配 `ALLOW` 过滤器。`MERGE`、`REPLACE` 和 `REMOVE` 操作会静默地不再应用于该过滤器，
而 `INSERT_BEFORE` 和 `INSERT_AFTER` 会将所提供的过滤器从过滤器链中完全丢弃，而不是回退到其他位置。
如果 `Gateway` 资源的授权策略仅使用 `ALLOW` 操作，则根本不存在名为 `envoy.filters.http.rbac` 的过滤器。

除非在 `istiod` 上设置了 `PILOT_ENVOY_FILTER_STATS=true`（这会公开 `pilot_envoy_filter_status` 指标），
否则补丁匹配失败时不会发出任何警告。

如果您依赖此类补丁，请添加第二个匹配 `istio.authorization.allow` 的 `EnvoyFilter`，
或者保持 `ENABLE_GATEWAY_API_HTTPROUTE_AUTH` 处于禁用状态。
Envoy 统计信息不受影响，因为 RBAC 过滤器指标派生自连接管理器的统计前缀，而不是过滤器名称。

## Kubernetes API 请求现在具有客户端超时 {#kubernetes-api-requests-now-have-client-side-timeouts}

默认值适用于大多数集群。如果环境中的 API 服务器较慢或负载较重，
可以在受影响的组件上通过以下环境变量调高这些值，
或者将其中任意一个设置为 `0` 以恢复以前不受限制的行为。

| 变量 | 默认值 | 适用范围 |
| --- | --- | --- |
| `ISTIO_KUBE_HEADER_TIMEOUT` | `90s` | 任何请求等待其响应标头的最长时间。该值必须始终大于 API 服务器的 `--request-timeout`（默认为 `60s`）。 |
| `ISTIO_KUBE_REQUEST_TIMEOUT` | `15m` | 未设置自身截止时间的请求的总时长，包括读取响应的时间。 |

Exec、attach 和 port-forward 会话不受影响。发生超时时会使 `kube_client_deadline_fired_total` 递增，
并记录一条包含方法和路径的警告。

## 来自 Pod 和 WorkloadEntry 资源的不健康端点 {#unhealthy-endpoints-from-pods-and-workloadentry-resources}

在启用 `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS`（默认启用）时，由 `ServiceEntry` 资源选中的未就绪 Pod，
以及经过健康检查且不健康的 `WorkloadEntry` 资源，现在可能会以不健康状态出现在端点发现响应中。
