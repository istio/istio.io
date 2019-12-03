---
title: 为什么我的规则无法匹配?
weight: 50
---

Mixer 的规则必须在运行时验证。这意味着匹配条件的表达式必须是用特定[语言](/zh/docs/reference/config/policy-and-telemetry/expression-language/)来明确定义，属性的声明应该在[属性清单](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)中，规则所指向的处理器和实例也必须存在。

在执行规则之前，属性值通常会被标准化。比如，在 `request.headers` 和 `response.headers` 属性中，HTTP 头的键是小写的。
表达式 `request.headers["X-Forwarded-Proto"] == "http"` 不会匹配任何请求，即使 HTTP 头部是不区分大小写的。
相反，应该使用这样的表达式 `request.headers["x-forwarded-proto"] == "http"`。