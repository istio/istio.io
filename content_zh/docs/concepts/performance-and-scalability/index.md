---
title: 性能与可伸缩性
description: 介绍 Istio 组件的性能与可伸缩性方法论、结果和最佳实践。
weight: 50
keywords: [performance,scalability,scale,benchmarks]
---

我们对 Istio 性能评估、跟踪和改进采用四管齐下的方法：

* 代码级微基准测试

* 各种场景下的综合端到端基准测试

* 各种设置下真实复杂应用程序端到端基准测试

* 使用自动化测试以确保性能不会退化

## 微基准测试

我们使用 Go 的原生工具为性能敏感区域编写有针对性的微基准测试。我们使用此方法的主要目标是提供易于使用的微基准测试，开发人员可以凭借这些测试方法对变更进行评估，获取变更前后的性能差异。

查看 Mixer 的[示例微基准测试]({{< github_file >}}/mixer/test/perf/singlecheck_test.go)，以衡量属性处理代码的性能。

开发人员还可以利用黄金文件（golden-file）的方式来捕获源代码树中基准测试结果的状态，以达到保持跟踪和引用的目的。 GitHub 上有该[基线文件]({{< github_file >}}/mixer/test/perf/bench.baseline)。

由于这种测试的性质，机器间的延迟数据可能存在很大差异。建议以这种方式捕获的微基准数据仅与同一台机器上先前运行的数据进行比较。

可以使用 [`perfcheck.sh`]({{< github_file >}}/bin/perfcheck.sh) 脚本快速运行子文件夹中的基准测试并将其结果与相同目录下的基线文件进行对比。

## 测试场景

{{< image width="80%" ratio="75%"
    link="https://raw.githubusercontent.com/istio/istio/master/tools/perf_setup.svg?sanitize=true"
    alt="性能测试场景示意图"
    caption="性能测试场景示意图"
    >}}

