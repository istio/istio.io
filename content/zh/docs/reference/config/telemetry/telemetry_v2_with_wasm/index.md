---
title: 使用Wasm运行时的Telemetry V2（实验性）
description: 如何通过Wasm运行时启用Telemetry V2（实验性）。
weight: 60
---

从Istio 1.5开始，默认情况下Telemetry V2已启用，并被编译成为Istio代理过滤器。 相同的过滤器也被编译为了WebAssembly（Wasm）模块，并随Istio代理一起提供。 要通过Wasm运行时启用Telemetry V2，请使用`preview`配置文件安装Istio：

{{< text bash >}}
$ istioctl manifest apply --set profile=preview
{{< /text >}}

或者，在使用`default`配置文件的情况下，设置以下两个值以启用基于Wasm的Telemetry V2：

{{< text bash >}}
$ istioctl manifest apply --set values.telemetry.v2.metadataExchange.wasmEnabled=true --set values.telemetry.v2.prometheus.wasmEnabled=true
{{< /text >}}

{{< warning >}}
基于Wasm的Telemetry V2有几个已知的局限性：

* 在Wasm模块加载期间（例如在应用上述配置时），代理的CPU使用量将激增。 增加代理的CPU可用资源上限将有助于加快加载速度。
* 代理的基准资源使用率增加。 根据初步的性能测试结果，与默认的Telemetry V2安装相比，在Wasm运行时下运行Telemetry V2将使CPU用量增加30％〜50％，内存使用量增加一倍。

在后续版本中，性能将持续改进。
{{</ warning>}}
