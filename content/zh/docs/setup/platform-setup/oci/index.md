---
title: Oracle Cloud Infrastructure
description: 为 Istio 配置 OKE 集群环境的说明。
weight: 27
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/oci/
    - /zh/docs/setup/kubernetes/platform-setup/oci/
keywords: [platform-setup,kubernetes,oke,oci,oracle]
---

根据如下介绍，为 Istio 配置 OKE 集群环境。

1. 在您的 OCI 租户中，创建一个新的 OKE 集群。最简单的方式就是使用 [web 控制台](https://docs.cloud.oracle.com/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm)中的 'Quick Cluster' 选项。您也可以使用下面的 [OCI cli](https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/cliinstall.htm) 命令:

    {{< text bash >}}
    $ oci ce cluster create --name oke-cluster1 \
        --kubernetes-version <preferred version> \
        --vcn-id <vcn-ocid> \
        --service-lb-subnet-ids [] \
        ..
    {{< /text >}}

1. 使用 OCI cli 为您的 `kubectl` 获取凭据:

    {{< text bash >}}
    $ oci ce cluster create-kubeconfig \
        --file <path/to/config> \
        --cluster-id <cluster-ocid>
    {{< /text >}}

1. 向当前用户授予集群管理员（admin）权限。要为 Istio 创建必要的 RBAC 规则，当前用户需要拥有管理员权限。

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=<user_ocid>
    {{< /text >}}

