---
title: EnvoyFilterUsesRelativeOperationWithProxyVersion
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `EnvoyFilter` 没有设置优先级并没有使用相关补丁操作（`INSERT_BEFORE/AFTER`、`REPLACE`、`MERGE`、`DELETE`）和 `proxyVersion` 时会出现此消息，这可能会导致 `EnvoyFilter` 升级期间没有被应用。使用 `INSERT_FIRST` 或 `ADD` 选项或设置优先级可能有助于确保 `EnvoyFilter` 被正确应用。关注 `proxyVersion` 的原因是，在升级后，`proxyVersion` 可能会发生变化，升级后它的使用顺序可能不同于升级前的顺序。

## 示例 {#example}

考虑一个 `EnvoyFilter` 的补丁操作 `REPLACE`，并使用 `proxyVersion`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-replace-3
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      app: reviews4
  configPatches:
    # The first patch adds the Lua filter to the listener/http connection manager
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
      proxy:
        proxyVersion: '^1\.11.*'
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
              1000)
            end

apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-replace-4
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      app: reviews4
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
    patch:
      operation: REPLACE
      value: #Lua filter specification
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

## 如何解决

因为 `REPLACE` 的相关操作是与 `proxyVersion` 一起使用，所以添加 `priority` 可以解决这个问题：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-replace-3
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      app: reviews4
  priority: 10
  configPatches:
    # The first patch adds the Lua filter to the listener/http connection manager
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
      proxy:
        proxyVersion: '^1\.11.*'
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
              1000)
            end

apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-replace-4
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      app: reviews4
  priority: 20
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
    patch:
      operation: REPLACE
      value: #Lua filter specification
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
