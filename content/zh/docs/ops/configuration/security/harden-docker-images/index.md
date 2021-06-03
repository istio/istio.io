---
title: 加固 Docker 容器镜像
description: 使用加固的容器镜像来减小 Istio 的攻击面。
weight: 80
aliases:
  - /zh/help/ops/security/harden-docker-images
  - /zh/docs/ops/security/harden-docker-images
owner: istio/wg-security-maintainers
test: n/a
---

为了简化加固 docker 镜像的过程，Istio 提供了一系列基于[非发行版镜像](https://github.com/GoogleContainerTools/distroless)的镜像

## 安装非发行版镜像{#install-distroless-images}

按照[安装步骤](/zh/docs/setup/install/istioctl/)配置 Istio。
添加 `--set tag={{< istio_full_version >}}-distroless` 选项以使用 *非发行版镜像* 。

{{< text bash >}}
$ istioctl install --set tag={{< istio_full_version >}}-distroless
{{< /text >}}

## 效果{#benefits}

使用非发行版时，非发行版镜像已经不再包含非必需的可执行文件和库。

- 减少了攻击面。尽可能少的漏洞。
- 镜像更小了，且启动更快。

请参考官方非发行版 README 的[为何选择非发行版镜像？](https://github.com/GoogleContainerTools/distroless#why-should-i-use-distroless-images) 章节。

{{< warning >}}
请注意，通常的调试工具如 `bash`、`curl`、`netcat`、`tcpdump` 等在非发行版镜像中是不可用的。
{{< /warning >}}
