---
title: 本地构建和运行本网站
description: 介绍如何在本地进行本网站的构建，测试，运行和预览。
weight: 5
keywords: [contribute, serve, Docker, Hugo, build]
---

在为本站做贡献之后，要确保变更是符合预期的。可以通过做本地预览来确保没问题，我们提供了相应的工具让您方便的构建和查看。我们使用了自动化测试来检测所有贡献的质量。在把修改的内容放在一个合并请求（PR）中提交之前，您也应该在本地运行测试。

## 开始之前 {#before-you-begin}

为了保证本地运行测试的工具和 Istio 持续集成（CI）运行测试的工具是相同的版本，我们提供了一个包含了所有需要工具的 Docker 镜像，包括了我们站点的生成器：[Hugo](https://gohugo.io/)。

为了本地构建，测试和预览站点，要在您的系统上安装 [Docker](https://www.docker.com/get-started)。

## 预览变更 {#preview-your-changes}

要预览对站点的修改，在 `istio/istio.io` 的分支根目录执行下面的命令：

{{< text bash >}}
$ make serve
{{< /text >}}

如果修改没有编译出错误，这个命令会构建这个站点，并且启动一个本地 web 服务来运行这个站点。通过在浏览器中输入 `http://localhost:1313` 来浏览本地构建的站点。

如果要从远程服务器上构建和预览，可以使用 `ISTIO_SERVE_DOMAIN` 来设置这个服务器的 IP 地址或者 DNS 域名，例如：

{{< text bash >}}
$ make ISTIO_SERVE_DOMAIN=192.168.7.105 serve
{{< /text >}}

这个例子是在 `192.168.7.105` 这个远程服务器上构建站点并且启动一个 web 服务。像前面一样，可以通过 `http://192.168.7.105:1313` 这个地址来访问这个 web 服务器。

### 测试变更 {#test-your-changes}

我们使用静态检测和测试方法，通过自动检查确保网站内容的质量基线。提交的贡献都必须成功通过这些检测才能被批准合入主线。在提交 PR 之前确保在本地已经运行了这些检查。我们会执行以下自动检查：

- HTML 校对：确保所有链接以及其它检查均有效。
- 拼写检查：确保所有内容的拼写都是正确的。
- Markdown 格式检查：确保使用的标记符合我们的 Markdown 样式规则。

使用下面的命令来执行本地检查：

{{< text bash >}}
$ make lint
{{< /text >}}

如果拼写检查有错误，很有可能是以下原因：

- 有错别字：在 Markdown 文件上修复错别字。
- 报告有命令，字段或者符号名称错误：将带有错误的内容放在反引号中。
- 因为没有在工具词典中而被报告错误：将单词添加到 `istio/istio.io` 根目录下的 `.spelling` 文件中。

如果网络链接不稳定，可能会无法使用链接检查器。如果您的网络链接不好，可以设置检查器不检查外部链接。例如：在运行静态检查之前，设置环境变量 `INTERNAL_ONLY` 为 `True`：

{{< text bash >}}
$ make INTERNAL_ONLY=True lint
{{< /text >}}

当修改内容通过所有检查，就可以把修改作为 PR 向仓库提交了。更多信息请访问[如何使用 GitHub](/zh/about/contribute/github)。
