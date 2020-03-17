---
title: 使用 Wasm 运行时的 Telemetry V2（实验性）
description: 如何通过 Wasm 运行时启用 Telemetry V2（实验性）。
weight: 60
---

从 Istio 1.5 开始，默认情况下 Telemetry V2 已启用，并被编译成为 Istio 代理过滤器。相同的过滤器也被编译为了 WebAssembly（Wasm）模块，并随 Istio 代理一起提供。要通过 Wasm 运行时启用 Telemetry V2，请使用 `preview` 配置文件安装 Istio：

{{< text bash >}}
$ istioctl manifest apply --set profile=preview
{{< /text >}}

或者，在使用 `default` 配置文件的情况下，设置以下两个值以启用基于 Wasm 的 Telemetry V2：

{{< text bash >}}
$ istioctl manifest apply --set values.telemetry.v2.metadataExchange.wasmEnabled=true --set values.telemetry.v2.prometheus.wasmEnabled=true
{{< /text >}}

{{< warning >}}
基于 Wasm 的 Telemetry V2 有几个已知的局限性：

* 在 Wasm 模块加载期间（例如在应用上述配置时），代理的 CPU 使用量将激增。增加代理的 CPU 可用资源上限将有助于加快加载速度。
* 代理的基准资源使用率增加。根据初步的性能测试结果，与默认的 Telemetry V2 安装相比，在 Wasm 运行时下运行 Telemetry V2 将使 CPU 用量增加 30％〜50％，内存使用量增加一倍。

在后续版本中，性能将持续改进。
{{</ warning>}}
