---
title: Report Nothing
description: 该模板不包含数据，用于测试。
weight: 100
---

`reportnothing` 模板是一个空的数据块，用于协助各种场景下的测试。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: reportnothing
metadata:
  name: reportrequest
  namespace: istio-system
spec:
{{< /text >}}

## 模板

`reportnothing` 模板是一个空的数据块，用于不需要数据输入的报告类型的适配器。主要用于测试场景。