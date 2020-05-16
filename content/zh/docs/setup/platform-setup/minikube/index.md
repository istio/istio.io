---
title: Minikube
description: 在 Minikube 上配置 Istio。
weight: 21
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/minikube/
    - /zh/docs/setup/kubernetes/platform-setup/minikube/
keywords: [platform-setup,kubernetes,minikube]
---

按照文档安装 minikube，为 Istio 与一些基础应用准备足够的系统资源。

## 前提条件{#prerequisites}

- 运行 minikube 需要管理员权限。

- 如果要启用[秘钥发现服务](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration)（SDS），需要为 Kubernetes deployment 添加[额外的配置](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection)。
访问 [`api-server` 参考文档](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)查看最新的可选参数。

## 安装步骤{#installation-steps}

1. 安装最新的 [minikube](https://kubernetes.io/docs/setup/minikube/)，版本 **1.1.1 或更高**，以及
    [minikube 虚拟机驱动](https://kubernetes.io/docs/tasks/tools/install-minikube/#install-a-hypervisor)。

1. 如果你没有使用默认的驱动，需要配置 minikube 虚拟机驱动。

    比如，如果你安装了 KVM 虚拟机，使用如下命令设置 minikube 的 `vm-driver` 配置：

    {{< text bash >}}
    $ minikube config set vm-driver kvm2
    {{< /text >}}

1. 以 16384 `MB` 内存和 4 `CPUs` 启动 minikube。这个例子使用了 Kubernetes **1.14.2**。
    你可以设置 `--kubernetes-version` 的值以指定任意 Istio 支持的 Kubernetes 版本：

    {{< text bash >}}
    $ minikube start --memory=16384 --cpus=4 --kubernetes-version=v1.14.2
    {{< /text >}}

    取决于你使用的虚拟机版本以及所运行的平台，最小内存要求也不同。16384 `MB` 足够运行
    Istio 和 bookinfo。

    {{< tip >}}
    如果你没有足够的内存分配给 minikube 虚拟机，可能出现如下报错：

    - image pull failures
    - healthcheck timeout failures
    - kubectl failures on the host
    - general network instability of the virtual machine and the host
    - complete lock-up of the virtual machine
    - host NMI watchdog reboots

    minikube 中有一个不错的方法查看内存占用：

    {{< text bash >}}
    $ minikube ssh
    $ top
    GiB Mem : 12.4/15.7
    {{< /text >}}

    这里显示虚拟机内全部的 15.7G 内存已占用了 12.4G。这个数据是在一个 16G 内存的 Macbook Pro 13" 中运行着 Istio 1.2 和
     bookinfo 的 VMWare Fusion 虚拟机中生成的。
    {{< /tip >}}

1. （可选，推荐）如果你希望 minikube 提供一个负载均衡给 Istio，你可以使用
    [minikube tunnel](https://minikube.sigs.k8s.io/docs/tasks/loadbalancer/#using-minikube-tunnel)。
    在另一个终端运行这个命令，因为 minikube tunnel 会阻塞的你的终端用于显示网络诊断信息：

    {{< text bash >}}
    $ minikube tunnel
    {{< /text >}}

    {{< warning >}}
    有时 minikube 不会正确清理 tunnel network。强制清理使用如下命令：

    {{< text bash >}}
    $ minikube tunnel --cleanup
    {{< /text >}}

    {{< /warning >}}
