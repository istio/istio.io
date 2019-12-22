---
title: 构建 & 发布节奏
description: 管理、编号和支持 Istio 发布的方式。
weight: 15
icon: cadence
---

我们每天都在构建发布 Istio。大约每个季度左右，我们会构建一个长期支持（LTS）的版本，并进行大量测试和发布资格认证。最后，如果发现 LTS 版本有问题，我们会发布补丁。

不同类型代表不同的产品质量水平和 Istio 团队对其的不同支持水平。在这种情况下，*支持* 意味着我们将为关键问题打补丁并提供技术支持。另外，第三方和合作伙伴可以提供长期支持解决方案。

|类型             | 支持级别                                                 | 质量和推荐使用
|-----------------|----------------------------------------------------------|----------------------------
|开发构建         | 不支持                                                   | 危险，不完全可靠。可以用于测试。
|LTS 版本         | 在下一个 LTS 之后的 3 个月内提供支持                     | 安全地部署在生产中。建议用户尽快升级到这些版本。
|补丁             | 与相应的 Snapshot/LTS 版本相同                           | 鼓励用户在给定版本可用时立即采用补丁版本。

您可以在[发布页面](https://github.com/istio/istio/releases)上找到可用的版本，如果您是冒险类型，您可以在[开发构建 wiki](https://github.com/istio/istio/wiki/Dev%20Builds) 上了解我们的开发构建。您可以在[此处](/zh/news)找到每个 LTS 版本的高级发行说明。

## 命名模式

LTS 版本的命名模式为：

{{< text plain >}}
<major>.<minor>.<LTS patch level>
{{< /text >}}

其中`<minor>`针对每个 LTS 版本增加，`<LTS patch level>`为当前 LTS 版本的补丁总数。补丁通常是相对于 LTS 的小变更。

对于 snapshot 版本，命名模式为：

{{< text plain >}}
<major>.<minor>.0-snapshot.<snapshot count>
{{< /text >}}

其中`<major>.<minor>`代表下一个LTS，`<sha>`代表git提交版本的构建发布。
