---
title: SchemaWarning
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当资源通过了 Schema 验证，但验证返回警告时，会出现此消息。
警告不会阻止配置生效，它提示您该配置使用了已弃用的设置，或者其行为可能不符合您的预期。

## 示例 {#example}

假设一个 `VirtualService` 使用了已弃用的 `mirrorPercent` 字段：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
    mirror:
      host: reviews-mirror
    mirrorPercent: 50
{{< /text >}}

您将收到以下消息：

{{< text plain >}}
Warning [IST0133] (VirtualService default/reviews) Schema validation warning: using deprecated setting "mirrorPercent", use "mirrorPercentage" instead
{{< /text >}}

## 如何修复 {#how-to-resolve}

阅读警告文本并更新资源。在上面的示例中，将 `mirrorPercent` 替换为 `mirrorPercentage`。
