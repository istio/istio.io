---
title: Istio 1.0.4 发布公告
linktitle: 1.0.4
subtitle: 补丁发布
description: Istio 1.0.4 补丁发布。
publishdate: 2018-11-21
release: 1.0.4
aliases:
    - /zh/about/notes/1.0.4
    - /zh/blog/2018/announcing-1.0.4
    - /zh/news/2018/announcing-1.0.4
    - /zh/news/announcing-1.0.4
---

我们很高兴的宣布 Istio 1.0.4 现已正式发布。下面是更新详情。

{{< relnote >}}

## 已知问题{#known-issues}

- 使用 [`istioctl proxy-status`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-status) 来获取代理同步状态时，可能会导致 Pilot 死锁。
  临时的解决方法是不使用 `istioctl proxy-status`。
  一旦 Pilot 进入死锁状态，它将表现出持续的内存增长，最终耗尽内存。

## 网络{#networking}

- 修复了过期 endpoint 漏删导致 503 错误的 bug。

- 修复了 Pod 标签包含 `/` 时 sidecar 的注入 bug。

## 策略和遥测{#policy-and-telemetry}

- 修复了进程外 Mixer 适配器偶尔的数据损坏问题导致的不正确行为。

- 修复了在等待失踪的 CRD 时，Mixer 过度使用 CPU 的 bug。
