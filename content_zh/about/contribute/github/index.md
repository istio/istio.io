---
title: 使用 GitHub
description: 向您展示如何使用 GitHub 处理 Istio 文档。
weight: 20
keywords: [贡献]
---

很高兴您有兴趣为改进和扩展我们的文档做出贡献！在开始之前，请花点时间熟悉下程序。

要处理 Istio 文档，您需要：

1. 创建一个 [GitHub 账号](https://github.com)。

1. 签署[贡献者证书协议](https://github.com/istio/community/blob/master/CONTRIBUTING.md#contributor-license-agreements)。

该文档是在 [Apache 2.0](https://github.com/istio/istio.github.io/blob/master/LICENSE) 许可下发布的。

## 如何贡献

为 Istio 贡献文档有两种方式：

* 如果要编辑现有页面，可以在浏览器中打开页面，然后从每页右上角的齿轮菜单中选择**在 GitHub 上编辑此页面**选项。这将带您到 GitHub 上编辑和提交更改。
* 如果您希望修改网站源码，则必须创建存储库分支。单击下面的按钮以访问 GitHub 存储库。然后，您必须单击屏幕右上角的 **Fork** 按钮，在 GitHub 帐户中创建我们的存储库副本。创建 fork 的克隆并进行任何需要的更改。当您准备将这些更改发送给我们时，将更改推送到您的 fork，转到 fork 的索引页面，然后单击 **New Pull Request** 以告知我们。

<a class="btn btn-istio"
href="https://github.com/istio/istio.github.io/">浏览该站点的源码</a>

一旦您的更改被合并后，它们会立即显示在 [preliminary.istio.io](https://preliminary.istio.io/) 上。但是，这些更改只会在下次我们生成新版本时显示在 [istio.io](https://istio.io) 上，该版本每月发布一次。

## 预览您的成果

当您提交 pull request 时，GitHub 上的 PR 页面会显示一个链接，指向您的 PR 自动构建的临时站点。这有助于您查看面向最终用户的页面。审核您 pull request 的人也使用此临时站点，当一切看起来没有问题时才准许合并。

如果您创建了存储库的分支，则可以在本地预览更改。有关说明，请参阅 [README](https://github.com/istio/istio.github.io/blob/master/README.md)。