---
title: 发行说明
description: 每个 Istio 版本的功能和改进说明。
weight: 5
aliases:
  - /docs/reference/release-notes.html
  - /release-notes
  - /docs/welcome/notes/index.html
  - /docs/references/notes
---

- [Istio 1.0](./1.0)
- [Istio 0.8](./0.8)
- [Istio 0.7](./0.7)
- [Istio 0.6](./0.6)
- [Istio 0.5](./0.5)
- [Istio 0.4](./0.4)
- [Istio 0.3](./0.3)
- [Istio 0.2](./0.2)
- [Istio 0.1](./0.1)

最新的 Istio snapshot 版本是 {{< istio_version >}} （[发行说明](/zh/about/notes/{{< istio_version >}}/)）。您可以使用下面的命令[下载 {{< istio_version >}}](https://github.com/istio/istio/releases)：

{{< text bash >}}
$ curl -L https://git.io/getLatestIstio | sh -
{{< /text >}}

最新的稳定版本为 0.8。您可以使用下面的命令下载：

{{< text bash >}}
$ curl -L https://git.io/getIstio | sh -
{{< /text >}}

> 由于我们不控制 `git.io` 域，如果在任何敏感或非沙盒环境中运行，请检查 `curl` 命令的输出，然后再将其输出到 shell。