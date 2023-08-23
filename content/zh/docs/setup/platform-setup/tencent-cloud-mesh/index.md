---
title: 腾讯云
description: 在腾讯云上快速创建 Istio 服务。
weight: 65
skip_seealso: true
keywords: [platform-setup,tencent-cloud-mesh,tcm,tencent-cloud,tencentcloud]
owner: istio/wg-environments-maintainers
test: n/a
---

## 准备工作 {#prerequisites}

请参考以下的说明为 Istio 搭建一个 [Tencent Kubernetes Engine](https://cloud.tencent.com/product/tke)
或者 [Elastic Kubernetes Service](https://cloud.tencent.com/product/eks) 集群

您可以在腾讯云上基于 [Tencent Kubernetes Engine](https://cloud.tencent.com/document/product/457/32189)
或者 [Elastic Kubernetes Service](https://cloud.tencent.com/document/product/457/39813)
部署一个 Kubernetes 集群，这两种集群都完全支持 Istio 的安装与部署。

{{< image link="./tke.png" caption="创建集群" >}}

## 步骤 {#procedure}

在创建了一个 TKE 或者 EKS 集群之后，您能够在 [Tencent Cloud Mesh](https://cloud.tencent.com/product/tcm)
中快速的部署和使用 Istio。

{{< image link="./tcm.png" caption="创建腾讯服务网格" >}}

1. 登陆到**容器服务**的控制台，然后点击左边导航栏中**服务网格**进入到**服务网格**的页面。

1. 点击左上角的**创建**按钮。

1. 输入 Mesh 的名称。

    {{< tip >}}
    Mesh 的名称可以是长度为1到60的字符，可以包含数字、中文字符、英文字母以及连字符(-)。
    {{< /tip >}}

1. 选择集群所在的**地域**。

1. 选择安装的 Istio 的版本。Tencent Cloud Mesh 支持最新两个重要版本的 Istio 的安装。

1. 选择服务网格的部署模式：**独立网格**或者是**托管网格**。

    {{< tip >}}
    Tencent Cloud Mesh 支持**独立网格模式**，Istiod 在用户集群中运行并由用户自身维护；
    同时也支持**托管网格模式**，Istiod 在托管面中运行并由 Tencent Cloud Mesh 团队维护。
    {{< /tip >}}

1. 配置 Egress 的流量规则：`Register Only` 或者是 `Allow Any`。

1. 选择相关的 **Tencent Kubernetes Engine** 或者 **Elastic Kubernetes Service** 集群。

1. 选择在指定 Namespaces 下开启 Sidecar 自动注入。

1. 配置外部请求绕过 Sidecar 直接访问的 IP 地址块，外部请求流量将无法使用 Istio
   流量管理、可观测性等特性。默认所有外部请求转发至 Sidecar。

1. 选择开启 Sidecar 就绪保障。

    {{< tip >}}
    开启后业务容器将等待 Sidecar 就绪后再启动，将一定程度增加 Pod 启动时长，
    建议对于业务逻辑中有 Sidecar 功能强依赖的服务开启。
    {{< /tip >}}

    {{< image link="./ingress-egress.png" caption="配置 Gateway" >}}

1. 配置边缘代理网关，开启 Ingress Gateway 或者 Egress Gateway。

    {{< image link="./tps.png" caption="配置可观测性服务" >}}

1. 配置 Metrics，Tracing，Logging 相关的可观测性的能力。

    {{< tip >}}
    除了默认的云监控服务外，您能够选择开启高级外部服务，如
    [Prometheus 监控服务](https://cloud.tencent.com/product/tmp)
    和[日志服务](https://cloud.tencent.com/product/cls)。
    {{< /tip >}}

在完成这些步骤，并确认配置创建 Istio 后，就可以开始在 Tencent Cloud Mesh 中使用 Istio 了。
