---
title: List
description: 用于执行黑名单或白名单检测的适配器。
weight: 90
---

`list` 适配器能够用来执行简单的黑白名单校验工作。可以把列表内容直接配置到适配器中，也可以要求适配器在指定 URL 中抓取列表内容。列表元素可以是简单的字符串、IP 地址或者正则表达式。

该适配器支持 [`listentry 模板`](/zh/docs/reference/config/policy-and-telemetry/templates/listentry/)。

## 参数

`list` 适配器的配置格式。

|字段|类型|描述|
|---|---|---|
|`providerUrl`|`string`|从哪里找到列表内容进行检查。如果使用本地列表，则可以省略该字段|
|`refreshInterval`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|用于更新列表的频率|
|`ttl`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|列表的生效时间。一般来说 TTL 的值应该明显（两倍以上）超过 `refreshInterval`，从而确保操作的持续性|
|`cachingInterval`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|该适配器的调用者可以将一个查询结果写入本地缓存，在这一字段所规定的**时间**之内无需再次向适配器进行查询|
|`cachingUseCount`|`int32`|该适配器的调用者可以将一个查询结果写入本地缓存，在这一字段所规定的**次数**之内无需再次向适配器进行查询|
|`overrides`|`string[]`|在处理来自服务器的列表之前，首先查询该列表|
|`entryType`|[`ListEntryType`](#listentrytype)|决定列表的类型|
|`blacklist`|`bool`|如果为真，这一列表的操作符就是是黑名单，反之则是白名单|

## `ListEntryType`

列表的类型。

|字段|描述|
|---|---|
|`STRINGS`|普通字符串列表|
|`CASE_INSENSITIVE_STRINGS`|不区分大小写的字符串列表|
|`IP_ADDRESSES`|IP 地址和范围的列表|
|`REGEX`|[re2 规范](https://github.com/google/re2/wiki/Syntax)的正则表达式|