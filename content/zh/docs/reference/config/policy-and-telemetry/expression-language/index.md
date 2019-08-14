---
title: 表达式语言
description: Mixer 的配置表达式语言参考。
weight: 20
---
这个页面描述了如何使用 Mixer 的配置表达式语言 (Mixer configuration expression language，或缩写 CEXL)

## 背景介绍

Mixer 通过一种表达式语言 (CEXL) 去指定 Mixer 遥测策略配置的匹配表达式和[映射表达式](/zh/docs/concepts/policies-and-telemetry/#属性表达式)。这种 CEXL 表达式将一组类型化的[属性](/zh/docs/concepts/policies-and-telemetry/#属性)和常量映射到类型化的[值](https://github.com/istio/api/blob/master/policy/v1beta1/value_type.proto)。

## 语法

CEXL 表达式支持一部分的 **[Go 语言表达式](https://golang.org/ref/spec#Expressions)**，并以之作为 CEXL 的语法。CEXL 表达式自己实现了一部分 Go 语言的操作符，所以它只支持了一部分 Go 语言操作符。在 CEXL 表达式里你可以任意加上括号。

## 功能

CEXL 表达式支持下列的功能：

|运算符/函数|定义|例子|说明|
|------------------|-----------|--------|------------|
|`==` |相等|`request.size == 200`
|`!=` |不相等|`request.auth.principal != "admin"`
|<code>&#124;&#124;</code> |逻辑或| `(request.size == 200)` <code>&#124;&#124;</code> `(request.auth.principal == "admin")`
|`&&` |逻辑与| `(request.size == 200) && (request.auth.principal == "admin")`
|`[ ]` |访问字典 | `request.headers["x-request-id"]`
|`+` |加| `request.host + request.path`
|<code>&#124;</code> |默认值| `source.labels["app"]` <code>&#124;</code> `source.labels["svc"]` <code>&#124;</code> `"unknown"`
|`match` | 全局匹配|`match(destination.service, "*.ns1.svc.cluster.local")` | 通过指定 `*` 字符的位置，匹配以特定字符串作为前缀或后缀的值
|`email` | 将一个 email 字符串转换为一个 `EMAIL_ADDRESS` 类型 | `email("awesome@istio.io")` | 使用 `email` 函数创建一个 `EMAIL_ADDRESS` 类型的字面量
|`dnsName` | 将一个域名字符串转换为一个 `DNS_NAME` 类型 | `dnsName("www.istio.io")` | 使用 `dnsName` 函数创建一个 `DNS_NAME` 类型的字面量
|`ip` | 将一个 IPv4 地址字符串转换为一个 `IP_ADDRESS` 类型 | `source.ip == ip("10.11.12.13")` | 使用 `ip` 函数创建一个 `IP_ADDRESS` 类型的字面量
|`timestamp` | 将一个 RFC 3339 格式的时间字符串转换为一个 `TIMESTAMP` 类型 | `timestamp("2015-01-02T15:04:35Z")` | 使用 `timestamp` 函数创建一个 `TIMESTAMP`类型的字面量
|`uri` | 将一个 URI 字符串转换为一个 `URI` 类型 | `uri("http://istio.io")` | 使用 `uri` 函数创建一个 `URI` 类型的字面量
|`.matches` | 正则表达式匹配 | `"svc.*".matches(destination.service)` | 用正则表达式 `"svc.*"` 匹配 `destination.service`
|`.startsWith` | 匹配字符串前缀 | `destination.service.startsWith("acme")` | 匹配 `destination.service` 字符串是否以 `"acme"` 开始
|`.endsWith` | 匹配字符串后缀 | `destination.service.endsWith("acme")`  | 匹配 `destination.service` 字符串是否以 `"acme"` 结束
|`emptyStringMap` | 创建一个空字符串字典 | `request.headers` <code>&#124;</code> `emptyStringMap()`| 用 `emptyStringMap` 函数创建一个空字符串字典作为 `request.headers` 的默认值
|`conditional` | 模拟三元操作符| `conditional((context.reporter.kind` <code>&#124;</code> `"inbound") == "outbound", "client", "server")` | 如果 `reporter.kind` 的值是 `"outbound"` 的话，返回 `"client"`，否则返回 `"server"`
|`toLower` | 将字符串转换成小写 | `toLower("User-Agent")` | 返回 `"user-agent"`

## 类型检查

CEXL 表达式里的变量来自[属性表](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)里定义的属性，常量是隐式类型的，而函数是显式类型化的。

Mixer 在校验配置信息时，会校验其中的 CEXL 表达式，并将它转换为对应的类型。选择表达式必须解析成布尔值，而映射表达式必须解析为它们映射到的类型。如果选择表达式无法解析成布尔值，或者映射表达式解析成错误的类型，配置校验就会失败。

例如，如果一个需要传 *string* 类型的操作，但是传了 `request.size | 200` 表达式，配置校验就会失败，因为表达式经过解析后是一个整型值。

## 默认值

如果表达式尝试读取一个不存在的属性，表达式解析会失败。使用 `|` 操作符可以为这次读取属性设置一个默认值。

举个例子，如果 `request.auth.principal` 值不存在，在解析 `request.auth.principal == "user1"` 这个表达式时就会失败。可以用 `|` (OR) 操作符解决这个问题，比如将表达式改为： `(request.auth.principal | "nobody" ) == "user1"`。

## 例子

|表达式|返回类型|说明|
|-----------|------------|-----------|
|`request.size` <code>&#124;</code> `300` | `int` | 如果 `request.size` 存在，则返回，否则表达式值为整型 200
|`request.headers["x-forwarded-host"] == "myhost"`| **boolean**
|`(request.headers["x-user-group"] == "admin")` <code>&#124;&#124;</code> `(request.auth.principal == "admin")`| **boolean**| 如果用户为 admin，或者用户属于 admin 组，表达式为 true
|`(request.auth.principal` <code>&#124;</code> `"nobody" ) == "user1"` | **boolean** | 如果 `request.auth.principal` 的值的是 "user1"，表达式值为 true，表达式解析不会因为 `request.auth.principal` 不存在而失败
|`source.labels["app"]=="reviews" && source.labels["version"]=="v3"`| **boolean** | 如果 app label 的值为 "reviews" 而且 version label 是 "v3"，表达式值为 true，否则为 false
