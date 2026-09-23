---
title: EnvoyFilterUsesRelativeOperationWithProxyVersion
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when an `EnvoyFilter` does not have a priority and uses a relative patch operation (`INSERT_BEFORE/AFTER`, `REPLACE`, `MERGE`, `DELETE`) and `proxyVersion` set which can cause the `EnvoyFilter` not to be applied during an upgrade. Using the `INSERT_FIRST` or `ADD` option or setting the priority may help in ensuring the `EnvoyFilter` is applied correctly."  The reason for concern with the `proxyVersion` is that after an upgrade the `proxyVersion` would likely have changed and the order it is applied would now be different than before.

## An example

Consider an `EnvoyFilter` with the patch operation of `REPLACE` with the use of `proxyVersion`:

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

## How to resolve

Because the relative operation of `REPLACE` was used along with the `proxyVersion`, adding a `priority` would resolve the issue:

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
