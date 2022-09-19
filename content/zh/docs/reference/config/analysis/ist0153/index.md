---
title: EnvoyFilterUsesAddOperationIncorrectly
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `EnvoyFilter` 使用 `ADD` 操作且 `ApplyTo` 设置为 `ROUTE_CONFIGURATION` 或 `HTTP_ROUTE` 时，会出现此消息。
这将导致 `ADD` 操作被忽略。目前，只有 `MERGE` 操作可用于 `ROUTE_CONFIGURATION`。

## 例如{#example}

以下示例中，如果一个 `EnvoyFilter` 附带有 `ADD` 补丁操作，该 `EnvoyFilter` 将被忽略：

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
      filterClass: AUTHZ # 此过滤器将在 Istio 的 authz 过滤器之后运行。
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
