---
title: 在网格外部署多个控制平面
subtitle: 网格操作员和网格管理员之间清晰的分离
description: Istio 的新部署模型。
publishdate: 2020-08-27
attribution: "Lin Sun (IBM), Iris Ding (IBM)"
keywords: [istiod,deployment model,install,deploy,'1.7']
---

## 概览{#overview}

根据与不同的服务网格用户和供应商合作的经验，我们认为典型的服务网格有 3 个关键角色：

* 网格操作员，管理服务网格控制平面的安装和升级。

* 网格管理员，通常被称为平台所有者，他拥有服务网格平台，并定义了服务所有者采用服务网格的总体策略和实现。

* 网格用户，通常称为服务所有者，在网格中拥有一个或多个服务。

在 1.7 版本之前，Istio 要求控制平面在网格的一个{{< gloss "primary cluster" >}}主要集群{{< /gloss >}}中运行，导致网格操作员和网格管理员之间没有分离。 Istio 1.7 引入了一个新的{{< gloss "external control plane" >}}外部控制平面{{< /gloss >}}部署模型，该模型允许网格操作人员在单独的外部集群上安装和管理网格控制平面。这种部署模型允许网格操作员和网格管理员之间的明确分离。Istio 网格操作员现在可以为网格管理员运行 Istio 控制平面，而网格管理员仍然可以控制控制平面的配置，而不必担心安装或管理控制平面。这个模型对网格用户是透明的。

## 外部控制平面部署模型{#external-control-plane-deployment-model}

使用[默认安装配置文件](/zh/docs/setup/install/istioctl/#install-istio-using-the-default-profile)安装 Istio 后，您将在单个集群中安装一个 Istiod 控制平面，如下图所示：

{{< image width="100%"
    link="single-cluster.svg"
    alt="单集群中的 Istio 网格"
    title="单集群中的 Istio 网格"
    caption="单集群中的 Istio 网格"
    >}}

使用 Istio 1.7 中的新部署模型，可以在外部集群上运行 Istiod，与网格服务分离，如下图所示。外部控制平面集群由网格操作员拥有，而网格管理员拥有运行部署在网格中的服务的集群。网格管理员无法访问外部控制平面集群。网格操作人员可以遵循[外部 istiod 单集群逐步指南](https://github.com/istio/istio/wiki/External-Istiod-single-cluster-steps)来进一步探索这方面的内容。(注意：在 Istio 维护者之间的一些内部讨论中，这个模型以前被称为“中心 istiod”。)

{{< image width="100%"
    link="single-cluster-external-Istiod.svg"
    alt="外部带有 Istiod 的单群集 Istio 网格"
    title="外部带有 Istiod 的单群集 Istio 网格"
    caption="外部控制平面集群中带有 Istiod 的单个群集 Istio 网格"
    >}}

网格管理员可以将服务网格扩展到多个集群，这些集群由运行在外部集群中的相同 Istiod 管理。 在这种情况下，没有一个网格集群是{{< gloss "primary cluster" >}}主要集群{{< /gloss >}}。它们都是{{< gloss "remote cluster" >}}远程集群{{< /gloss >}}。但是，除了运行服务外，其中一个还充当 Istio 配置集群。外部控制平面从 `config cluster` 读取 Istio 配置，而 Istiod 将配置推送到在配置集群和其他远程集群中运行的数据平面，如下图所示。

{{< image width="100%"
    link="multiple-clusters-external-Istiod.svg"
    title="外部带有 Istiod 的多集群 Istio 网格"
    caption="外部控制平面集群中具有 Istiod 的多集群 Istio 网格"
    >}}

网格操作员可以进一步扩展这种部署模型，从运行多个 Istio 控制平面的外部集群管理多个 Istio 控制平面：

{{< image width="100%"
    link="multiple-external-Istiods.svg"
    alt="外部带有 Istiod 的单集群 Istio 网格"
    title="外部带有 Istiod 的多个单集群 Istio 网格"
    caption="外部控制平面集群中具有多个 Istiod 控制平面的多个单集群"
    >}}

在这种情况下，每个 Istiod 管理自己的远程集群。网格操作人员甚至可以在外部控制平面集群中安装自己的 Istio 网格，并配置 `istio-ingress` 网关，将通信从远程集群路由到相应的 Istiod 控制平面。 想要了解更多，请查看[这些步骤](https://github.com/istio/istio/wiki/External-Istiod-single-cluster-steps#deploy-istio-mesh-on-external-control-plane-cluster-to-manage-traffic-to-istiod-deployments)。

## 结论{#conclusion}

外部控制平面部署模型使 Istio 控制平面能够由具有 Istio 操作专长的网格操作人员运行和管理，并在服务网格控制和数据平面之间提供了清晰的分离。 网格操作人员可以在自己的集群或其他环境中运行控制平面，将控制平面作为服务提供给网格管理员。网格操作人员可以在单个集群中运行多个 Istiod 控制平面，部署自己的 Istio 网格，并使用 `istio-ingress` 网关来控制对这些 Istiod 控制平面的访问。通过本文提供的示例，网格操作人员可以探索不同的实现选择并选择最适合自己的方法。

这种新模型允许网格管理员只关注网格配置而不操作控制平面，从而降低了网格管理员的复杂性。网格管理员可以继续配置网格范围的设置和 Istio 资源，而不需要访问任何外部控制平面集群。网格用户可以继续与服务网格交互，而无需进行任何更改。
