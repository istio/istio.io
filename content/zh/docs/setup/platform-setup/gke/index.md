---
title: 使用 Google Kubernetes Engine 快速开始
description: 在 Google Kubernetes Engine (GKE) 上快速搭建 Istio 服务。
weight: 15
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/gke/
    - /zh/docs/setup/kubernetes/platform-setup/gke/
keywords: [platform-setup,kubernetes,gke,google]
---

{{< tip >}}
Google 为 GKE 提供了一个插件，
您可以使用它来代替手动安装 Istio。
要确定该插件是否适合您，请参阅 [Istio on GKE](https://cloud.google.com/istio/docs/istio-on-gke/overview)
以获得更多信息。
{{< /tip >}}

依照以下操作指南为安装 Istio 准备一个 GKE 集群。

{{< warning >}}
需要在 Istio 中启用 SDS，请使用 Kubernetes 1.13 或更高版本。
{{< /warning >}}

1. 创建一个新集群。

    {{< text bash >}}
    $ gcloud container clusters create <cluster-name> \
      --cluster-version latest \
      --machine-type=n1-standard-2 \
      --num-nodes 4 \
      --zone <zone> \
      --project <project-id>
    {{< /text >}}

    {{< tip >}}
    默认安装 Mixer 要求节点的 vCPU 大于 1。
    如果您要使用 [演示配置文件](/zh/docs/setup/additional-setup/config-profiles/)，
    您可以删除 `--machine-type` 参数，以使用较小 `n1-standard-1` 机器配置代替。
    {{< /tip >}}

    {{< warning >}}
    如果需要使用 Istio CNI 功能，
    需要在  `gcloud container clusters create`  命令中加入 `--enable-network-policy` 参数，
    以启用 GKE 集群的 [network-policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) 功能。
    {{< /warning >}}

1. 为 `kubectl` 获取认证凭据。

    {{< text bash >}}
    $ gcloud container clusters get-credentials <cluster-name> \
        --zone <zone> \
        --project <project-id>
    {{< /text >}}

1. 为了给 Istio 创建 RBAC 规则，需要给当前用户赋予集群管理员（admin）权限，因此这里进行授权操作。

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}
