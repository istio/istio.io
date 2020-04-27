---
title: 构建 & 发布节奏
description: 管理、编号和支持 Istio 发布的方式。
weight: 15
icon: cadence
---

每个提交我们会产生 Istio 新构建。大约每个季度，我们会构建一个长期支持（LTS）的版本，并进行大量测试和发布认证。最后，如果发现 LTS 版本有问题，我们会发布补丁。

不同类型代表不同的产品质量水平和 Istio 团队对其的不同支持水平。在这种情况下，*支持* 意味着我们将为关键问题发布补丁并提供技术支持。另外，第三方和合作伙伴也可能提供长期支持方案。

|类型             | 支持级别                                                 | 质量和建议使用场景
|-----------------|----------------------------------------------------------|----------------------------
|开发构建         | 不支持                                                   | 不完全可靠。建议用于实验、测试场景。
|LTS 版本         | 在下一个 LTS 版本后的 3 个月内提供支持                     | 可安全地用于生产环境。建议用户尽快升级到这些版本。
|补丁             | 与相应的 Snapshot/LTS 版本相同                           | 建议用户在补丁可用时尽快采用。

您可以在[发布页面](https://github.com/istio/istio/releases)上找到可用的版本，如果您想了解、体验最新特性，您可以在[开发构建 wiki](https://github.com/istio/istio/wiki/Dev%20Builds) 上了解我们的开发构建版本。您可以在[此处](/zh/news)找到每个 LTS 版本的简要发行说明。

## 命名模式{#naming-scheme}

LTS 版本的命名模式为：

{{< text plain >}}
<major>.<minor>.<LTS patch level>
{{< /text >}}

其中 `<minor>` 针对每个 LTS 版本递增，`<LTS patch level>`为当前 LTS 版本补丁总数。补丁相对于 LTS 通常是较小变更。

对于 snapshot 版本，命名模式为：

{{< text plain >}}
<major>.<minor>-alpha.<sha>
{{< /text >}}

其中 `<major>.<minor>` 代表下一个 LTS，`<sha>` 代表此版本构建基于的 git 提交。
