---
title: DestinationRuleSubsetNotSelectPods
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `DestinationRule` 中的某个子集没有选中任何 Pod 时，会出现此消息。

路由到此子集的请求将失败，并返回 `503` 错误和 `UH`（无健康上游）响应标志。

## 示例 {#example}

假设没有任何 `reviews` Pod 带有 `version: v4` 标签，并有如下 `DestinationRule`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v4
    labels:
      version: v4
{{< /text >}}

您将收到以下消息：

{{< text plain >}}
Error [IST0173] (DestinationRule default/reviews) The Subset v4 defined in the DestinationRule does not select any pods. Which may lead to 503 UH (NoHealthyUpstream).
{{< /text >}}

## 如何修复 {#how-to-resolve}

执行以下操作之一：

- 修改子集的标签，使其选中正确的 Pod。
- 部署该子集应选中的 Pod。
- 如果不再使用该子集，请将其移除。
