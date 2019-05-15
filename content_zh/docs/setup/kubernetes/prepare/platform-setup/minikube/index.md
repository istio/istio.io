---
title: Minikube
description: 对 Minikube 集群进行配置以便安装运行 Istio。
weight: 21
skip_seealso: true
keywords: [platform-setup,kubernetes,minikube]
---

按照本指南为 Istio 安装准备 Minikube ，并提供足够的资源来运行 Istio 和一些基本的应用程序。

1. 要在本地运行 Istio，可以安装最新版本的 [Minikube](https://kubernetes.io/docs/setup/minikube/) **1.0.0 或更高** 以及 [Minikube 管理驱动程序](https://kubernetes.io/docs/tasks/tools/install-minikube/#install-a-hypervisor) 。

    {{< tip >}}
    设置您的 Minikube 管理程序驱动程序。例如，如果您安装了 KVM 管理程序，请使用以下命令在 Minikube 配置中设置 vm-driver ：

    {{< text bash >}}
    $ minikube config set vm-driver kvm2
    {{< /text >}}

    {{< /tip >}}

1. 使用内存大小为 8192 `MB` 和拥有 `CPU` 数量为 4 的机器来启动 Minikube ，这个示例使用的 Kubernetes 版本是 **1.13.0** 。通过修改 `--Kubernetes -version` 值，您可以将版本更改为 Istio 支持的任何 Kubernetes 版本 :

    {{< text bash >}}
    $ minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.13.0
    {{< /text >}}

1. （可选项） 如果您想在 Minikube 中为 Istio 使用负载均衡器，可以使用
   [Minikube Tunnel](https://github.com/kubernetes/minikube/blob/master/docs/tunnel.md) 。

    {{< text bash >}}
    $ minikube tunnel
    {{< /text >}}

    {{< tip >}}
    运行 minikube 隧道特性将阻塞终端并输出诊断信息。在不同的终端上运行这个可选命令。
    {{< /tip >}}
