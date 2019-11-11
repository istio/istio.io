---
title: 阿里云
description: 对阿里云 Kubernetes 集群进行配置以便安装运行 Istio。
weight: 3
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/alicloud/
    - /zh/docs/setup/kubernetes/platform-setup/alicloud/
keywords: [platform-setup,alibaba-cloud,aliyun,alicloud]
---

按照以下说明配置
[阿里云 Kubernetes 容器服务](https://www.alibabacloud.com/product/kubernetes)
集群以便安装运行 Istio。
你可以在阿里云的 **容器服务管理控制台** 中快速简单的部署一个完全支持 Istio 的 Kubernetes 集群。

{{< tip >}}
你也可以按照
[阿里云应用目录说明](https://archive.istio.io/v1.1/docs/setup/kubernetes/install/platform/alicloud/)
在阿里云 Kubernetes 容器服务中使用 **应用目录** 服务来安装配置 Istio。
{{< /tip >}}

## 前置条件{#prerequisites}

1. [按照阿里云说明](https://www.alibabacloud.com/help/doc-detail/53752.htm)启用以下服务：容器服务、资源编排服务（ROS）和 RAM。

## 步骤{#procedure}

1. 登陆 **容器服务管理控制台** ，点击左边导航栏中 **Kubernetes** 下的 **集群** 进入到 **集群列表** 页面。

1. 点击右上角的 **创建 Kubernetes 集群** 按钮。

1. 输入集群名称。集群名称可以是长度为 1–63 个字符，可以包含数字、中文字符、英文字母和连字符 (-) 。

1. 选择集群所在到 **region** 和 **zone**。

1. 设置集群网络类型。Kubernetes 集群现在只支持 VPC 的网络类型。

1. 配置节点类型。支持按量付费和包年包月。

1. 配置主节点。为主节点选择实例规格。

1. 配置工作节点。选择是否创建工作节点或添加现有 ECS 实例作为工作节点。

1. 配置登录模式，配置 POD 网络 CIDR 和 Service CIDR 。

下图显示了完成前面所有步骤的界面:

{{< image link="./csconsole.png" caption="Console" >}}
