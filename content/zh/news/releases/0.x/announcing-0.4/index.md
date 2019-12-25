---
title: Istio 0.4 发布公告
linktitle: 0.4
subtitle: 重大更新
description: Istio 0.4 发布公告。
publishdate: 2017-12-18
release: 0.4.0
aliases:
    - /zh/about/notes/older/0.4
    - /zh/docs/welcome/notes/0.4.html
    - /zh/about/notes/0.4/index.html
    - /zh/news/2017/announcing-0.4
    - /zh/news/announcing-0.4
---

随着我们稳定的每月发布流程，此版本只进行了几周的更改。除了普通的错误修复和性能改进之外，此版本还包含以下项。

{{< relnote >}}

## General

- **Cloud Foundry**。增加了对 [Cloud Foundry](https://www.cloudfoundry.org) 平台的最低 Pilot 支持，使 Pilot 可以发现 CF 服务和服务实例。

- **Circonus**。Mixer 现在包含了用于 [Circonus](https://www.circonus.com) 分析和监控平台的适配器。

- **Pilot 指标**。Pilot 现在会收集诊断指标。

- **Helm Chart**。现在，我们提供了 Helm Chart 安装 Istio 的方式。

- **增强的属性表达式**。Mixer 的表达语言获得了一些新功能，使编写策略规则变得更加容易。[学到更多](/zh/docs/reference/config/policy-and-telemetry/expression-language/)

如果您想了解细节，可以在 [此处](https://github.com/istio/istio/wiki/v0.4.0) 查看我们更详细的低级发行说明。
