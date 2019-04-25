---
title: 为什么我的规则无法匹配？
weight: 50
---

Mixer 在运行时必须通过验证才能生效。这就要求匹配条件需要是一个有效的[表达式](/zh/docs/reference/config/policy-and-telemetry/expression-language/)，其中需要用到的属性定义在[属性词汇表](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)中，同时 Rule 中包含的 Handler 和 Instance 引用也必须是有效的。

在表达式运行之前通畅会对属性值进行预处理。例如 `request.headers` 和 `response.headers` 中包含的 HTTP 头的键会被转换为小写。表达式 `request.headers["X-Forwarded-Proto"] == "http"` 是不会完成匹配的，而应该修改成 `request.headers["x-forwarded-proto"] == "http"`。