---
title: Mixer 适配器模型
description: 概要说明 Mixer 的插件架构。
publishdate: 2017-11-03
subtitle: 将 Istio 与后端基础设施整合
attribution: Martin Taillefer
weight: 95
keywords: [适配器,mixer,策略,遥测]
---

Istio 0.2 引入了一种新的 Mixer 适配器模型，这种模型使接入后端基础设施具有更多的灵活性 。本文将解释这种模型是如何工作的。

## 为什么是适配器模型?

后端基础设施提供了支持服务构建的功能。他们包括访问控制、遥测、配额控制、计费系统等等。传统服务会直接与这些后端系统集成，并与后端紧密耦合，并集成到其中的个性化语义和操作。

Mixer 服务作为 Istio 和一套开放式基础设施之间的抽象层。Istio 组件和运行在 Service Mesh 中的服务，通过 Mixer 就可以在不直接访问后端接口的情况下和这些后端进行交互。

除了作为应用层与基础设施隔离外，Mixer 提供了一种中介模型，这种模型允许注入和控制应用和后端的策略。操作人员可以控制哪些数据汇报给哪个后端，哪个后端提供授权等等。

考虑到每个基础服务都有不同的接口和操作模型，Mixer 需要用户通过代码来解决这些差异，我们可以称这些用户自己封装的代码为[*适配器*](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide)。

适配器以 Go 包的形式直接链接到 Mixer 二进制中。如果默认的适配器不能满足特定的使用需求，自定义适配器也是很简单的。

## 设计哲学

Mixer 本质上就是一个处理属性和路由的机器。代理将[属性](/zh/docs/concepts/policies-and-telemetry/#属性)作为预检和遥测报告的一部分发送出来，并且转换为一系列对适配器的调用。运维人员提供了用于描述如何将传入的属性映射为适配器的配置。

{{< image width="60%" ratio="42.60%"
    link="/docs/concepts/policies-and-telemetry/machine.svg"
    caption="Attribute Machine"
    >}}

配置是一个复杂的任务。有证据表明绝大多数服务中断是由配置错误造成的。为了帮助解决这一问题，Mixer 的配置模型通过做限制来避免错误。例如，在配置中使用强类型，以此来确保在上下文环境中使用了有意义的属性或者属性表达式。

## Handlers: 适配器的配置

Mixer 使用的每个适配器都需要一些配置才能运行。一般来说，适配器需要一些信息。例如，到后端的 URL 、证书、缓存选项等等。每个适配器使用一个 [protobuf](https://developers.google.com/protocol-buffers/) 消息来定义所需要的配置数据。

你可以通过创建 [*handler*](/zh/docs/concepts/policies-and-telemetry/#处理器-handler) 为适配器提供配置。Handler 就是一套能让一个适配器就绪的完整配置。对同一个适配器可以有任意数量的 Handler，这样就可以在不同的场景下复用了。

## Templates: 适配输入结构

通常对于进入到 Mesh 服务中的请求，Mixer 会发生两次调用，一次是预检，一次是遥测报告。每一次调用，Mixer 都会调用一个或更多的适配器。不同的适配器需要不同的数据作为输入来处理。例如，日志适配器需要日志输入，metric 适配器需要 metric 数据作为输入，认证的适配器需要证书等等。Mixer [*templates*](/docs/reference/config/policy-and-telemetry/templates/) 用来描述每次请求适配器消费的数据。

每个 Template 被指定为 [protobuf](https://developers.google.com/protocol-buffers/) 消息。一个模板描述了一组数据，这些数据在运行时被传递给一个或多个适配器。一个适配器可以支持任意数量的模板，开发者还可以设计支持特定模板的是适配器。

[`metric`](/docs/reference/config/policy-and-telemetry/templates/metric/) 和 [`logentry`](/docs/reference/config/policy-and-telemetry/templates/logentry/) 是两个最重要的模板，分别表示负载的单一指标，和到适当后端的单一日志条目。

## Instances: 属性映射

你可以通过创建 [*instances*](/zh/docs/concepts/policies-and-telemetry/#实例-instance) 来决定哪些数据被传递给特定的适配器。Instances 决定了 Mixer 如何通过 [attributes](/zh/docs/concepts/policies-and-telemetry/#属性) 把来自代理的属性拆分为各种数据然后分发给不同的适配器。

创建实例通常需要使用 [attribute expressions](/zh/docs/concepts/policies-and-telemetry/#属性表达式) 。这些表达式的功能是使用属性和常量来生成结果数据，用于给instance字段进行赋值。

在模板中定义的每个 instance 字段、每个属性、每个表达式都有一个 [type](https://github.com/istio/api/blob/master/policy/v1beta1/value_type.proto)，只有兼容的数据类型才能进行赋值。例如不能把整型的表达式赋值给字符串类型。强类型设计的目的就是为了降低配置出错引发的风险。

## Rules: 将数据交付给适配器

最后一个问题就是告诉 Mixer 哪个 instance 在什么时候发送给哪个 handler。这个通过创建 [*rules*](/zh/docs/concepts/policies-and-telemetry/#规则-rule) 实现。每个规则都会指定一个特定的处理程序和要发送给该处理程序的示例。当 Mixer 处理一个调用时，它会调用指定的处理程序，并给他一组特定的处理实例。

Rule 中包含有匹配断言，这个断言是一个返回布尔值的属性表达式。只有属性表达式断言成功的 Rule 才会生效，否则这条规则就形同虚设，当然其中的 Handler 也不会被调用。

## 未来的工作

我们正在努力改进和提升适配器的使用及开发。例如，计划中包含很多新特性使用户更加方便地使用 Templates。另外，表达式语言也正在不断的发展和成熟。

长远来看，我们正在寻找不直接将适配器直接连接到 Mixer 二进制的方法。这将简化部署和开发使用。

## 结论

新的 Mixer 适配器模型的设计是为了提供一个灵活的框架用来支持一个开放基础设施。

Handler 为各个适配器提供了配置数据，Template 用于在运行时确定不同的适配器所需的数据类型，Instance 让运维人员准备这些数据，Rule 将这些数据提交给一个或多个 Handler 进行处理。

更多信息可以关注[这里](/zh/docs/concepts/policies-and-telemetry/)。更多关于 templates, handlers,和 rules 的内容可以关注[这里](/docs/reference/config/policy-and-telemetry/)。你也可以在[这里]({{< github_tree >}}/samples/bookinfo)找到对应的示例。
