---
title: 阿里云
description: 为 Istio 设置阿里云 Kubernetes 集群的说明。
weight: 3
skip_seealso: true
keywords: [platform-setup,alibaba-cloud,aliyun,alicloud]
---

按照这些说明给 Istio 准备一个阿里云 Kubernetes 的集群。

你可以在阿里云的“容器服务控制台”中快速简单的部署一个 Kubernetes 集群，并且是完全支持 Istio 。

## 前置条件

1. [按照阿里云说明](https://www.alibabacloud.com/help/doc-detail/53752.htm)可以启动以下服务：容器服务、资源编排服务（ROS）和 RAM。

## 步骤

1. 登陆“容器服务控制台”，点击左边导航栏中 **Kubernetes** 下的 **集群** 进入到 **集群列表** 页面。

1. 点击右上角的 **创建 Kubernetes 集群** 按钮。

1. 输入集群名称。集群名称可以是长度为 1–63 个字符，可以包含数字、中文字符、英文字母和 (-) 。

1. 选择集群所在到 **地区** 和 **区域**。

1. 设置集群到网络类型。 Kubernetes 集群现在只支持 VPC 的网络类型。

1. 配置节点类型、按需付费和订阅类型。

1. 配置主节点。为主节点选择版本以及类型。

1. 配置工作节点。选择是否创建工作节点或添加现有 ECS 实例作为工作节点。

1. 配置登录模式，配置 POD 网络 CIDR 和服务 CIDR 。

下图显示了完成前面所有步骤的界面:

{{< image link="/docs/setup/kubernetes/platform-setup/alicloud/csconsole.png" caption="Console" >}}
