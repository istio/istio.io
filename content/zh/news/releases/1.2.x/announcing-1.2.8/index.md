---
title: 发布 Istio 1.2.8
linktitle: 1.2.8
subtitle: 发布补丁
description: Istio 1.2.8 版本修复。
publishdate: 2019-10-23
release: 1.2.8
aliases:
    - /zh/news/2019/announcing-1.2.8
    - /zh/news/announcing-1.2.8
---

我们很高兴地宣布 Istio 1.2.8 现在是可用的，详情请查看如下更改。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复了我们在 [10 月 8 日发布的安全性错误](/zh/news/security/istio-security-2019-005)，错误地计算了 `HTTP header` 和 `body sizes` ([Issue 17735](https://github.com/istio/istio/issues/17735))。

- 修复了一个较小的错误，将部署减小到 0 个副本时，`endpoint` 仍保留在 `/clusters` 中 ([Issue 14336](https://github.com/istio/istio/issues/14336))。

- 修复了 `Helm` 的升级过程，以正确的方式更新对 `mutual TLS` 的网格策略 ([Issue 16170](https://github.com/istio/istio/issues/16170))。

- 修复了在目标服务中对 `TCP` 连接的打开和关闭度量标准的不一致性问题 ([Issue 17234](https://github.com/istio/istio/issues/17234))。

- 修复了 `Istio` 的 `secret` 清除机制 ([Issue 17122](https://github.com/istio/istio/issues/17122))。

- 修复了 `Mixer Stackdriver` 适配器的编码过程，以处理无效的 `UTF-8` ([Issue 16966](https://github.com/istio/istio/issues/16966))。

## 特点{#features}

- 新增了 `pilot` 对新的故障域标签：`zone` 和 `region` 的支持。
