---
title: 表达式语言
description: Mixer 配置表达式语言手册。
weight: 20
aliases:
    - /zh/docs/reference/config/mixer/expression-language.html
---

这篇文档描述了怎样使用 Mixer 配置表达式语言(CEXL)。

## 底层{#background}

Mixer 配置使用了一种表达式语言(CEXL)去描述 match expressions 以及 [mapping expressions](/zh/docs/reference/config/policy-and-telemetry/mixer-overview/#attribute-expressions)。
CEXL 表达式为有类型的[值](https://github.com/istio/api/blob/{{< source_branch_name >}}/policy/v1beta1/value_type.proto)映射了一组带类型的[属性](/zh/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes)和常量。

## 语法{#syntax}

CEXL 使用 **[Go 表达式](https://golang.org/ref/spec#Expressions)**的一个子集作为语法。
CEXL 实现了一组 Go 操作符来限制这部分有限的 Go 表达式。
CEXL 同样支持任意的括号。

## 函数{#functions}

CEXL 支持如下函数。

|操作符/函数 |定义 |例子 | 描述|
|------------------|-----------|--------|------------|
|`==` |相等 |`request.size == 200`
|`!=` |不等 |`request.auth.principal != "admin"`
|<code>&#124;&#124;</code> |逻辑或 | `(request.size == 200)` <code>&#124;&#124;</code> `(request.auth.principal == "admin")`
|`&&` |逻辑与 | `(request.size == 200) && (request.auth.principal == "admin")`
|`[ ]` |Map 取值 | `request.headers["x-request-id"]`
|`+` |加 | `request.host + request.path`
|`>` |大于 | `response.code > 200`
|`>=` |大于等于 | `request.size >= 100`
|`<` |小于 | `response.code < 500`
|`<=` |小于等于 | `request.size <= 100`
|<code>&#124;</code> | 取首个非空元素 | `source.labels["app"]` <code>&#124;</code> `source.labels["svc"]` <code>&#124;</code> `"unknown"`
|`match` | 通配符匹配 |`match(destination.service, "*.ns1.svc.cluster.local")` | 以 `*` 的位置匹配前缀或后缀
|`email` | 将文本类型的 e-mail 转换为 `EMAIL_ADDRESS` 类型 | `email("awesome@istio.io")` | 使用 `email` 函数创建一个 `EMAIL_ADDRESS` 字面量。
|`dnsName` | 将文本类型的 DNS 转换为 `DNS_NAME` 类型 | `dnsName("www.istio.io")` | 使用 `dnsName` 函数创建一个 `DNS_NAME` 字面量。
|`ip` | 将文本类型的 IPv4 地址转换为 `IP_ADDRESS` type | `source.ip == ip("10.11.12.13")` | 使用 `ip` 函数创建一个 `IP_ADDRESS` 字面量。
|`timestamp` | 将文本类型的 RFC 3339 时间戳格式转换为 `TIMESTAMP` 类型 | `timestamp("2015-01-02T15:04:35Z")` | 使用 `timestamp` 函数创建一个 `TIMESTAMP` 字面量。
|`uri` | 将文本类型的 URI 转换为 `URI` 类型 | `uri("http://istio.io")` | 使用 `uri` 函数创建一个 `URI` 字面量。
|`.matches` | 正则表达式匹配 | `"svc.*".matches(destination.service)` | 通过正则表达式 `"svc.*"` 匹配 `destination.service`。
|`.startsWith` | 字符串前缀匹配 | `destination.service.startsWith("acme")` | 检查 `destination.service` 的值是否开始于 `"acme"`。
|`.endsWith` | 字符串后缀匹配 | `destination.service.endsWith("acme")`  | 检查 `destination.service` 的值是否结束于 `"acme"`。
|`emptyStringMap` | 创建一个空的 string map | `request.headers` <code>&#124;</code> `emptyStringMap()`| 为 `request.headers` 使用 `emptyStringMap` 去创建一个空的 string map 作为默认值。
|`conditional` | 三元运算 | `conditional((context.reporter.kind` <code>&#124;</code> `"inbound") == "outbound", "client", "server")` | report kind 是 `outbound` 时返回 `"client"`，否则返回 `"server"`。
|`toLower` | 将字符串转换成小写 | `toLower("User-Agent")` | 返回 `"user-agent"`
|`size` | 字符串的长度 | `size("admin")` | 返回 5

## 类型检查{#type-checking}

CEXL 变量是[属性词汇表](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)中的某个属性，常量是隐式类型，函数是显式类型。

Mixer 验证 CEXL 表达式的语法并在配置验证期间解析为一个类型。
选择器必须解析为 boolean 类型且 mapping expressions 必须解析为它所映射的类型。当选择器解析为 boolean 类型失败或 mapping expression 解析为不正确的类型时配置验证将失败。

比如，如果一个操作人员指定了一个 *string* 标签为 `request.size | 200`，这个表达式解析为 integer 类型从而验证将失败。

## 属性缺失{#missing-attributes}

如果表达式使用了一个在请求处理期间不可用的属性，则表达式将执行失败。如果属性可能缺失，请使用`|`运算符提供默认值。

比如，如果表达式 `request.auth.principal` 属性是缺失的则 `request.auth.principal == "user1"` 将执行失败。`|` (或) 运算符可以处理这个问题： `(request.auth.principal | "nobody" ) == "user1"`。

## 例子{#examples}

|表达式 |返回类型 |描述|
|-----------|------------|-----------|
|`request.size` <code>&#124; 200</code> |  **int** | `request.size` 在可用时返回其值，否则返回 200。
|`request.headers["x-forwarded-host"] == "myhost"`| **boolean**
|`(request.headers["x-user-group"] == "admin")` <code>&#124;&#124;</code> `(request.auth.principal == "admin")`| **boolean**| user 是 admin 或属于 admin 组时 结果为 True。
|`(request.auth.principal` <code>&#124;</code> `"nobody" ) == "user1"` | **boolean** | 如果 `request.auth.principal` 是 "user1" 则结果是 True，且 `request.auth.principal` 属性缺失时不会报错。
|`source.labels["app"]=="reviews" && source.labels["version"]=="v3"`| **boolean** | 如果 app label 是 reviews 且 version label 是 v3 则结果是 True， 否则是 false。