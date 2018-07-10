---
title: 可伸缩性和规模调整指南
description: Istio 组件安装的水平伸缩、高可用及规模调整指南。
weight: 60
---

* 为控制平面组件设置多个副本。

* 设置 [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

* 拆分 mixer 中检查和报告的 pod。

* 高可用性（HA）。

* 另请参阅 [Istio 面向性能的常见问题解答](https://github.com/istio/istio/wiki/Istio-Performance-oriented-setup-FAQ)

* 以及 [性能和可伸缩性工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#performance-and-scalability) 的工作。

当前建议（使用所有 Istio 功能时）：

* 开启访问日志（默认开启）时，每秒峰值请求每达 1000 为 sidecar 配置 1 vCPU，没有开启则配置 0.5 vCPU，节点上的 `fluentd` 由于需要捕获和上传日志，是主要的性能消耗者。

* 假设 mixer 的典型高速缓存命中率（>80％）：每秒峰值请求每达 1000 为mixer pod 配置 0.5 vCPU。

* 截至 0.7.1 版本，service-service（涉及 2 个代理，mixer telemetry 和检查）延迟消耗/开销约为 [10毫秒](https://fortio.istio.io/browse?url=qps_400-s1_to_s2-0.7.1-2018-04-05-22-06.json)，我们希望将其降低到个位数毫秒级别。

* 在 CPU 和延迟方面，AES-NI 硬件支持的 mTLS 成本可以忽略不计。

我们计划为采用 Istio “点菜（A la carte）” 的客户提供更详细的指导。

2018 年 Istio 的目标是减少 CPU 开销和将 Istio 添加到您的应用程序带来的延迟，但请注意，如果您的应用程序正自己处理 telemetry，策略，安全，网络路由，a/b 测试等等......则所有的代码和调用成本都可以被移除，并且，即使不是全部，也可以抵消大部分 Istio 的延迟。
