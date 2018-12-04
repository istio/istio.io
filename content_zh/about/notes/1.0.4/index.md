---
title: Istio 1.0.4
weight: 88
icon: notes
---

社区在 Istio 1.0.3 的使用过程中发现了一些严重问题，本次发布对这些问题进行了处理。本文对 Istio 1.0.3 和 1.0.4 两个版本之间的差异进行了描述。

{{< relnote_links >}}

## 已知问题

- 在执行 [`istioctl proxy-status`](/docs/reference/commands/istioctl/#istioctl-proxy-status) 命令获取代理同步状态时，Pilot 可能会发生死锁。要避免这一情况的发生，应避免使用 `istioctl proxy-status`。Pilot 进入死锁的表现是 `goroutine` 持续增长，直到耗尽内存。

## 网络

- 删除过期端点时候引发的 `503` 错误现已得到修正。

- Pod 标签中包含 `/` 时的注入行为得以修正。

## 策略和遥测

- 进程外 Mixer 适配器的不当行为会导致偶发的数据损坏，这一问题已经修正。

- 修复了 Mixer 在等待缺失的 CRD 过程中消耗 CPU 过多的问题。