---
title: EnvoyFilterUsesAddOperationIncorrectly
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when an `EnvoyFilter` uses the `ADD` operation and `ApplyTo` is set to `ROUTE_CONFIGURATION` or `HTTP_ROUTE`.  This will cause the `ADD` operation to be ignored.  At the moment only the `MERGE` operation can be used for `ROUTE_CONFIGURATION`.

## An example

Consider an `EnvoyFilter` with the patch operation of `ADD` where this `EnvoyFilter` will just be ignored:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: test-auth-2
  namespace: bookinfo
spec:
  configPatches:
  - applyTo: ROUTE_CONFIGURATION
    match:
      context: SIDECAR_INBOUND
    patch:
      operation: ADD
      filterClass: AUTHZ # This filter will run *after* the Istio authz filter.
      value:
        name: envoy.filters.http.ext_authz
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
          grpc_service:
            envoy_grpc:
              cluster_name: acme-ext-authz
            initial_metadata:
            - key: foo
              value: myauth.acme # required by local ext auth server.
{{< /text >}}