描述了综合基准测试场景和测试的源代码托管在 [GitHub]({{< github_blob >}}/tools#istio-load-testing-user-guide) 上。

<!-- add blueperf and more details -->

## 端到端综合基准测试

我们使用 Fortio 作为 Istio 的端到端负载测试工具。Fortio 以特定的每秒查询率（qps）运行，记录执行时间的直方图并计算百分位数（例如 p99，即 99％ 请求的响应时间小于该数值（以秒为单位，SI 单位））。它可以运行一个设定的持续时间段、执行固定数量的请求或直到被中断为止（以一个恒定的目标 QPS，或每个连接/线程的最大速度/负载）。

Fortio 是一个快速、小巧、可重复使用、可嵌入的 go 库以及命令行工具和服务进程，该服务包含一个简单的 Web UI 和结果的图形化表示（同时包含单个延迟图表和多个结果的最小、最大、平均值和百分比图表）。

Fortio 也是 100％ 开源的，除了 go 和 gRPC 之外没有外部依赖，因此您可以轻松地重现我们的所有结果并添加您自己想要探索的变量或场景。

下面是一个在 `istio-0.7.1` 上绘制的，在网格（使用双向 TLS、Mixer 检查和遥测）中的两个服务间以 400 每秒查询率（qps）进行测试的示例场景结果（我们为每个版本运行的 8 个场景之一）的延迟分布图：

<iframe src="https://fortio.istio.io/browse?url=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06.json&xMax=105&yLog=true" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

比较相同情景的 0.6.0 和 0.7.1 直方图/响应时间分布，可以清楚地显示出 0.7 的改进：

<iframe src="https://fortio.istio.io/?xMin=2&xMax=110&xLog=true&sel=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06&sel=qps_400-s1_to_s2-0.6.0-2018-04-05-22-33" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

跟踪该场景所有测试版本的进度：

<iframe src="https://fortio.istio.io/?s=qps_400-s1_to_s2" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

您可以在 GitHub 上了解更多关于 [Fortio](https://github.com/istio/fortio/blob/master/README.md#fortio) 的信息，并在 [https://fortio.istio.io](https://fortio.istio.io) 上查看结果。

## 现实应用程序基准测试

Acmeair（又称 BluePerf）是一个用 Java 实现的客户系统微服务应用程序。此应用程序在 WebSphere Liberty 上运行，并模拟虚拟航空公司的运营。

Acmeair 由以下微服务组成：

* **飞行服务** 检索航线数据。预订服务会调用它来检查奖励操作的里程（Acmeair 客户忠诚度计划）。

* **客户服务** 存储、更新和检索客户数据。认证服务会调用它进行登录，预订服务会调用它进行奖励操作。

* **预订服务** 存储、更新和检索预订数据。

* **认证服务** 如果用户名/密码有效，则生成 JWT。

* **主要服务** 主要包括与其他服务交互的表示层（网页）。这允许用户通过浏览器直接与应用程序交互，但在负载测试期间不会执行此操作。

下图展示了在 Kubernetes/Istio 环境中应用程序的不同 pod/容器：

{{< image ratio="80%"
    link="https://ibmcloud-perf.istio.io/regpatrol/istio_regpatrol_readme_files/image004.png"
    alt="Acmeair 微服务概览"
    >}}

下表展示了回归测试期间由脚本驱动的事务以及请求的近似分布：

{{< image ratio="20%"
    link="https://ibmcloud-perf.istio.io/regpatrol/istio_regpatrol_readme_files/image006.png"
    alt="Acmeair 请求类型和分布"
    >}}

Acmeair 基准测试应用程序可以在这里找到：[IBM's BluePerf](https://github.com/blueperf).

## 自动化测试

综合基准测试（基于 fortio）和方针应用（BluePerf）都是每晚发布管道（nightly release pipeline）的一部分，您可以在此看到结果：

* [https://fortio-daily.istio.io/](https://fortio-daily.istio.io/)
* [https://ibmcloud-perf.istio.io/regpatrol/](https://ibmcloud-perf.istio.io/regpatrol/)

这使我们能够及早发现回归并跟踪一段时间内的改进。

## 可伸缩性和规模调整指南

* 为控制平面组件设置多个副本。

* 设置[水平自动扩展（Horizontal Pod Autoscaling）](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

* 拆分 mixer 中检查和报告的 pod。

* 高可用性（HA）。

* 另请参阅 [Istio 面向性能的常见问题解答](https://github.com/istio/istio/wiki/Istio-Performance-oriented-setup-FAQ)

* 以及[性能和可伸缩性工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#performance-and-scalability)的工作。

当前建议（使用所有 Istio 功能时）：

* 开启访问日志（默认开启）时，为 Sidecar 每分配 1 个 vCPU 能够负担 1000 qps 的访问峰值，没有开启则 0.5 vCPU 即可负担同样峰值，节点上的 `fluentd` 由于需要捕获和上传日志，是主要的性能消耗者。

* 假设 Mixer 检查的典型缓存命中率达到（>80％）：每 1000 qps 需要给 Mixer pod 分配 1 个 vCPU。

* 截至 0.7.1 版本，服务之间的（涉及 2 个代理：Mixer 的遥测和检查）延迟消耗/开销约为 [10 毫秒](https://fortio.istio.io/browse?url=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06.json)，我们希望将其降低到个位数毫秒级别。

* 在 CPU 和延迟方面，AES-NI 硬件支持的双向 TLS 成本可以忽略不计。

我们计划为有意用定制方式部署 Istio 的客户提供更详细的指导。

我们当前的目标是减少将应用程序加入 Istio 的过程中带来的 CPU 开销和延迟。但请注意，如果您的应用程序正自己处理遥测、策略、安全、网络路由、a/b 测试等等，那么所有的代码和随之而来的调用成本都可以被移除，即使不是全部消除，也可以抵消大部分 Istio 带来的延迟。
