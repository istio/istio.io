---
title: Authorization
description: 该模版用于访问控制查询。
weight: 30
location: https://istio.io/docs/reference/config/policy-and-telemetry/templates/authorization.html
layout: protoc-gen-docs
generator: protoc-gen-docs
number_of_entries: 3
---

Authorization 模版用于定义在 Istio 中策略执行的参数。启动 Mixer 可以配置此模版。

配置例子：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: authorization
metadata:
  name: authinfo
  namespace: istio-system
spec:
 subject:
   user: source.user | request.auth.token[user] | ""
   groups: request.auth.token[groups]
   properties:
    iss: request.auth.token["iss"]
 action:
   namespace: destination.namespace | "default"
   service: destination.service | ""
   path: request.path | "/"
   method: request.method | "post"
   properties:
     version: destination.labels[version] | ""
{{< /text >}}

## Action

Action 定义了“如何访问资源”。

|字段|类型|描述|
|----|----|----|
|namespace|string|命名空间|
|service|string|服务名称|
|method|string|请求方法|
|path|string|服务的 HTTP RestAPI|
|properties|`map<string,[`istio.policy.v1beta1.Value`](/zh/docs/reference/config/policy-and-telemetry/templates/authorization/#istio-policy-v1beta1-Value)>`|其他属性数据|

## Subject

Subject 包括用户身份识别属性

|字段|类型|描述|
|----|----|----|
|user|string|用户名称或 ID|
|group|string|认证的用户组，`groups` 可以从 JWT 断言或用户签名中获得。创建模版事例时可以指定。|
|properties|`map<string,[`istio.policy.v1beta1.Value`](/zh/docs/reference/config/policy-and-telemetry/templates/authorization/#istio-policy-v1beta1-Value)>`|其他属性数据|

## Template

Authorization 模版定义 Istio 中策略执行的参数。启动 Mixer 可以使用此模版来定义谁可以做什么。在模版中，`who` 定义了消息主题。`what` 定义了操作信息。在 Mixer 检查调用期间，将根据请求属性配置这些值，并将这些值传给各个授权适配器来进行决定。

|字段|类型|描述|
|----|----|----|
|subject|[`Subject`](/zh/docs/reference/config/policy-and-telemetry/templates/authorization/#Subject)|主题包括用户身份识别的属性列表|
|action|[`Action`](/zh/docs/reference/config/policy-and-telemetry/templates/authorization/#Action)|操作定义了如何访问资源|

## istio.policy.v1beta1.Value

Value 类型的字段表示该字段是动态类型，可以转换为任何 ValueType 枚举值。例如：模版中类型为 istio.policy.v1beta1.Value 的字段数据,下面两个表达式都是有效的 `data: source.ip | ip("0.0.0.0"), data: request.id | ""`；结果类型分别为 ValueType.IP_ADDRESS 或 ValueType.STRING。

Value 类型对象也会在请求时传递给适配器。 Value 中的一个字段与 ValueType 中的枚举值之间存在 1:1 映射的关系。 根据表达式的已评估 ValueType 值，由 Mixer 提供等效的 Value 类型的 oneof 字段并传给适配器。

|字段|类型|描述|
|----|----|----|
|stringValue|string (oneof)|STRING 类型的值|
|int64Value|int64 (oneof)|INT64 类型的值|
|doubleValue|double (oneof)|DOUBLE 类型的值|
|ipAddressValue|istio.policy.v1beta1.IPAddress (oneof)|IPAddress 类型的值|
|timestampValue|istio.policy.v1beta1.TimeStamp (oneof)|TIMESTAMP 类型的值|
|durationValue|istio.policy.v1beta1.Duration (oneof)|DURATION 类型的值|
|emailAddressValue|istio.policy.v1beta1.EmailAddress (oneof)|EmailAddress 类型的值|
|dnsNameValue|istio.policy.v1beta1.DNSName (oneof)|DNSName 类型的值|
|uriValue|istio.policy.v1beta1.Uri (oneof)|Uri类型的值|

