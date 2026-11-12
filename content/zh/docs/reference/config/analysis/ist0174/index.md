---
title: UnknownDestinationRuleHost
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `DestinationRule` 的 `host` 与网格中的任何服务都不匹配时，会出现此消息。
该服务可以是 Kubernetes `Service`，也可以是 `ServiceEntry` 中的主机。

## 示例 {#example}

假设不存在 `reveiws` 服务，并有如下 `DestinationRule`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reveiws
{{< /text >}}

您将收到以下消息：

{{< text plain >}}
Warning [IST0174] (DestinationRule default/reviews) The host reveiws defined in the DestinationRule does not match any services in the mesh.
{{< /text >}}

## 如何修复 {#how-to-resolve}

- 确保主机名拼写正确。
- 如果服务位于不同的命名空间中，请使用主机的完全限定名称，
  例如 `reviews.bookinfo.svc.cluster.local`。
- 确保服务的 `exportTo` 字段使其对 `DestinationRule` 所在的命名空间可见。
- 如果主机位于网格外部，请为其创建 `ServiceEntry`。
