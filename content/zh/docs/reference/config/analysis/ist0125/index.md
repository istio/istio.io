---
title: InvalidAnnotation
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当集群的某些资源与 Istio 相关（名称归属 `istio.io`）但注解（annotation）包含以下情况时：

- 在此版本中不存在的注解
- 此版本中存在，但是其值不符合规范，比如要求值是数字但是设置了一个字符串
- 注解给到了错误的资源对象，比如本身需要归属 Pod 却给到了 Service

会出现此消息。

参考 [Istio 的资源注解表](/zh/docs/reference/config/annotations/)。

## 示例 {#example}

当集群包含以下资源时：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
  annotations:
    # 没有这种 Istio 注解
    networking.istio.io/exportTwo: bar
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin
{{< /text >}}

您会收到这条消息：

{{< text plain >}}
Warning [IST0108] (Service httpbin.default) Unknown annotation: networking.istio.io/exportTwo
{{< /text >}}

在这个样例中，Service `httpbin` 想要使用 `networking.istio.io/exportTwo`
代替 `networking.istio.io/exportTo`。

## 如何修复 {#how-to-resolve}

- 删除或重命名未知的注解
- 修改不允许的值
