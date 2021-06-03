---
title: 使用 Google Kubernetes Engine 快速开始
description: 在 Google Kubernetes Engine (GKE) 上快速搭建 Istio 服务。
weight: 20
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/gke/
    - /zh/docs/setup/kubernetes/platform-setup/gke/
keywords: [platform-setup,kubernetes,gke,google]
owner: istio/wg-environments-maintainers
test: no
---

依照以下操作指南为 Istio 准备一个 GKE 集群。

1. 创建一个新集群。

    {{< text bash >}}
    $ export PROJECT_ID=`gcloud config get-value project` && \
      export M_TYPE=n1-standard-2 && \
      export ZONE=us-west2-a && \
      export CLUSTER_NAME=${PROJECT_ID}-${RANDOM} && \
      gcloud services enable container.googleapis.com && \
      gcloud container clusters create $CLUSTER_NAME \
      --cluster-version latest \
      --machine-type=$M_TYPE \
      --num-nodes 4 \
      --zone $ZONE \
      --project $PROJECT_ID
    {{< /text >}}

    {{< tip >}}
    Istio的默认安装要求节点 vCPU 大于 1，如果您要使用[配置文件示例](/zh/docs/setup/additional-setup/config-profiles/)，您可以删除 `--machine-type` 参数，以使用较小 `n1-standard-1` 机器配置代替。
    {{< /tip >}}

    {{< warning >}}
    如果需要使用 Istio CNI 功能，需要在 `gcloud container clusters create` 命令中加入 `--enable-network-policy` 参数，以启用 GKE 集群的 [Network-Policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy) 功能。
    {{< /warning >}}

    {{< warning >}}
    **Private GKE Cluster**

    Pilot 检测 Validation Webhook 需要 15017 端口，但自动创建的防火墙规则不会打开这个端口。

    根据以下操作查看防火墙规则以允许 Master 访问：

    {{< text bash >}}
    $ gcloud compute firewall-rules list --filter="name~gke-${CLUSTER_NAME}-[0-9a-z]*-master"
    {{< /text >}}

    替换当前的防火墙规则以允许 Master 访问：

    {{< text bash >}}
    $ gcloud compute firewall-rules update <firewall-rule-name> --allow tcp:10250,tcp:443,tcp:15017
    {{< /text >}}

    {{< /warning >}}

1. 为 `kubectl` 获取认证凭据。

    {{< text bash >}}
    $ gcloud container clusters get-credentials <cluster-name> \
        --zone <zone> \
        --project <project-id>
    {{< /text >}}

1. 为 Istio 创建 RBAC 规则，需要授予当前用户集群管理员（admin）权限，根据如下命令进行授权操作。

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}
