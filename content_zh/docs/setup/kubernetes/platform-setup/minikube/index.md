---
title: Minikube
description: 对 Minikube 集群进行配置以便安装运行 Istio。
weight: 15
-skip_toc: true
-skip_seealso: true
keywords: [platform-setup,kubernetes,minikube]
---

依照本指南对 Minikube 集群进行配置以便安装运行 Istio。

1. 要在本地运行 Istio，可以安装最新版本的 [Minikube](https://kubernetes.io/docs/setup/minikube/)（**0.28.1 或更高**）

1. 选择一个[虚拟机驱动](https://kubernetes.io/docs/setup/minikube/#quickstart)，安装之后，这里假设所选驱动为 `your_vm_driver_choice`，完成下面的步骤，要安装 Istio 控制面板组件、插件以及其他应用程序，我们建议使用内存大小为 8192 `MB` 和拥有 `CPU` 数量为 4 的机器:

    如果是 Kubernetes **1.9**：

    {{< text bash >}}
    $ minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.9.4 \
        --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota" \
        --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

    如果是 Kubernetes **1.10**：

    {{< text bash >}}
    $ minikube start --memory=8192 --cpus=4 --kubernetes-version=v1.10.0 \
        --vm-driver=`your_vm_driver_choice`
    {{< /text >}}
