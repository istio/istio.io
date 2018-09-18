---
title: 构建 & 发布节奏
description: 管理、编号和支持 Istio 发布的方式。
weight: 6
icon: cadence
---

我们每天都在构建发布 Istio。大约每个月我们会将其中一个日常构建版本通过一系列额外的质量测试后，将其构建标记为 Snapshot 版本。大约每个季度左右，我们会选择其中一个 Snapshot 版本运行更多测试并将构建标记为长期支持（LTS）版本。最后，如果发现 LTS 版本有问题，我们会发布补丁。

不同类型（每日、Snapshot、LTS）代表不同的产品质量水平和 Istio 团队对其的不同支持水平。在这种情况下，*支持* 意味着我们将为关键问题打补丁并提供技术支持。另外，第三方和合作伙伴可以提供长期支持解决方案。

|类型             | 支持级别                                            | 质量和推荐使用
|-----------------|----------------------------------------------------------|----------------------------
|每日构建      | 不支持                           | 危险，不完全可靠。可以用于测试。
|Snapshot 版本 | 仅支持最新的 snapshot 版本 | 预计相当稳定，但生产中的使用应限制在必要的基础上。通常只由前沿用户或寻求特定功能的用户采用。
|LTS 版本      | 在下一个 LTS 之后的 3 个月内提供支持 | 安全地部署在生产中。建议用户尽快升级到这些版本。
|补丁          | 与相应的 Snapshot/LTS 版本相同 | 鼓励用户在给定版本可用时立即采用补丁版本。

您可以在[发布页面](https://github.com/istio/istio/releases)上找到可用的版本，如果您是冒险类型，您可以在[每日构建 wiki](https://github.com/istio/istio/wiki/Daily-builds) 上了解我们的每日构建。您可以在[此处](/zh/about/notes)找到每个 LTS 版本的高级发行说明。

## 命名模式

在 Istio 0.8 之前，我们每月都会增加产品的版本号。从 0.8 开始，我们将仅为 LTS 版本增加产品的版本号。

LTS 版本的命名模式为：

{{< text plain >}}
<major>.<minor>.<LTS patch level>
{{< /text >}}

其中 <minor> 针对每个 LTS 版本增加，<LTS patch level> 为当前 LTS 版本的补丁总数。补丁通常是相对于 LTS 的小变更。

对于 snapshot 版本，命名模式为：

{{< text plain >}}
<major>.<minor>.0-snapshot.<snapshot count>
{{< /text >}}

其中 `<major>.<minor>.0` 表示下一个 LTS，`<snapshot count>` 从 0 开始，并且每个快照都会增加，直到下一个 LTS。

在极少的情况下我们需要向快照发补丁，编号为：

{{< text plain >}}
<major>.<minor>.0-snapshot.<snapshot count>.<snapshot patch level>
{{< /text >}}
