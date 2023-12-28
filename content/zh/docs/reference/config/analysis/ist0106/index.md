---
title: SchemaValidationError
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当您的 Istio 配置没有成功通过模式验证时，会出现此消息。

例如，您将会看到以下错误：

{{< text plain >}}
Error [IST0106] (VirtualService ratings-bogus-weight-default.default) Schema validation error: percentage 888 is not in range 0..100
{{< /text >}}

并且您的 Istio 配置包含以下参数值：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-bogus-weight-default
  namespace: default
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
      weight: 999
    - destination:
        host: ratings
        subset: v2
      weight: 888
{{< /text >}}

在这个示例中，错误消息是指在模式检查时发现 `weight` 属性的取值错误或无效。

要解决此问题，参考[消息详情](/zh/docs/reference/config/analysis/message-format/)
的字段来了解哪些属性无效或错误，更正所有错误后重试。

有关 Istio 资源的预期模式详情，请查看[配置参考](/zh/docs/reference/config/)。
