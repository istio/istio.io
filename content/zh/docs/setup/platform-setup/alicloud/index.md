---
title: 阿里云
description: 在阿里云 Kubernetes 集群进行配置以便安装运行 Istio。
weight: 5
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/alicloud/
    - /zh/docs/setup/kubernetes/platform-setup/alicloud/
keywords: [platform-setup,alibaba-cloud,aliyun,alicloud]
owner: istio/wg-environments-maintainers
test: n/a
---

此页面最新更新时间 2018年8月8日。

{{< boilerplate untested-document >}}

按照以下说明配置[阿里云 Kubernetes 容器服务](https://www.alibabacloud.com/zh/product/kubernetes)集群以便安装运行 Istio。
您可以在阿里云的 **容器服务管理控制台** 中快速简单地部署一个完全支持 Istio 的 Kubernetes 集群。

{{< tip >}}
阿里云提供了一个完全托管的服务网格平台，名为阿里云服务网格（ASM），与 Istio 完全兼容。有关详细信息和说明，请参阅[阿里云服务网格](https://www.alibabacloud.com/help/zh/alibaba-cloud-service-mesh/latest/what-is-asm)。
{{< /tip >}}

## 前置条件{#prerequisites}

1. 按照[阿里云说明](https://www.alibabacloud.com/help/zh/container-service-for-kubernetes/latest/create-an-ack-managed-cluster)启用以下服务：容器服务、资源编排服务（ROS）和 RAM。

## 步骤{#procedure}

1. 您登录 `容器服务管理控制台`，点击左边导航栏中 **Kubernetes** 下的 **集群** 进入到 **集群列表** 页面。

1. 点击右上角的 **创建 Kubernetes 集群** 按钮。

1. 输入集群名称。集群名称可以是长度为 1–63 个字符，可以包含数字、中文字符、英文字母和连字符 (-)。

1. 选择集群所在的 **region** 和 **zone**。

1. 设置集群网络类型。Kubernetes 集群现在只支持 VPC 的网络类型。

1. 配置节点类型。支持按量付费和包年包月。

1. 配置主节点。为主节点选择实例规格。

1. 配置工作节点。选择是否创建工作节点或添加现有 ECS 实例作为工作节点。

1. 配置登录模式，配置 Pod 的网络 CIDR 和 Service CIDR。

下图显示了完成前面所有步骤的界面：

{{< image link="./csconsole.png" caption="Console" >}}
