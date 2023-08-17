---
title: Docker Desktop
description: 在 Docker Desktop 中运行 Istio 的设置说明。
weight: 15
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/docker-for-desktop/
    - /zh/docs/setup/kubernetes/prepare/platform-setup/docker/
    - /zh/docs/setup/kubernetes/platform-setup/docker/
keywords: [platform-setup,kubernetes,docker-desktop]
owner: istio/wg-environments-maintainers
test: no
---

1. 如果您想在 Docker Desktop 下运行 Istio，则需要安装[受支持的 Kubernetes 版本](/zh/docs/releases/supported-releases#support-status-of-istio-releases)
    ({{< supported_kubernetes_versions >}})。

1. 如果您想在 Docker Desktop 内置的 Kubernetes 下运行 Istio，您可能需要在 Docker Desktop 的 **Settings...** 中的
   **Resources->Advanced** 面板下增加 Docker 的内存限制。将资源设置为至少 8.0 `GB` 的内存和 4 核心 `CPUs`。

    {{< image width="60%" link="./dockerprefs.png"  caption="Docker Preferences"  >}}

    {{< warning >}}
    最低内存的要求不尽相同。8 `GB` 足以运行
    Istio 和 Bookinfo 实例。如果您没有足够的内存用于 Docker Desktop，
    则可能发生以下错误：

    - 镜像拉取失败
    - 健康检查超时失败
    - 主机上 kubectl 运行失败
    - 虚拟机管理程序的网络不稳定

    使用以下命令为 Docker Desktop 释放出更多可用资源：

    {{< text bash >}}
    $ docker system prune
    {{< /text >}}

    {{< /warning >}}
