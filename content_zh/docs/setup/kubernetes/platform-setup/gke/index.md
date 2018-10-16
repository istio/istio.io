---
title: Google Kubernetes Engine
description: 对 Google Kubernetes Engine（GKE）集群进行配置以便安装运行 Istio。
weight: 9
skip_toc: true
skip_seealso: true
keywords: [platform-setup,kubernetes,gke,google]
---

依照本指南对 GKE 集群进行配置以便安装运行 Istio。

1. 创建一个新集群：

    {{< text bash >}}
    $ gcloud container clusters create <cluster-name> \
      --num-nodes 4
      --zone <zone> \
      --project <project-id>
    {{< /text >}}

1. 为 `kubectl` 获取认证凭据：

    {{< text bash >}}
    $ gcloud container clusters get-credentials <cluster-name> \
        --zone <zone> \
        --project <project-id>
    {{< /text >}}

1. 为了给 Istio 创建 RBAC 规则，需要给当前用户赋予集群管理员权限，因此这里进行授权操作：

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}

