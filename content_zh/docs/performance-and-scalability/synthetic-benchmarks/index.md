---
title: 合成端到端基准测试
description: Fortio 是我们简单合成 http 和 grpc 基准测试工具.
weight: 30
---

我们使用 Fortio（Φορτίο）作为 Istio 的合成端到端负载测试工具。Fortio 以特定的每秒查询率（qps）运行，记录执行时间的直方图并计算百分位数（例如 p99，即 99％ 请求的响应时间小于该数值（以秒为单位，SI单位））。它可以运行一段设定的持续时间、固定数量的请求或直到被中断为止（以一个恒定的目标 QPS，或每个连接/线程的最大速度/负载）。

Fortio 是一个快速、小巧、可重复使用、可嵌入的 go 库以及命令行工具和服务进程，该服务包含一个简单的 Web UI 和结果的图形化表示（同时包含单个延迟图表和多个结果的最小、最大、平均值和百分比图表）。

Fortio 也是 100％ 开源的，除了 go 和 gRPC 之外没有外部依赖，因此您可以轻松地重现我们的所有结果并添加您自己想要探索的变量或场景。

下面是一个在 istio-0.7.1 上绘制的，在网格（使用 mTLS，Mixer 检查和遥测）中的两个服务间以 400 每秒查询率（qps）进行测试的示例场景结果（我们为每个版本运行的 8 个场景之一）的延迟分布图：

<iframe src="https://fortio.istio.io/browse?url=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06.json&xMax=105&yLog=true" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

比较相同情景的 0.6.0 和 0.7.1 直方图/响应时间分布，可以清楚地显示出 0.7 的改进：

<iframe src="https://fortio.istio.io/?xMin=2&xMax=110&xLog=true&sel=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06&sel=qps_400-s1_to_s2-0.6.0-2018-04-05-22-33" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

跟踪该场景所有测试版本的进度：

<iframe src =“https://fortio.istio.io/?xMin=2&xMax=110&xLog=true&sel=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06&sel=qps_400-s1_to_s2-0.6.0- 2018-04-05-22-33“width =”100％“height =”1024“scrolling =”no“frameborder =”0“> </ iframe>

<iframe src="https://fortio.istio.io/?s=qps_400-s1_to_s2" width="100%" height="1024" scrolling="no" frameborder="0"></iframe>

您可以在 GitHub 上了解更多关于 [Fortio](https://github.com/istio/fortio/blob/master/README.md#fortio) 的信息，并在 [https://fortio.istio.io](https//fortio.istio.io) 上查看结果。
