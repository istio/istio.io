---
title: EnvoyFilterMayClearRouteCache
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `AuthorizationPolicy` 以 `HTTPRoute` 为目标，
同时有 `EnvoyFilter` 向网关或 waypoint 添加 HTTP 过滤器时，会出现此消息。

以 `HTTPRoute` 为目标的策略依赖于 Envoy 选择的路由。如果在策略之后运行的过滤器修改了请求并清除了路由缓存，
Envoy 可能会选择不同的路由。这样，请求可能会被发送到策略未检查过的目标。更多信息请参阅
[Envoy 安全注意事项](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_filters.html#security-considerations)。

分析器不会检查上下文为 `SIDECAR_INBOUND` 或 `SIDECAR_OUTBOUND` 的 `EnvoyFilter` 补丁。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Warning [IST0178] (EnvoyFilter istio-system/add-header) Using an EnvoyFilter with route-dependent filters may cause the routing cache to be cleared after the route-dependent filter has run. This can cause a request to be routed differently than it was when the route-dependent filter was evaluated. See https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_filters.html#security-considerations.
{{< /text >}}

## 如何修复 {#how-to-resolve}

确保 `EnvoyFilter` 添加的 HTTP 过滤器不会在授权过滤器运行之后更改请求的路由。
如果无法做到这一点，请不要将以 `HTTPRoute` 为目标的 `AuthorizationPolicy` 资源与此 `EnvoyFilter` 一起使用。
