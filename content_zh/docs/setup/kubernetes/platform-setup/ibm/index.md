---
title: IBM Cloud Kubernetes Service
description: 对 IBM Cloud Kubernetes Service（IKS）集群进行配置以便安装运行 Istio。
weight: 12
keywords: [platform-setup,ibm,iks]
---

依照本指南对 IBM IKS 集群进行配置以便安装运行 Istio。

1. 创建新的 `lite` 集群：

    {{< text bash >}}
    $ bx cs cluster-create --name <cluster-name> --kube-version 1.9.7
    {{< /text >}}

    或者创建一个新的付费集群：

    {{< text bash >}}
    $ bx cs cluster-create --location location --machine-type u2c.2x4 \
      --name <cluster-name> --kube-version 1.9.7
    {{< /text >}}

1. 为 `kubectl` 获取认证凭据。下面的命令需要根据实际情况对 `<cluster-name>` 进行替换：

    {{< text bash >}}
    $(bx cs cluster-config <cluster-name>|grep "export KUBECONFIG")
    {{< /text >}}

## IBM Cloud Private

[设置 kubectl 客户端](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_cli.html)以便对 IBM Cloud Private 进行访问
