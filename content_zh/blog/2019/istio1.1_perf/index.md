---
title: 面向性能而架构的 Istio 1.1
description: Istio 1.1 性能概览.
publishdate: 2019-03-18
subtitle: Istio 1.1 性能改进概览
attribution: Surya V Duggirala (IBM), Mandar Jog (Google), Jose Nativio (IBM)
keywords: [performance,scalability,scale,benchmarks]
---

构建一个超大规模的基于微服务的云环境一直令人非常兴奋，但却难于管理。自从 2014 年出现 Kubernetes (容器编排引擎)，随后在 2017 年出现 Istio (容器服务管理)，这两个开源项目让开发者无需在管理上耗费太多时间即可扩展基于容器的应用程序。

现在，Istio 1.1 新的增强功能带来了改进的应用性能和服务管理效率。相比于 Istio 1.0，使用我们的示例商业航班预订程序的模拟显示出了如下改进。

我们看到大量的应用程序性能提升:

* 应用程序平均延迟降低 30％
* 在大型网格中服务启动时间快 40％

同样还有服务管理效率的显著提升:

* 在大型网格中，Pilot 的 CPU 使用率降低了 90％
* 在大型网格中，Pilot 的内存使用率降低了 50％

使用 Istio 1.1，企业会对一致性和可控的应用程序扩展能力更加自信 —— 即使在超大规模的云环境中也无所畏惧。

祝贺那些来自世界各地的为此次版本发布做出贡献的 Istio 专家。我们对这些结果无比高兴。

## Istio 1.1 性能增强

作为 Istio Performance and Scalability （性能和可伸缩）工作组的成员，我们进行了广泛的性能评估。我们与其他 Istio 贡献者合作，为 Istio 1.1 引入了许多旨在提高性能的新特性。1.1 中一些显著的性能增强包括:

* Envoy 生成统计数据的默认集合显著减少
* 为 Mixer 工作负载添加了减载特性
* 改进了 Envoy 和 Mixer 之间的协议
* 隔离命名空间以减少操作开销
* 可配置的并发工作线程，可以提高整体吞吐量
* 为限制遥测数据的可配置过滤器
* 解除同步瓶颈

## 持续的代码质量和性能验证

回归巡检促进了 Istio 性能和质量的不断提高，在幕后帮助 Istio 开发者识别并修正代码错误。每天的构建都会经过以客户为中心的性能基准 [BluePerf](https://github.com/blueperf/) 的性能检测。测试结果会展示在 [Istio 社区门户网站](https://ibmcloud-perf.istio.io/regpatrol/)。评估了各种应用配置以帮助洞悉 Istio 组件的性能。

另一个用于评估 Istio 构建性能的工具是 [Fortio](https://fortio.org/)，它提供了一个综合的端到端的压力测试基准。

## 概要

Istio 1.1 旨在提高性能和可扩展性。Istio Performance and Scalability （性能和可扩展性）工作组实现了自 1.0 以来显著的性能改进。
Istio 1.1 提供的新特性和功能优化，提高了服务网格对企业工作负载的支撑能力。Istio 1.1 性能和调优指南记录了性能模拟，提供了调整和容量规划指导，并包含了调优客户用例的最佳实践。

## 有用的链接

* [Istio 服务网格性能 (34:30)](https://www.youtube.com/watch?time_continue=349&v=G4F5aRFEXnU), 作者：Surya Duggirala, Laurent Demailly 和 Fawad Khaliq 于 Kubecon Europe 2018
* [Istio 性能和可扩展性讨论专题](https://discuss.istio.io/c/performance-and-scalability)

## 免责声明

这里展示的性能数据是在一个可控的隔离环境中产生的。在其他环境中获得的实际结果可能存在较大差异。无法保证在其他地方获得相同或类似的结果。
