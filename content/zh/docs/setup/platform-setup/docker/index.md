---
title: Docker Desktop
description: 在 Docker Desktop 中运行 Istio 的设置说明。
weight: 12
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/docker-for-desktop/
    - /zh/docs/setup/kubernetes/prepare/platform-setup/docker/
    - /zh/docs/setup/kubernetes/platform-setup/docker/
keywords: [platform-setup,kubernetes,docker-desktop]
---

1. 如果你想在 Docker Desktop 下运行 Istio，则需要安装受支持的 Kubernetes 版本
    ({{< supported_kubernetes_versions >}})。

1. 如果你想在 Docker Desktop 内置的 Kubernetes 下运行 Istio，你可能需要在 Docker 首选项的 Advanced 面板下增加 Docker 的内存限制。设置可用的内存资源为 8.0 `GB` 以及 4 核心 `CPUs`.

    {{< image width="60%" link="./dockerprefs.png"  caption="Docker Preferences"  >}}

    {{< warning >}}
    最低内存的要求不尽相同。8 `GB` 足以运行
    Istio 和 Bookinfo 实例。如果你没有足够的内存用于 Docker Desktop，
    则可能发生以下错误：

    - 镜像拉取失败
    - 健康检查超时失败
    - 宿主上 kubectl 运行失败
    - 虚拟机管理程序的网络不稳定

    为 Docker Desktop 释放出更多可用资源：

    {{< text bash >}}
    $ docker system prune
    {{< /text >}}

    {{< /warning >}}
