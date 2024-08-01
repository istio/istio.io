---
title: 下载 Istio 发行版 
description: 获取安装和探索 Istio 所需的文件。
weight: 30
keywords: [profiles,install,release,istioctl]
owner: istio/wg-environments-maintainers
test: n/a
---

每个 Istio 版本中都包含一个**发布档案**，其中包含：

- [`istioctl`](/zh/docs/ops/diagnostic-tools/istioctl/) 二进制文件
- [安装配置文件](/zh/docs/setup/additional-setup/config-profiles/)和
  [Helm Chart](/zh/docs/setup/install/helm)
- 示例，包括 [Bookinfo](/zh/docs/examples/bookinfo/) 应用程序

发布档案是为每个受支持的处理器架构和操作系统构建的。

## 下载 Istio {#download}

1.  前往 [Istio 发布版本]({{< istio_release_url >}})页面下载适用于您的操作系统的安装文件，
    或者自动下载并解压最新版本（Linux 或 macOS）：

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

    {{< tip >}}
    上述命令下载 Istio 的最新版本（以数字表示）。您可以在命令行中传递变量来下载特定版本或覆盖处理器架构。
    例如，要下载适用于 x86_64 体系结构的 Istio {{< istio_full_version >}}，请运行：

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_full_version >}} TARGET_ARCH=x86_64 sh -
    {{< /text >}}

    {{< /tip >}}

1.  转到 Istio 软件包目录。例如，如果软件包是 `istio-{{< istio_full_version >}}`：

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    安装目录中包含：

    - `samples/` 中的示例应用程序
    - `bin/` 目录中的 [`istioctl`](/zh/docs/reference/commands/istioctl) 客户端二进制文件。

1.  将 `istioctl` 客户端添加到您的 Path 中（Linux 或 macOS）：

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}
