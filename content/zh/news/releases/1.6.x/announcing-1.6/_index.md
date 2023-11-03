---
title: 发布 Istio 1.6
linktitle: 1.6
subtitle: Major Update
description: Istio 1.6 发布公告。
publishdate: 2020-05-21
release: 1.6.0
skip_list: true
aliases:
    - /zh/news/announcing-1.6.0
    - /zh/news/announcing-1.6
---

我们很高兴地宣布发布 Istio 1.6！

{{< relnote >}}

在此版本中，
我们延续了今年早些时候在[路线图](/zh/blog/2020/tradewinds-2020/)中绘制的路径，
朝着更简单、更好的安装体验的方向前进，并且我们还添加了其他优势改进。

以下是今天发布的一些内容：

## 简化，简化，再简化{#simplify-simplify-simplify}

上一个版本中，我们引入了 **Istiod**，这是一个新模块，
它通过组合多个服务的功能来减少 Istio 安装中的组件数量。
在 Istio 1.6 中，我们已经完成了这一转变，
并将所有功能完全迁移到了 Istiod 中。这使我们能够删除
Citadel、Sidecar 注入器和 Galley 的独立部署。

好消息！我们为使用 Kubernetes 中新的 alpha 功能的开发人员提供了简化的体验。
如果您在 Kubernetes [`EndpointPort`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#endpointport-v1beta1-discovery-k8s-io)
或 [`ServicePort`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#serviceport-v1-core)
API 中使用新的 `appProtocol` 字段（这是 1.18 中的 Alpha 版本功能），
您将不再需要在您的 `Service` 中附加名称字段以表示协议。

## 更好的生命周期{#better-lifecycle}

我们继续让安装和升级 Istio 获得更好的体验。
我们的命令行工具 `istioctl` 提供了更好的诊断信息，
具有更简单的安装命令，甚至还提供了状态信息的多种颜色显示！

升级 Istio 也以多种强大的方式得到了改进。
首先，我们现在支持 Istio 控制平面本身的金丝雀发布。
这意味着您可以在现有版本的基础上安装新版本的控制平面，
并有选择地让代理使用新版本。
查看此[博客文章](/zh/blog/2020/multiple-control-planes/)了解更多详细信息。

我们还有一个 `istioctl upgrade` 命令，
它将在您的集群中执行原地升级（仍然将控制代理自身更新的权力留给您）。

查看[文档](/zh/docs/setup/upgrade/)，
了解有关新升级体验的所有详细信息。

## 观测{#observe-this}

许多公司采用 Istio 只是为了获得更好的分布式应用程序可观察性，
因此我们将继续在此进行投入。由于更改太多，无法在此处一一列举，
请参阅[发布说明](/zh/news/releases/1.6.x/announcing-1.6/change-notes/)了解完整详细信息。一些亮点：您将看到更多的可配置性、
更好的控制跟踪采样率的能力，以及更新的 Grafana
仪表盘（我们甚至在 [Istio 组织页面](https://grafana.com/orgs/istio)上的
[Grafana](https://grafana.com) 中发布了它们）。

## 针对虚拟机的更好支持{#better-virtual-machine-support}

扩大对不在 Kubernetes 中运行的工作负载的支持是我们
2020 年的主要投入领域之一，我们很高兴在这里宣布一些重大进展。

使用新的 [`WorkloadEntry`](/zh/docs/reference/config/networking/workload-entry/)
资源对于需要将非 Kubernetes 工作负载添加到网格（例如，部署在 VM
上的工作负载）的人来说，比之前的任何时候都更加简单。
我们创建此 API 是为了在 Istio 中为非 Kubernetes
工作负载提供一流的表现。它将虚拟机或裸金属工作负载提升到与
Kubernetes `Pod` 相同的级别，而不仅仅是具有 IP 地址的端点。
您现在甚至可以定义 Pod 和 VM 并存的 Service。
为什么这是有用的呢？因为您现在可以为同一服务实现混合部署（VM 和 Pod），
这提供了一种将 VM 工作负载迁移到 Kubernetes
集群的好方法，而不是通过中断其进出站流量来实现。

基于 VM 的工作负载仍然是我们的重中之重，
您可以期待在即将发布的版本中看到更多该领域的内容。

## 网络改进{#networking-improvements}

网络是服务网格的核心，因此我们也加入了一些很棒的流量管理功能。
Istio 改进了对 Secret 的处理，从而为 Kubernetes Ingress
提供了更好的支持。我们还默认启用了 Gateway SDS，
以获得更安全的体验。我们还添加了对 Kubernetes Service API
的实验性支持（依然是实验性的）。

## 加入 Istio 社区{#join-the-Istio-community}

与往常一样，很多事情都发生在[社区会议](https://github.com/istio/community#community-meeting)；
每隔一个星期四的太平洋时间上午 11 点加入我们。
我们希望您可以通过 [Istio Discuss](https://discuss.istio.io)
加入对话，此外，也可以加入我们的
[Slack 频道](https://istio.slack.com)。

我们很荣幸成为 GitHub [成长最快](https://octoverse.github.com/#top-and-trending-projects)的五个开源项目之一。
想参与其中吗？加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一，
帮助我们使 Istio 变得更好。
