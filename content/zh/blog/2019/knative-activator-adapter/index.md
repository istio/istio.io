---
title: 适用于 Knative 的 Mixer 适配器
subtitle: 本文演示 Mixer 进程外适配器实现 Knative scale-from-zero 逻辑的具体过程
description: 本文演示 Mixer 进程外适配器实现 Knative scale-from-zero 逻辑的具体过程。
publishdate: 2019-09-18
attribution: Idan Zach （IBM）
keywords: [mixer,adapter,knative,scale-from-zero]
target_release: 1.3
---

这篇文章演示了如何使用 [Mixer](/zh/faq/mixer/) 把应用逻辑放进 Istio。它描述了一个用简单的代码实现了 Knative scale-from-zero 逻辑的 Mixer 适配器，该适配器和原有实现的性能相差无几。

## Knative serving{#Knative-serving}

[Knative Serving](https://knative.dev/docs/serving/) 基于 [Kubernetes](https://kubernetes.io/) 来支持 serverless 应用的部署和服务（serving）。一个 serverless 平台的核心功能就是 scale-to-zero，该功能可减少非活动工作负载的资源使用量和成本。当空闲应用收到新请求时，需要一种新的机制来 scale-from-zero。

下图表示当前 Knative scale-from-zero 的架构。

{{< image width="60%" link="knative-activator.png" caption="Knative scale-from-zero" >}}

通过配置 Istio 中的 `VirtualServices` 和 `DestinationRules` 可以将空闲应用的流量重定向到 **Activator** 组件。当 **Activator** 接受新请求的是时候，它：

1. 缓存进来的请求
1. 触发 **Autoscaler**
1. 在应用扩容了之后把请求重定向到该应用，包括重试和负载均衡（如果需要的话）

一旦应用启动并再次运行，Knative 就会把请求路由到正在运行的应用上（之前请求是路由到 **Activator** 的）。

## Mixer 适配器{#mixer-adapter}

[Mixer](/zh/faq/mixer/) 在 Istio 组件和基础设施后端之间提供了一个丰富的中介层。它是独立于 [Envoy](https://www.envoyproxy.io/) 的组件，并且具有简单的可扩展性模型，该扩展模型使 Istio 可以与大部分后端进行交互。Mixer 本质上比 Envoy 更容易扩展。

Mixer 是一个属性处理引擎，它使用面向操作员（operator-supplied）的配置通过可插拔（pluggable）的适配器将 Istio 代理的请求属性映射到对基础设施后端系统的调用。适配器使 **Mixer** 暴露单个一致的 API，与使用中的基础设施后端无关。运行时使用的适配器是由操作员配置决定的，适配器可以轻松扩展以适应新的或定制的基础设施后端。

为了实现 Knative scale-from-zero，我们使用 Mixer [进程外适配器](https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Dev-Guide)来调用 Autoscaler。Mixer 的进程外适配器使开发人员可以使用任何编程语言，并以独立程序的形式构建和维护您的扩展程序，而无需构建 Istio 代理。

下图表示使用 **Mixer** 适配器的 Knative 设计。

{{< image width="60%" link="knative-mixer-adapter.png" caption="Knative scale-from-zero" >}}

在这种设计中，无需像 Knative 原有的设置中那样为空闲应用程序更改到 **Activator** 的路由。当由 Istio 代理（ingress gateway）收到对空闲应用程序的新请求时，它将通知 Mixer，包括所有相关的元数据信息。然后 Mixer 调用您的适配器，该适配器使用 Knative 原有的协议触发 Knative Autoscaler。

{{< idea >}}
通过使用这种设计，您不需要处理缓存，重试和负载平衡，因为 Istio 代理已经处理了这些。
{{< /idea >}}

Istio 的 Mixer 适配器模式使得我们可以用更简单的方式实现原本复杂并且基于网络的应用逻辑，如 [Knative 适配器](https://github.com/zachidan/istio-kactivator)中所示。

当适配器从 Mixer 接收到消息时，它会使用 Knative 协议直接向 Autoscaler 发送一个 `StatMessage`。Istio 代理将 **Autoscaler** 所需的元数据信息（`namespace` 和 `service name`）传输到 Mixer，再从那里传输到适配器。

## 总结{#summary}

我将 Knative 原有的参考架构的冷启动（cold-start）时间与新的 Istio Mixer 适配器参考架构进行了比较。结果显示它们的冷启动时间很接近。使用 Mixer 适配器的实现更加简单。无需处理基于底层网络的机制，因为这些机制是由 Envoy 处理的。

下一步是把这个 Mixer 适配器放到一个特定的 Envoy（Envoy-specific）过滤器中，该过滤器是在 ingress gateway 内运行。这将进一步改善响应时间（不再调用 **Mixer** 和适配器），并消除对 Istio Mixer 的依赖。
