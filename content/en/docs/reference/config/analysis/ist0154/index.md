---
title: EnvoyFilterUsesRemoveOperationIncorrectly
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when an `EnvoyFilter` uses the `REMOVE` operation and `ApplyTo` is set to `ROUTE_CONFIGURATION` or `HTTP_ROUTE`.  This will cause the `REMOVE` operation to be ignored.  At the moment only the `MERGE` operation can be used for `ROUTE_CONFIGURATION`.

## An example

Consider an `EnvoyFilter` with the patch operation of `REMOVE` where this `EnvoyFilter` will just be ignored:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-remove-2
  namespace: bookinfo
spec:
  workloadSelector:
    labels:
      app: mysvc2
  configPatches:
  - applyTo: ROUTE_CONFIGURATION
    match:
      context: GATEWAY
      listener:
        filterChain:
          sni: app.example.com
          filter:
            name: "envoy.filters.network.http_connection_manager.InternalAddressConfig"
    patch:
      operation: REMOVE
{{< /text >}}
