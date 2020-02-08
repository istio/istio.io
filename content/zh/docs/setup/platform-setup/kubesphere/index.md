---
title: KubeSphere 容器平台
description: 使用 KubeSphere 快速搭建与运维 Kubernetes 与 Istio。
weight: 18
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/kubesphere/
    - /zh/docs/setup/kubernetes/platform-setup/kubesphere/
keywords: [platform-setup,kubesphere,kubernetes]
---

本文将使用开源的 [KubeSphere 容器平台](https://github.com/kubesphere/kubesphere) 来搭建 Kubernetes 集群，下载 KubeSphere Installer 后可以即可在您的 Linux 环境中快速快速搭建与可视化管理 Kubernetes 与 Istio。

{{< tip >}}
KubeSphere 支持 **All-in-One** 和 **Multi-Node** 两种安装方式，帮助用户快速搭建 Kubernetes 与 Istio，并在一个统一的 Web 平台管理它们。本文仅介绍 All-in-One 单节点安装，关于多节点安装方式请参考 [Multi-node Installation](https://kubesphere.com.cn/docs/v2.1/zh-CN/installation/multi-node/)。
{{< /tip >}}

## 前提条件

一台全新的 Linux 主机 (64 bit)，支持虚拟机或物理机，并且至少有 2 个 CPU 和 4 GB 内存, 目前支持以下操作系统:


- CentOS 7.4 ~ 7.7
- Ubuntu 16.04/18.04 LTS
- RHEL 7.4
- Debian Stretch 9.5


{{< tip >}}
注意，建议在安装前关闭防火墙，如果您的机器有防火墙，请参考 [网络防火墙配置](https://kubesphere.com.cn/docs/v2.1/zh-CN/installation/port-firewall/) 并根据实际情况开放相关的端口。
{{< /tip >}}

## 安装 Kubernetes

1. 在您的 Linux 机器下载 KubeSphere Installer。

    {{< text bash >}}
    $ curl -L https://kubesphere.io/download/stable/v2.1.0 > installer.tar.gz \
    && tar -zxf installer.tar.gz && cd kubesphere-all-v2.1.0/scripts
    {{< /text >}}

1. 执行安装脚本，将创建一个 Kubernetes 集群（默认安装 v1.15，还支持 v1.13 和 v1.14）。

    {{< text bash >}}
    $ ./install.sh
    {{< /text >}}

1. 直接选择 "1) All-in-one" 即可开始快速安装。等待 20 分钟左右，当安装日志显示如下的日志并且所以 Pod 都是 Running 状态，则说明安装成功，可使用以下的账号和地址登录 KubeSphere。同时，Kubernetes 1.15 也已经安装成功。

    {{< text plain >}}
    #####################################################
    ###              Welcome to KubeSphere!           ###
    #####################################################
    Console: http://192.168.0.8:30880
    Account: admin
    Password: P@88w0rd
    {{< /text >}}

    ![KubeSphere Console](images/kubesphere-console.png)


## 开启 Istio 安装至 Kubernetes

KubeSphere 还支持开启一键安装 Istio 至 Kubernetes，并在 KubeSphere Console 对 Istio 可视化管理，详见 [开启 Istio（Service Mesh）](https://kubesphere.com.cn/docs/v2.1/zh-CN/installation/install-servicemesh/) 。
