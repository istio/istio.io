---
title: 镜像签名和验证
description: 描述如何使用镜像签名来验证 Istio 镜像的出处。
weight: 35
aliases: []
keywords: [install,signing]
owner: istio/wg-environments-maintainers
test: n/a
---

本页介绍如何使用 [Cosign](https://github.com/sigstore/cosign) 验证 Istio 镜像制品的来源。

Cosign 是作为 [sigstore](https://www.sigstore.dev) 项目的一部分开发的工具。
它简化了已签名的开放容器倡议（OCI）制品（例如容器镜像）的签名和验证。

从 Istio 1.12 开始，我们签署所有正式发布的容器镜像作为我们发布过程的一部分。
然后，最终用户可以使用下面描述的过程来验证这些镜像。

此过程适用于手动执行或与构建/部署管道集成，以自动验证镜像制品。

## 先决条件 {#prerequisites}

在开始之前，请执行以下操作：

1. 为您的架构下载最新的 [Cosign](https://github.com/sigstore/cosign/releases/latest) 构建及其签名。
1. 验证 `cosign` 二进制签名：

   {{< text bash >}}
$ openssl dgst -sha256 \
    -verify <(curl -ssL https://raw.githubusercontent.com/sigstore/cosign/main/release/release-cosign.pub) \
    -signature <(cat /path/to/cosign.sig | base64 -d) \
    /path/to/cosign-binary
    {{< /text >}}

1. 使二进制文件可执行（`chmod +x`），并移动到 `PATH` 上的一个位置。

## 验证镜像 {#validating-image}

要验证容器镜像，请执行以下操作：

{{< text bash >}}
$ ./cosign-binary verify --key "https://istio.io/misc/istio-key.pub" {{< istio_docker_image "pilot" >}}
{{< /text >}}

此过程适用于使用 Istio 构建基础设施构建的任何已发布镜像或待发布镜像。

输出示例：

{{< text bash >}}
$ cosign verify --key "https://istio.io/misc/istio-key.pub" gcr.io/istio-release/pilot:1.12.0


gcr.io/istio-release/pilot:1.12.0 的验证——对这些签名中的每一个都进行了以下检查：
  - 联合署名声明得到验证
  - 签名已根据指定的公钥进行验证
  - 任何证书都已针对 Fulcio 根进行了验证。

[{"critical":{"identity":{"docker-reference":"gcr.io/istio-release/pilot"},"image":{"docker-manifest-digest":"sha256:c37fd83f6435ca0966d653dc6ac42c9fe5ac11d0d5d719dfe97de84acbf7a32d"},"type":"cosign container image signature"},"optional":null}]
{{< /text >}}
