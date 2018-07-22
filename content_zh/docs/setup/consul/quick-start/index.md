---
title: 通过 Docker 快速安装
description: 通过 Docker Compose 快速安装 Istio service mesh。
weight: 10
keywords: [consul]
---

通过安装 Docker Compose 快速安装和配置 Istio。

## Prerequisites

* [Docker](https://docs.docker.com/engine/installation/)
* [Docker Compose](https://docs.docker.com/compose/install/)

## 安装步骤

1.  在 [Istio release](https://github.com/istio/istio/releases) 页面下载与你操作系统相对应的安装文件。如果你使用了 macOS 或者 Linux 系统，你还可以运行以下命令自动下载并解压最新版本的安装文件。

    {{< text bash >}}
    $ curl -L https://git.io/getLatestIstio | sh -
    {{< /text >}}

1.  解压下载好的文件并切换到文件所在的目录。安装文件目录中包含以下内容：

    * `samples/` 目录包含示例代码
    * `bin/` 目录中包含 `istioctl` 客户端二进制文件。`istioctl` 用来创建路由和策略等。
    * `istio.VERSION` 配置文件

1.  在你的 PATH 中添加 `istioctl` 客户端命令。比如，在 macOS 或者 Linux 系统中运行下面的命令：

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

1.  对于 Linux 用户，配置 `DOCKER_GATEWAY` 环境变量。

    {{< text bash >}}
    $ export DOCKER_GATEWAY=172.28.0.1:
    {{< /text >}}

1.  切换 Istio 安装目录的根目录。

1.  启动 Istio 控制平面的容器：

    {{< text bash >}}
    $ docker-compose -f install/consul/istio.yaml up -d
    {{< /text >}}

1.  确认所有的 docker 容器都在运行：

    {{< text bash >}}
    $ docker ps -a
    {{< /text >}}

    > 如果 Istio Pilot 容器停止了，确保运行 `istioctl context-create` 命令并且重复上一步骤。

1.  使用 `istioctl` 为 Istio API server 配置端口映射：

    {{< text bash >}}
    $ istioctl context-create --api-server http://localhost:8080
    {{< /text >}}

## 部署应用

你现在可以部署自己的应用或者 [Bookinfo](/docs/examples/bookinfo/) 中提供的示例应用。

> 由于在 Docker 中没有 pods 的概念，因此 Istio sidecar 需要和应用运行在同一个容器中。
> 我们会使用 [Registrator](https://gliderlabs.github.io/registrator/latest/) 将示例自动注册到 Consul 中。
>
> 应用必须使用 HTTP 1.1 或者 HTTP 2.0协议进行 HTTP 请求，因为 HTTP 1.0 不被支持。

{{< text bash >}}
$ docker-compose -f <your-app-spec>.yaml up -d
{{< /text >}}

## 卸载

通过删除 docker 容器便可卸载 Istio 核心组件：

{{< text bash >}}
$ docker-compose -f install/consul/istio.yaml down
{{< /text >}}
