---
title: Check Nothing
description: 该模板不包含任何数据，用于测试。
weight: 40
---

`checknothing` 模板是一个空的数据块，在不同的测试场景中都可应用。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: checknothing
metadata:
  name: denyrequest
  namespace: istio-system
spec:
{{< /text >}}

## 模板

`checknothing` 适用于不需要任何输入参数的前置检查类的适配器。这一模板主要用于测试。