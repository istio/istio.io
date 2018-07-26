---
title: Minikube
description: 对 Minikube 集群进行配置以便安装运行 Istio
weight: 15
keywords: [platform-setup,kubernetes,minikube]
---

依照本指南对 Minikube 集群进行配置以便安装运行 Istio。

1. 要在本地运行 Istio，可以安装最新版本的 [Minikube](https://kubernetes.io/docs/setup/minikube/)（**0.28.0 或更高**）

1. 选择一个[虚拟机驱动](https://kubernetes.io/docs/setup/minikube/#quickstart)，安装之后，这里假设所选驱动为 `your_vm_driver_choice`，完成下面的步骤：

    如果是 Kubernetes **1.9**：

    {{< text bash >}}
    $ minikube start --memory=4096 --kubernetes-version=v1.9.4 --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

    如果是 Kubernetes **1.10**：

    {{< text bash >}}
    $ minikube start --memory=4096 --kubernetes-version=v1.10.0 --vm-driver=`your_vm_driver_choice`
    {{< /text >}}
