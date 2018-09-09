---
title: Rules
description: 用于对 Mixer 的策略和和遥测功能进行配置的规则。
weight: 60
---

## Action

Action 为 Mixer 提供了一个定义：发送什么数据给哪个 [Handler](#Handler) 进行处理。

下面的例子指示 Mixer 使用 `RequestCountByService` 这一 [Instance](#Instance) 构建数据，并调用 `prometheus-handler` 进行处理。

{{< text yaml >}}
handler: prometheus-handler
instances:
- RequestCountByService
{{< /text >}}

|字段|类型|说明|
|---|---|---|
|`handler`|`string`|必要字段。要调用的 Handler 的完全限定名。必须能够匹配到一个 [Handler](#Handler) 的 `name`|
|`instances`|`string[]`|必要字段。其中的每个值都必须能够匹配到某个 [Instance](#Instance) 的完全限定名。被引用的 Instance 会解析所有字段的属性和常量，最后生成的对象被提交给 `action` 中的 `handler` 进行处理|
|`name`|`string`|可选字段。用于引用这一 Action 的句柄|

## Instance

Instance 告知 Mixer 如何为某个模板创建实例。

Instance 由运维人员根据已知模板进行编写。这一文件的存在目的是告知 Mixer 如何使用属性或常量在运行时对特定的模板进行实例化。

下面的例子要求 Mixer 对模板 `istio.mixer.adapter.metric.Metric` 进行实例化。它提供了一个模板字段到表达式的映射关系。[Action](#Action) 可以使用名称 `RequestCountByService` 来引用这一 Instance 生成的实例。

{{< text yaml >}}
- name: RequestCountByService
  template: istio.mixer.adapter.metric.Metric
  params:
    value: 1
    dimensions:
      source: source.service
      destination_ip: destination.ip
{{< /text >}}

|字段|类型|说明|
|---|---|---|
|`name`|`string`|必要字段。Instance 的名称。必须保持唯一。[Action](#Action) 可以使用这一字段引用该 Instance。|
|`compiledTemplate`|`string`|必要字段。Instance 所要进行实例化的内置（`compiled-in`）模板的名称。要引用其它模板，则应该使用 `template` 字段。该字段取值必须取自内置模板列表|
|`template`|`string`|必要字段。Instance 所要进行实例化的模板的名称。如果引用的是内置模板，则应该使用 `compiledTemplate` 字段。该字段取值必须取自当前范围的可用模板列表|
|`params`|[`google.protobuf.Struct`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#struct)|必要字段。这里的结构定义来自于相关模板。|

## Handler

## Rule

Rule 由一个选择器和一组动作构成，当选择器的结果为 `true` 时，就执行对应的动作。

下面的例子要求 Mixer 对所有服务执行 `prometheus-handler`，并且用 `RequestCountByService` 这一 Instance 生成的实例作为该 Handler 的输入。

{{< text yaml >}}
- match: destination.service == "*"
  actions:
  - handler: prometheus-handler
    instances:
    - RequestCountByService
{{< /text >}}

|字段|类型|说明|
|---|---|---|
|`match`|`string`|必要字段。这个字段是一个表达式。在 Mixer 收到请求之后，会根据请求属性来执行这一表达式，如果运算结果为 `true`，则执行 `action` 字段中的操作。表达式中可以使用与或非这样的逻辑操作连接多个子表达式。例如表达式 `true`，代表无条件执行；表达式 `destination.service == ratings*` 会选择目标服务名称以 `ratings` 为前缀的请求|
|`actions`|[`Action[]`](#Action)|可选字段。当 `match` 结果为 `true` 的时候要执行的动作|
|`requestHeaderOperations`|[`Rule.HeaderOperationTemplate[]`](#rule-headeroperationtemplate)|可选字段。根据针对请求 Header 进行模板化操作|
|`responseHeaderOperations`|[`Rule.HeaderOperationTemplate[]`](#rule-headeroperationtemplate.operation)|可选字段。可选字段。根据针对响应 Header 进行模板化操作|

## `Rule.HeaderOperationTemplate`

对 HTTP Header 进行操作的模板。

|字段|类型|说明|
|---|---|---|
|`name`|`string`|必要字段。Header 的名称|
|`value`|`string[]`|可选字段。要进行添加或者替换的 Header 值|
|`operation`|[`Rule.HeaderOperationTemplate.Operation`](#rule-headeroperationtemplate-operation)|可选字段。操作类型。缺省操作是根据 Header 名称对其中的值进行替换|

## `Rule.HeaderOperationTemplate.Operation`

Header 操作类型。

|字段|说明|
|---|---|
|`REPLACE`|替换指定名称的 Header 值|
|`REMOVE`|删除指定名称的 Header，`value` 会被忽略|
|`APPEND`|在指定名称的 Header 值后追加指定值|