---
title: EnvoyFilterUsesRemoveOperationIncorrectly
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `EnvoyFilter` 使用 `REMOVE` 操作并且 `ApplyTo` 设置为 `ROUTE_CONFIGURATION` 或
`HTTP_ROUTE` 时会出现此消息。这将导致 `REMOVE` 操作被忽略。
目前只有 `MERGE` 操作可以用于 `ROUTE_CONFIGURATION`。

## 示例 {#example}

考虑一个带有 `REMOVE` 补丁操作的 `EnvoyFilter`，其中这个 `EnvoyFilter` 将被忽略：

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
