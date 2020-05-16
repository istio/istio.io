---
title: Istio 1.2.6 发布公告
linktitle: 1.2.6
subtitle: 发布补丁
description: Istio 1.2.6 版本发布公告。
publishdate: 2019-09-17
release: 1.2.6
aliases:
    - /zh/about/notes/1.2.6
    - /zh/blog/2019/announcing-1.2.6
    - /zh/news/2019/announcing-1.2.6
    - /zh/news/announcing-1.2.6
---

我们很高兴地宣布 Istio 1.2.6 现在是可用的，详情请查看如下更改。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复了 `redisquota` 有关 `memquota` 的计数不一致问题 ([Issue 15543](https://github.com/istio/istio/issues/15543))。
- 修复了在 Istio 1.2.5 中引入的 Envoy 崩溃问题 ([Issue 16357](https://github.com/istio/istio/issues/16357))。
- 修复了在插件证书（带有中间证书）的上下文中损坏的 `Citadel` 的运行状况的检查 ([Issue 16593](https://github.com/istio/istio/issues/16593))。
- 修复了 Stackdriver Mixer Adapter 的错误日志的详细程度 ([Issue 16782](https://github.com/istio/istio/issues/16782))。
- 修复了一个错误，该错误将删除具有多个端口的服务主机上的账户映射。
- 修复了由 Pilot 产生的不正确的通配符 `filterChainMatch` 导致的主机重复的问题 ([Issue 16573](https://github.com/istio/istio/issues/16573))。

## 小改进{#small-enhancements}

- 当与 Stackdriver 等服务进行会话连接时，会暴露 `sidecarToTelemetrySessionAffinity` (Mixer V1 需要) ([Issue 16862](https://github.com/istio/istio/issues/16862))。
- 暴露 `HTTP/2` 窗口大小作为 Pilot 的环境变量 ([Issue 17117](https://github.com/istio/istio/issues/17117))。
