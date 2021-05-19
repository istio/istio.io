---
title: 使用 GitHub 参与社区活动
description: 向您展示如何使用 GitHub 参与贡献 Istio 文档。
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

Istio 文档协作遵循标准的 [GitHub 协作流](https://guides.github.com/introduction/flow/)。这种成熟的协作模式有助于开源项目管理以下类型的贡献：

- [添加](/zh/about/contribute/add-content)新文件到存储库。
- [编辑](#quick-edit)现有文件。
- [审阅](/zh/about/contribute/review)添加或修改的文件。
- 管理多个发布或开发[分支](#branching-strategy)。

该贡献指南假定您可以完成以下任务：

- Fork [Istio 文档存储库](https://github.com/istio/istio.io)。
- 为您的更改创建分支。
- 向该分支添加提交。
- 打开一个 PR 分享您的贡献。

## 开始之前{#how-to-contribute}

要为 Istio 贡献文档，您需要：

1. 创建 [GitHub 帐户](https://github.com)。

1. 签署[贡献者许可协议](https://github.com/istio/community/blob/master/CONTRIBUTING.md#contributor-license-agreements)。

1. 安装 [Docker](https://www.docker.com/get-started)，以预览和测试您的文档更改。

文档是根据 [Apache 2.0](https://github.com/istio/istio.io/blob/master/LICENSE) 协议许可发布的。

## 快速编辑 {#quick-edit}

任何签署了 CLA 的 GitHub 帐户，都可以对 Istio 网站上的任何页面进行修改并提交贡献。这个过程非常简单：

1. 访问您要编辑的页面。
1. 将 `preliminary` 添加到 URL 的开头。例如，要编辑 `https://istio.io/about`，新 URL 应为 `https://preliminary.istio.io/about`。
1. 单击右下角的铅笔图标。
1. 在 GitHub UI 上进行编辑。
1. 创建 Pull Request 提交您的修改。

请参阅我们在[贡献新内容](/zh/about/contribute/add-content)或[内容审查](/zh/about/contribute/review)中的指南，
以了解有关提交更多实质性更改的详细信息。

## 分支策略{#branching-strategy}

文档内容的维护在 `istio/istio.io` 仓库 Master 分支进行，Istio 发布当天，我们基于 Master 创建发布分支。以下链接指向我们在 GitHub 上的存储库：

<a class="btn" href="https://github.com/istio/istio.io/">查看站点源码</a>

Istio 文档存储库使用多个分支发布所有 Istio 版本的文档。每个 Istio 发布都有相应的文档分支。例如，类似 `release-1.0`、`release-1.1`、`release-1.2` 等分支，都是在相应的发布日创建的。若要查看特定版本的文档，请参阅[存档页](https://archive.istio.io/)。

这种分支策略允许我们提供以下 Istio 在线资源：

- [发布站点](/zh/docs/)提供当前最新发布分支的内容。

- 预备站点 `https://preliminary.istio.io` 发布了当前 Master 分支上的最新内容。

- [存档站点](https://archive.istio.io)提供所有已发布分支的内容。

考虑到分支的工作原理，如果您提交修改到 master 分支，在 Istio 的下一个 major 版本发布前，这些更改都不会被应用到 istio.io。
如果您的文档更改和当前 Istio 版本密切相关，也可以将更改应用到当前版本的 Release 分支。您可以通过在文档的 PR 上使用 cherry-pick 标签，自动地执行此操作。
例如，如果您在 PR 中向 master 分支引入了更正，则可以通过 `cherrypick/release-1.4` 标签以将此更改合并到 `release-1.4` 分支。

一旦您的初始 PR 被合并，将自动在 Release 分支创建一个包含您的更改的 PR。为了使 `CLA` 机器人可以继续工作，您可能需要在 PR 上添加一个内容为 `@googlebot I consent` 的评论。

在极少数情况下，cherry picks 功能可能无效。发生这种情况时，自动化程序将在原始 PR 中留下一条注释，表明它已失败。发生这种情况时，您将需要手动创建 cherry pick，并处理阻止该过程自动运行的合并问题。

请注意，我们只会在当前版本的 Release 分支中应用更改，而不会在旧版本中进行。较旧的分支被视为已归档，并且通常不再接收任何更改。

## Istio 社区角色{#Istio-community-roles}

根据您的贡献和责任，您可以扮演多个角色。

访问我们的[社区角色页面](https://github.com/istio/community/blob/master/ROLES.md#role-summary)，在此页面您可以了解角色、相关的要求和职责以及与角色相关联的特权。

访问我们的[社区](https://github.com/istio/community)，您可以全面了解有关 Istio 社区的更多信息。
