---
title: List Entry
description: 该模板用于执行列表检查操作。
weight: 60
---

`listentry` 模板结合 `list` 适配器，可以用来进行列表检查。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: listentry
metadata:
  name: appversion
  namespace: istio-system
spec:
  value: source.labels["version"]
{{< /text >}}

## 模板

`listentry` 模板可以用来检查一个字符串是否存在于某列表之中。

该模板配置中的字段，可以是一个常量，也可以是一个[表达式](/zh/docs/reference//config/policy-and-telemetry/expression-language/)。要注意如果字段的数据类型不是 `istio.policy.v1beta1.Value`，那么表达式的类型必须和字段的[数据类型](/zh/docs/reference/config/policy-and-telemetry/expression-language/#类型检查)相匹配。

|字段|类型|说明|
|---|---|---|
|`value`|`string`|被检测的字符串|