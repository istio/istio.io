---
title: 使用 GitHub 参与社区活动
description: 向您展示如何使用 GitHub 处理 Istio 文档。
weight: 30
aliases:
    - /zh/docs/welcome/contribute/creating-a-pull-request.html
    - /zh/docs/welcome/contribute/staging-your-changes.html
    - /zh/docs/welcome/contribute/editing.html
    - /zh/about/contribute/creating-a-pull-request
    - /zh/about/contribute/editing
    - /zh/about/contribute/staging-your-changes
keywords: [contribute,community,github,pr]
---

我们很高兴您对改进和扩展 Istio 文档感兴趣！在开始之前，请花一些时间来熟悉改进与拓展 Istio 文档的流程。

要处理 Istio 文档，您需要：

1. 创建一个 [GitHub 账户](https://github.com)。

1.签署[贡献者许可协议](https://github.com/istio/community/blob/master/CONTRIBUTING.md#contributor-license-agreements).

该文档是根据 [Apache 2.0](https://github.com/istio/istio.io/blob/master/LICENSE) 协议许可发布的。

## 如何贡献{#how-to-contribute}

您可以通过以下三种方式为 Istio 文档做出贡献：

* 如果您想要编辑现有页面，可以在浏览器中打开页面，然后从该页面右上方的齿轮菜单中选择**在 GitHub 上编辑此页面**选项，这将带您到 GitHub 页面进行编辑操作并提交相应的更改。

* 如果您想使用通用的方式在站点上工作，请遵循我们的[如何添加内容](#add)中的步骤。

* 如果您想对现有的 pull request（PR）评审，遵循我们的[如何查看内容](#review)中的步骤。

合并您的更改后，您的更改会立即显示在 `preliminary.istio.io` 上。但是，更改仅在下一次我们发布一个新版本的时候才会在 `istio.io` 上显示，该更改大约每季度一次。

### 如何添加内容{#add}

要添加内容，您必须创建 Istio 仓库的分支以及从该分支到 Istio 仓库 docs 文档的 PR。以下步骤描述了该过程：

<a class="btn" href="https://github.com/istio/istio.io/">浏览 Istio 网站的源代码</a>

1.  单击上方的按钮访问 GitHub Istio 仓库。

1.  单击屏幕右上角的**Fork**按钮，以在您的 GitHub 帐户中创建我们的 Istio 仓库的副本。

1.  创建 fork 的分支，然后进行所需的任何更改。

1.  当您准备将这些更改发送给我们时，请将更改推送到您的 fork 分支。

1.  跳转您的 fork 分支的索引页面，然后单击**New Pull Request**提交 pr。

### 如何查看内容{#review}

如果您的评论内容很少，请直接在 PR 上发表评论。如果您评论的内容很详细，请按照以下步骤操作：

1.  在 PR 上评论 `/hold` 。此命令可防止 PR 在完成审阅之前被合并。

1.  在 PR 中评论具体信息。如果可以的话，请在受影响的文件和文件行上直接评论特定的具体信息。

1.  适当时在评论中向 PR 提交者与参与者提供建议。例如：

    {{< text markdown >}}
    使用现在时可避免动词一致问题并使文本更易于理解：

    &96;&96;&96;suggestion

    Pilot maintains an abstract model of the mesh.

    &96;&96;&96;
    {{< /text >}}

1.  发布您的评论，与 PR 参与者分享您的评论和建议。

    {{< warning >}}
    如果您不发布评论，则 PR 所有参与者者和社区将看不到您的评论。
    {{< /warning >}}

1.  发布评论后，大家经过讨论一致同意合并 PR，请在文本上留下：`/hold cancel`。该命令将取消阻止 PR 合并。

## 预览工作

当您提交 pull request 时，您在 GitHub 上的 PR 页面会显示一个指向为您的 PR 自动构建的登入站点的链接，这对于您查看最终用户的最终页面看起来很有用。这个临时的网站，可以确保页面预览看起来正常。

如果您创建了 Istio 仓库的分支，则可以在本地预览更改效果。
有关说明，请参阅 [README](https://github.com/istio/istio.io/blob/master/README.md)。

## Istio 社区角色

根据您的贡献和责任，您可以扮演多个角色。

访问我们的[社区角色页面](https://github.com/istio/community/blob/master/ROLES.md#role-summary)，在此页面您可以了解角色、相关的要求和职责以及与角色相关联的特权。

访问我们的 [社区](https://github.com/istio/community)，您可以全面了解有关 Istio 社区的更多信息。