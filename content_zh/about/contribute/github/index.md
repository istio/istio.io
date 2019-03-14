---
title: 使用 GitHub
description: 向您展示如何使用 GitHub 处理 Istio 文档。
weight: 20
keywords: [contribute,community,github,pr]
---

很高兴您有兴趣为改进和扩展我们的文档做出贡献！在开始之前，请花点时间熟悉下程序。

要处理 Istio 文档，您需要：

1. 创建一个 [GitHub 账号](https://github.com)。

1. 签署[贡献者证书协议](https://github.com/istio/community/blob/master/CONTRIBUTING.md#contributor-license-agreements)。

该文档是在 [Apache 2.0](https://github.com/istio/istio.io/blob/master/LICENSE) 许可下发布的。

## 如何贡献

为 Istio 贡献文档有三种方式：

* 如果要编辑现有页面，可以在浏览器中打开页面，然后从每页右上角的齿轮菜单中选择**在 GitHub 上编辑此页面**选项。这将带您到 GitHub 上对页面进行编辑，并可以提交更改。

* 还有更为通用的方式来对站点进行修改，具体步骤在[如何创建新内容](#add)一节中有更多介绍。

* 如果想要对现有的 Pull Request（PR）进行评审，请参看[内容评审](#review)的相关内容。

变更请求被合并之后，会马上在 `preliminary.istio.io` 进行呈现。然而 `istio.io` 上的内容不会立即变更，这个站点的内容仅在有新版本发布的时候才会更新，通常是一个季度一次。

## 如何创建新内容 {#add}

要加入新内容，首先要 Fork 文档版本仓库，然后从你的 Fork 中创建一个 PR 到文档版本库之中。具体步骤如下：

<a class="btn"
href="https://github.com/istio/istio.io/">Browse this site's source
code</a>

1. 点击上面的按钮，浏览 GitHub 仓库。

1. 点击右上角的 **Fork** 按钮，在自己的 GitHub 账号下复制一个文档版本库的副本。

1. 在本地克隆这个新副本，进行编辑。

1. 完成变更之后，将变更内容推送到前面 Fork 产生的版本库之中。

1. 前往 Fork 版本库的首页，点击 **New Pull Request**，通知项目成员。

## 如何评审内容 {#review}

如果你的评审意见很少，只要简单的给 PR 加上说明就可以了。如果你的评审比较详细，请按以下步骤执行：

1. 在 PR 中加入回复 `/hold`。这个命令会阻止该 PR 的合并，直到完成评审完成为止。

1. 开始评审。可以在文件的指定行上直接写入意见。

1. 可以为 PR 的所有者提出一些建议，例如：

    {{< text markdown >}}
    Use present tense to avoid verb congruence issues and
    to make the text easier to understand:

    ```suggestion

    Pilot maintains an abstract model of the mesh.

    ```
    {{< /text >}}

1. 发表评审结果之后，在 PR 中加入回复 `/hold cancel`，将会解锁 PR，允许合并。

## 预览您的成果

当您提交 Pull request 时，GitHub 上的 PR 页面会显示一个链接，指向您的 PR 自动构建的临时站点。这有助于您查看面向最终用户的页面。审核您 Pull request 的人也使用此临时站点，当一切看起来没有问题时才准许合并。

如果您创建了存储库的分支，则可以在本地预览更改。有关说明，请参阅 [README](https://github.com/istio/istio.io/blob/master/README.md)。

## Istio 社区的角色

根据每个人的职责和贡献，社区中存在多种角色。

[角色概览页面](https://github.com/istio/community/blob/master/ROLES.md#role-summary)中介绍了各种角色的要求和责任，及其所具备的权限。

[社区页面](https://github.com/istio/community)中对 Istio 社区进行了简单的介绍。