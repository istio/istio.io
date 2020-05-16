---
title: Istio 1.1.8 发布公告
linktitle: 1.1.8
subtitle: 补丁发布
description: Istio 1.1.8 补丁发布。
publishdate: 2019-06-06
release: 1.1.8
aliases:
    - /zh/about/notes/1.1.8
    - /zh/blog/2019/announcing-1.1.8
    - /zh/news/2019/announcing-1.1.8
    - /zh/news/announcing-1.1.8
---

我们非常高兴的宣布 Istio 1.1.8 已经可用。请浏览下面的变更说明。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复 CDS 集群的 `PASSTHROUGH` `DestinationRules`（[Issue 13744](https://github.com/istio/istio/issues/13744)）。
- 使 Helm charts 中的 `appVersion` 和 `version` 字段显示正确的 Istio 版本（[Issue 14290](https://github.com/istio/istio/issues/14290)）。
- 修复 Mixer 崩溃同时影响策略和遥测服务（[Issue 14235](https://github.com/istio/istio/issues/14235)）。
- 修复多集群时不同集群中的两个 pod 无法共享同一个 IP 地址的问题（[Issue 14066](https://github.com/istio/istio/issues/14066)）。
- 修复当 Citadel 无法连接 Kubernetes API 服务时重新生成新的根 CA 导致双向 TLS 验证失败的问题（[Issue 14512](https://github.com/istio/istio/issues/14512)）。
- 改进 Pilot 验证以拒绝相同域名的不同 `VirtualServices`，因为 Envoy 不会接受（[Issue 13267](https://github.com/istio/istio/issues/13267)）。
- 修复了本地负载均衡问题，即本地中只有一个副本会接收流量（[13994](https://github.com/istio/istio/issues/13994)）。
- 修复了 Pilot Agent 可能不会注意到 TLS 证书轮换的问题（[Issue 14539](https://github.com/istio/istio/issues/14539)）。
- 修复 Envoy 中一个 `LuaJIT` 崩溃问题（[Envoy Issue 6994](https://github.com/envoyproxy/envoy/pull/6994)）。
- 修复一个资源竞争问题：Envoy 可能在下游连接已经关闭 TCP 连接后重用 HTTP/1.1 连接，从而导致 503 错误和重试（[Issue 14037](https://github.com/istio/istio/issues/14037)）。
- 修复了 Mixer 的 Zipkin 适配器中的跟踪问题，该问题导致 spans 丢失（[Issue 13391](https://github.com/istio/istio/issues/13391)）。

## 小改进{#small-enhancements}

- 通过在 `DEBUG` 模式下记录 `the endpoints within network ... will be ignored for no network configured` 消息减少 Pilot 日志信息。
- 使 pilot-agent 忽略未知标记以更容易回滚。
- 将 Citadel 的默认根 CA 证书 TTL 从 1 年更新为 10 年。
