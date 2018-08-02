---
title: Istio 0.4
weight: 97
page_icon: /img/notes.svg
---

我们稳定了月度发布流程，因此这一版本只有几个星期的工作量。在平淡无奇的问题修复和性能增强之外，这个版本中包括：

- **Cloud Foundry**：为 [Cloud Foundry](https://www.cloudfoundry.org) 平台加入了最小限度的 Pilot 支持，这样 Pilot 就能够发现 CF 服务及其实例了。

- **Circonus**：Mixer 中加入了 [Circonus](https://www.circonus.com) 监控和分析平台的适配器。

- **Pilot 指标**：现在开始收集 Pilot 的指标用于诊断.

- **Helm Charts**.：提供了用于安装 Istio 的 Helm chart。

- **增强的属性表达式**：Mixer 的表达式语言加入了一些新的函数，增强了易用性，可以更方便的编写策略规则。[参考资料](/docs/reference/config/policy-and-telemetry/expression-language/)

如果希望了解更多低级细节，可以进一步阅读[发行说明](https://github.com/istio/istio/wiki/v0.4.0)。
