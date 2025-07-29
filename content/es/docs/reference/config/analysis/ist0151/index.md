---
title: EnvoyFilterUsesRelativeOperation
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when an `EnvoyFilter` does not have a priority and uses a relative patch operation (`INVALID`, `MERGE`, `REMOVE`, `INSERT_BEFORE`, `INSERT_AFTER`, `REPLACE`).  Using a relative patch operation means that the operation depends on another filter being there when the current `EnvoyFilter` filter is evaluated.  To ensure that the `EnvoyFilters` are applied in the order that the users want then a priority should be given or an non-relative operation (`ADD` or `INSERT_FIRST`) should be used.

## An example

Consider an `EnvoyFilter` with the patch operation of `INSERT_BEFORE`:

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
    # The first patch adds the Lua filter to the listener/http connection manager
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

## How to resolve

Because the relative operation of `INSERT_BEFORE` was used, changing it to absolute operation of `INSERT_FIRST` would resolve the issue:

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
    # The first patch adds the Lua filter to the listener/http connection manager
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
