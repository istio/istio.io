---
title: Redis Quota
description: 基于 Redis 的配额管理系统。
weight: 140
---

`redisquota` 适配器可以用来给 Istio 的配额管理系统提供支持。它使用 Redis 服务器来存储配额数据。

这一适配器支持 [quota 模板](/zh/docs/reference/config/policy-and-telemetry/templates/quota/)。

## 参数

`redisquota` 适配器支持固定或滚动窗口算法的速率限制配额管理。它使用 Redis 存储共享数据。

配置样例：

{{< text yaml >}}
redisServerUrl: localhost:6379
connectionPoolSize: 10
quotas:
  - name: requestcount.quota.istio-system
    maxAmount: 50
    validDuration: 60s
    bucketDuration: 1s
    rateLimitAlgorithm: ROLLING_WINDOW
    overrides:
      - dimensions:
          destination: ratings
          source: reviews
        maxAmount: 12
      - dimensions:
          destination: reviews
        maxAmount: 5
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`quotas`|[`Params.Quota[]`](#quota)|已知的 `quota` 列表，其中至少包含一个 `quota` 配置|
|`redisServerUrl`|`string`|Redis 连接字符串，例如 `localhost:6379`|
|`connectionPoolSize`|`int64`|Redis 的最大闲置连接数。缺省设置为每 CPU 10 连接，CPU 数量来自 `runtime.NumCPU`|

## `Override`

|字段|类型|描述|
|---|---|---|
|`dimensions`|`map<string, string>`|为覆盖配置指定的 Dimension。字符串表达的 Dimension 来自模板配置，这个值不能为空|
|`maxAmount`|`int64`|覆盖 `quota` 配置的上限值。这个值必须大于零|

## `Quota`

|字段|类型|描述|
|---|---|---|
|`name`|`string`|配额的名称|
|`maxAmount`|`int64`|配额的上限，取值应大于零|
|`validDuration`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|在自动释放之前，已分配数额保持有效的时间长度。这只对速率限制配额有效，取值必须大于零|
|`bucketDuration`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|如果 `rateLimitAlgorithm` 设置为 `FIXED_WINDOW`，该字段无效，取值必须大于零且小于 `validDuration`|
|`rateLimitAlgorithm`|[`Params.QuotaAlgorithm`](#quotaalgorithm)|配额管理算法，缺省值为 `FIXED_WINDOW`|
|`overrides`|[`Params.Override[]`](#override)|这一配额的相关覆盖内容，第一次覆盖优先生效|

## `QuotaAlgorithm`

速率限制的算法。

|字段|描述|
|---|---|
|`FIXED_WINDOW`|固定窗口算法允许出现两倍的速率峰值，滑动窗口算法不会出现这样的情况|
|`ROLLING_WINDOW`|滑动窗口算法提供更加精确的控制，但是也会提高对 Redis 资源的消耗|
