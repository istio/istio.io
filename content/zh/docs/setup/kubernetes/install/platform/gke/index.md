---
title: 使用 Google Kubernetes Engine 快速开始
linktitle: Google Kubernetes Engine
description: 在 Google Kubernetes Engine (GKE) 上快速搭建 Istio 服务。
weight: 65
keywords: [kubernetes,gke,google]
---

这是一个快速开始的操作指南，用于在 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)（GKE）上使用 [Istio on GKE](https://cloud.google.com/istio/docs/istio-on-gke/overview) 安装并运行 Istio。

## 先决条件

- 该用例需要一个启用了支付功能的有效的 Google Cloud Platform 项目。如果读者现在还不是 GCP 用户，可以现在加入，能够获得 [300 美元](https://cloud.google.com/free/) 的的充值点数用于试用。
- 确认试用项目已经启用了 [Google Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com/)（在导航菜单中查找 “API 和服务” -> “信息中心”）。如果没有看到这一 API，则需要首先进行启用。
- 必须安装和配置 [`gcloud` 命令行工具](https://cloud.google.com/sdk/docs/)，并确保其中包含 `kubectl` 组件（`gcloud components install kubectl`）。如果不想安装 `gcloud` 客户端，还可以使用 [Google Cloud Shell](https://cloud.google.com/shell/docs/) 来完成这一任务。
- {{< warning >}}
  必须为缺省的 Service Account 设置以下权限：
  {{< /warning >}}
    - `roles/container.admin`（Kubernetes Engine 管理）
    - `Editor`（缺省打开）

要完成这一设置，需要打开 [Cloud Console](https://console.cloud.google.com/iam-admin/iam/project) 的 **IAM** 模块，查找如下格式的缺省 GCE/GKE Service Account：

`projectNumber-compute@developer.gserviceaccount.com`，缺省情况下，它只包含 `Editor` 角色。对角色进行编辑，在“角色”下拉框中查找 `Kubernetes Engine` 分组，选择角色 `Kubernetes Engine Admin`。

{{< image link="/docs/setup/install/platform/gke/dm_gcp_iam.png" caption="GKE-IAM Service" >}}

加入 `Kubernetes Engine Admin` 角色：

{{< image width="70%" link="/docs/setup/install/platform/gke/dm_gcp_iam_role.png" caption="GKE-IAM Role" >}}

## 在 GKE 上设置 Istio

[Istio on GKE](https://cloud.google.com/istio/docs/istio-on-gke/overview) 文档中，包含了创建支持 Istio 集群的说明，据此进行操作。

集群就绪后，获取该集群的凭据：

    {{< text bash >}}
    $ gcloud container clusters get-credentials <your_cluster> --zone=<your_zone>
    {{< /text >}}

接下来就可以尝试 Istio 的示例了，例如 [Bookinfo](/zh/docs/examples/bookinfo/)。
