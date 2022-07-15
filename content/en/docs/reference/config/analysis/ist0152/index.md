---
title: EnvoyFilterUsesReplaceOperationIncorrectly
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when an `EnvoyFilter` uses the `REPLACE` operation and `ApplyTo` is set to `HTTP_FILTER` or `NETWORK_FILTER`.  This will cause the `REPLACE` operation to be ignored as `HTTP_FILTER` and `NETWORK_FILTER` are not valid for `REPLACE`.

## An example

Consider an `EnvoyFilter` with the patch operation of `REPLACE` where this `EnvoyFilter` will just be ignored:

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
