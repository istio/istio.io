---
title: 优刻得
description: 在优刻得 Kubernetes 集群进行配置以便安装运行 Istio。
weight: 70
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/ucloud/
    - /zh/docs/setup/kubernetes/platform-setup/ucloud/
keywords: [platform-setup,uk8s,ucloud]
owner: istio/wg-environments-maintainers
test: n/a
---

按照以下说明配置[优刻得 Kubernetes 容器服务(UK8S)](https://docs.ucloud.cn/uk8s/README)集群以便安装运行 Istio。
你可以在优刻得快速简单的部署一个完全支持 Istio 的 Kubernetes 集群。

## 步骤{#procedure}

1. 登陆 [优刻得容器云控制台](https://console.ucloud.cn/uk8s/manage)，并且点击左上角的创建集群按钮。

1. 选择托管版或者专有版。如果选择专有版，需要创建三台Master节点。如果选择托管版，Master节点以及核心组件，例如api-server, etcd, scheduler等都会由UCloud进行管理。

1. 选择集群所在的 **地域** 和 **可用区**。

1. 选择Master（在专有版中）和Node节点配置，或者直接使用默认配置。

1. 设置 **管理员密码**。

1. 点击右上角的 **立即购买** 按钮。

1. 在新弹出的页面点击 **立即支付**按钮。

1. 等待10分钟左右，K8S集群即可正常运行。
