---
title: EnvoyFilterUsesRelativeOperation
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `EnvoyFilter` 没有优先级且使用相对补丁操作（`INVALID`、`MERGE`、`REMOVE`、`INSERT_BEFORE`、`INSERT_AFTER`、`REPLACE`）时，
会出现此消息。使用相对补丁操作意味着当评估当前的 `EnvoyFilter` 过滤器时该操作依赖于另一个过滤器。
为了确保按照用户想要的顺序应用 `EnvoyFilters`，应该赋予一个优先级或者应该使用一个非相对操作（`ADD` 或 `INSERT_FIRST`）。

## 示例 {#example}

以一个带有 `INSERT_BEFORE` 补丁操作的 `EnvoyFilter` 为例：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-relative
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      app: reviews2
  configPatches:
    # 第一个补丁将 Lua 过滤器添加到 listener/http 连接管理器
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        portNumber: 8080
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
            subFilter:
              name: "envoy.filters.http.router"
    patch:
      operation: INSERT_BEFORE
      value: # Lua 过滤器规范
       name: envoy.lua
       typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
          inlineCode: |
            function envoy_on_request(request_handle)
              -- Make an HTTP call to an upstream host with the following headers, body, and timeout.
              local headers, body = request_handle:httpCall(
               "lua_cluster",
               {
                [":method"] = "POST",
                [":path"] = "/acl",
                [":authority"] = "internal.org.net"
               },
              "authorize call",
              5000)
            end
{{< /text >}}

## 如何修复 {#how-to-resolve}

由于原来使用了 `INSERT_BEFORE` 的相对操作，所以现在将其更改为 `INSERT_FIRST` 的绝对操作将解决这个问题：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-relative
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      app: reviews2
  configPatches:
    # 第一个补丁将 Lua 过滤器添加到 listener/http 连接管理器
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        portNumber: 8080
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
            subFilter:
              name: "envoy.filters.http.router"
    patch:
      operation: INSERT_FIRST
      value: # Lua 过滤器规范
       name: envoy.lua
       typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
          inlineCode: |
            function envoy_on_request(request_handle)
              -- Make an HTTP call to an upstream host with the following headers, body, and timeout.
              local headers, body = request_handle:httpCall(
               "lua_cluster",
               {
                [":method"] = "POST",
                [":path"] = "/acl",
                [":authority"] = "internal.org.net"
               },
              "authorize call",
              5000)
            end
{{< /text >}}
