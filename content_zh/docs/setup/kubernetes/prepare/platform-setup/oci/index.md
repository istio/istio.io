---
title: Oracle Cloud Infrastructure
description: 为 Istio 对 OKE 集群环境进行配置。
weight: 27
skip_seealso: true
keywords: [platform-setup,kubernetes,oke,oci,oracle]
---

根据如下介绍，为 Istio 配置 OKE 集群环境。

1. 在你的 OCI 租户中，创建一个新的 OKE 集群。最简单的方式就是使用 [Web Console](https://docs.cloud.oracle.com/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm) 中的 “Quick Cluster” 选项。也可以使用下面的 [OCI cli](https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm) 命令：

    {{< text bash >}}
    $ oci ce cluster create --name oke-cluster1 \
        --kubernetes-version <preferred version> \
        --vcn-id <vcn-ocid> \
        --service-lb-subnet-ids [] \
        ..
    {{< /text >}}

1. 使用 OCI cli 为 `kubectl` 获取登录凭据。

    {{< text bash >}}
    $ oci ce cluster create-kubeconfig \
        --file <path/to/config> \
        --cluster-id <cluster-ocid>
    {{< /text >}}

1. 要给 Istio 创建必要的 RBAC 规则，需要为当前用户获取管理员（admin）权限。

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=<user_ocid>
    {{< /text >}}
