---
title: 加固 Docker 容器镜像
description: 使用加固的容器镜像来减小 Istio 的攻击面。
weight: 80
aliases:
    - /zh/help/ops/security/harden-docker-images
---
为了简化加固 docker 镜像的过程，Istio 提供了一系列基于[非发行版镜像](https://github.com/GoogleContainerTools/distroless)的镜像

{{< warning >}}
*非发行版镜像*的工作还在进行中。
下列镜像尚未支持*非发行版*：

- `proxyproxy`
- `proxy_debug`
- `kubectl`
- `app_sidecar`

为了简化安装，它们可通过带上 `-distroless` 后缀来使用。
{{< /warning >}}

## 安装非发行版镜像{#install-distroless-images}

按照[安装步骤](/zh/docs/setup/install/istioctl/)来设置 Istio。
添加 `--set tag={{< istio_full_version >}}-distroless` 选项以使用*非发行版镜像*。

## 效果{#benefits}

非发行版镜像已经不再包含非必需的可执行文件和库。

- 攻击面减小了。包括尽可能少的漏洞。
- 镜像更小了，启动更快。

请参考官方非发行版 README 的[为何我选择非发行版镜像？](https://github.com/GoogleContainerTools/distroless#why-should-i-use-distroless-images)章节。

{{< warning >}}
请注意，通常的调试工具如 `bash`、`curl`、`netcat`、`tcpdump` 等在非发行版镜像中是不可用的。
{{< /warning >}}
