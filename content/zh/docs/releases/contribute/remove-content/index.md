---
title: 删除已停用的文档
description: 详细说明如何将已停用的文档提交给 Istio。
weight: 4
aliases:
    - /zh/about/contribute/remove-content
    - /zh/latest/about/contribute/remove-content
keywords: [contribute]
owner: istio/wg-docs-maintainers
test: n/a
---

要从Istio中删除文档，请遵循以下简单步骤：

1. 删除页面。
1. 调整失效的链接。
1. 将您的贡献提交到 GitHub。

## 删除页面{#remove-the-page}

使用 `git rm -rf` 删除包含目录的 `index.md` 页。

## 调整失效的链接{#reconcile-broken-links}

若要调整失效的链接，请使用以下流程：

{{< image width="100%"
    link="./remove-documentation.svg"
    alt="Remove Istio documentation."
    caption="Remove Istio documentation"
    >}}

## 将您的贡献提交到 GitHub{#submit-your-contribution-to-GitHub}

如果您不熟悉 GitHub，请参阅我们的 [GitHub工作指南](/zh/docs/releases/contribute/github),
了解如何提交文档更改。

如果您想了解更多关于您的贡献如何以及何时发表的信息，
请参阅[分支部分](/zh/docs/releases/contribute/github#branching-strategy)，
以了解我们如何使用分支和各种技巧来发布内容。
