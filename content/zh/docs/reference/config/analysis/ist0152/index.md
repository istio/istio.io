---
title: EnvoyFilterUsesReplaceOperationIncorrectly
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `EnvoyFilter` 使用 `REPLACE` 操作并且 `ApplyTo` 设置为 `HTTP_FILTER` 或 `NETWORK_FILTER` 时，
会出现此消息。这将导致 `REPLACE` 操作被忽略，因为 `HTTP_FILTER` 和 `NETWORK_FILTER` 对于 `REPLACE` 无效。

## 示例 {#example}

以一个带有 `REPLACE` 补丁操作的 `EnvoyFilter` 为例，这个 `EnvoyFilter` 将被忽略：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-replace-2
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      app: reviews2
  priority: 10
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
      operation: REPLACE
      value: # Lua filter specification
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
