---
title: 基于 Wasm 的遥测[实验特性]
description: 如何使用 Wasm 进行遥测。
weight: 60
owner: istio/wg-policies-and-telemetry-maintainers
test: no
aliases:
    - /zh/docs/reference/config/telemetry/telemetry_v2_with_wasm/
---

默认情况下，遥测生成特性作为 Istio 代理启用。同时也被编译成 WebAssembly (Wasm) 模块，并随 Istio 代理一起发布。

{{< text bash >}}
$ istioctl install --set profile=preview
{{< /text >}}

或者，设置以下两个参数，使用 `default` 配置文件启用基于 Wasm 的遥测技术:

{{< text bash >}}
$ istioctl install --set values.telemetry.v2.metadataExchange.wasmEnabled=true --set values.telemetry.v2.prometheus.wasmEnabled=true
{{< /text >}}

{{< warning >}}
基于 Wasm 的遥测技术存在几个已知的局限性:

* 代理 CPU 的使用将在 Wasm 模块加载阶段(例如：当上述配置被应用时)达到高峰。增加代理 CPU 资源限制将有助于加速加载。
* 当代理基线资源使用增加时，根据初步的性能测试结果运行基于 Wasm 的遥测要比默认安装环境多花费30%~50%的 CPU，并使内存使用量增加一倍。

性能将在接下来的版本中不断改进。
{{</ warning>}}
