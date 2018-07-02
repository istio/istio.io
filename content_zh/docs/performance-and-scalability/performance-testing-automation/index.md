---
title: 自动化
description: 我们如何确保在不同版本中跟踪和改进或不回退性能。
weight: 50
---

综合基准​​测试（基于 fortio）和真实应用（BluePerf）都是每晚发布管道（nightly release pipeline）的一部分，您可以在此看到结果：

* [https://fortio-daily.istio.io/](https://fortio-daily.istio.io/）
* [https://ibmcloud-perf.istio.io/regpatrol/](https://ibmcloud-perf.istio.io/regpatrol/）

这使我们能够及早发现回归并跟踪一段时间内的改进。