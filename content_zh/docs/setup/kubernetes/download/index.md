---
title: 下载 Istio 发布包
description: 关于 Istio 发布包下载过程的说明。
weight: 1
keywords: [kubernetes]
---

## 安装之前的下载和准备

Istio 会被安装到自己的 `istio-system` 命名空间，并且能够对所有其他命名空间的服务进行管理。

1. 进入 [Istio release](https://github.com/istio/istio/releases) 页面，下载对应目标操作系统的安装文件。在 macOS 或者 Linux 系统中，还可以运行下面的命令，进行下载和自动解压缩：

    {{< text bash >}}
    $ curl -L https://git.io/getLatestIstio | ISTIO_VERSION={{< istio_full_version >}} sh -
    {{< /text >}}

1. 进入 Istio 包目录。例如，假设这个包是 `istio-{{< istio_full_version >}}`：

    {{< text bash >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    安装目录中包含：

    * 在 `install/` 目录中包含了 Kubernetes 安装所需的 `.yaml` 文件
    * `samples/` 目录中是示例应用
    * `istioctl` 客户端文件保存在 `bin/` 目录之中。`istioctl` 的功能是手工进行 Envoy Sidecar 的注入。
    * `istio.VERSION` 配置文件

1. 把 `istioctl` 客户端加入 PATH 环境变量，如果是 macOS 或者 Linux，可以这样实现：

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}
