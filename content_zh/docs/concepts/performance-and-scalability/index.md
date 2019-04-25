---
title: 性能与可伸缩性
description: 介绍 Istio 组件的性能与可伸缩性。
weight: 50
keywords: [performance,scalability,scale,benchmarks]
---

Istio 在不侵入应用代码的情况下，在应用服务之间创建了具备丰富的路由能力、负载均衡、服务间认证、监控等功能的网络。Istio 的目标是使用最小资源开销来提供这些能力，并能够为负载大量请求的大规模集群提供低延迟服务。

Envoy 作为 Istio 的数据平面组件，在系统中负责数据流的处理。Istio 控制面组件包括 Pilot、Galley 和 Citadel，负责对数据平面进行控制。数据平面和控制平面在性能方面有着不同的侧重点。

## Istio {{< istio_release_name >}} 性能概述

[Istio 负载测试](https://github.com/istio/tools/tree/master/perf/load)网格由 **1000** 个服务和 **2000** 个 Sidecar 组成，每秒钟产生 70,000 个网格范围内的请求。在使用 Istio {{< istio_release_name >}} 完成测试之后，我们获得了以下结果：

- Envoy 在每秒处理 1000 请求的情况下，使用 **0.6 个 vCPU** 以及 **50 MB 的内存**。
- `istio-telemetry` 在每秒 1000 个 网格范围内的请求的情况下，消耗了 **0.6 个 vCPU**。
- Pilot 使用了 **1 个 vCPU** 以及 1.5GB 的内存。
- Envoy 在第 90 个百分位上增加了 8 毫秒的延迟。

## 控制平面的性能

Pilot 根据用户编写的配置文件，结合当前的系统状况对 Sidecar 代理进行配置。在 Kubernetes 环境中，系统状态由 CRD 和 Deployment 构成。用户可以编写 VirtualService、Gateway 之类的 Istio 配置对象。Pilot 会使用这些配置对象，结合 Kubernetes 环境，为 Sidecar 生成配置。

控制平面能够支持数千个 Pod 提供的数千个服务，以及同级别数量的用户配置对象。Pilot 的 CPU 和内存需求会随着配置的数量以及系统状态而变化。CPU 的消耗取决于几个方面：

- 部署情况的变更频率。
- 配置的变更频率。
- 连接到 Pilot 上的代理服务器数量。

然而这部分的本质上就是支持水平伸缩的。

在启用了[命名空间隔离](/docs/reference/config/networking/v1alpha3/sidecar/)的情况下，单一 Pilot 实例在使用 1 个 vCPU 和 1.5GB 内存的情况下，能够支持 1000 个服务、2000 个 Sidecar。可以增加 Pilot 实例数量来降低为 Sidecar 进行配置分发所需要的时长。

## 数据平面性能

数据平面同样会受到多种因素的影响，例如：

- 客户端连接数量。
- 目标请求频率。
- 请求和响应尺寸。
- 代理线程数量。
- 协议。
- CPU 核数。
- Sidecar filter 的数量和类型，尤其是 Mixer filter。

可以根据这些因素来衡量延迟、吞吐量和 Sidecar 的 CPU 以及内存需求。

### CPU 和内存

Sidecar 会在数据路径上执行额外的工作，也自然就需要消耗 CPU 和内存。Istio 1.1 中，代理在每秒 1000 请求的负载下，需要 0.6 个 vCPU。

Sidecar 的内存消耗取决于代理中的配置总数。大量的监听器、集群和路由定义都会增加内存占用。Istio 1.1 中加入了命名空间隔离功能，来限制发送到 Sidecar 上的配置数量。在一个较大的命名空间中，Sidecar 要消耗接近 50 MB 的内存。

通常情况下 Sidecar 不会对经过的数据进行缓存，因此请求数量并不影响内存消耗。

### 延迟

Istio 在数据路径上注入了 Sidecar，因此延迟是一个重要的考量因素。Istio 在代理中加入了认证和 Mixer 过滤器。每个额外的过滤器都会加入数据路径中，导致额外的延迟。

在响应发送给客户端之后，Envoy 会搜集原始的遥测数据。手机请求原始指标的耗时不会对完成请求的总体时间造成影响。然而因为 Worker 忙于处理请求，因此不会立刻开始处理下一个请求。这一过程会延长下一请求的请求队列时间，会对平均和尾部延迟造成影响。实际的尾部延迟取决于通信模式。

在网格里，一个请求会包含客户端代理和服务端代理两部分。每秒 1000 请求的情况下，这两个代理会在数据路径上加入 8 毫秒（90 百分位）。服务端代理自身会产生 2 毫秒（90 百分位）的延迟。

### Istio {{< istio_release_name >}} 的延迟

缺省配置的 Istio 1.1 会在数据平面的基线上加入 8 毫秒的延迟（90 百分位）。这一结果的是使用 [Istio benchmarks](https://github.com/istio/tools/tree/master/perf/benchmark) 得出的，测试过程采用了 `http/1.1` 协议，16个客户端连接，每秒 1000 请求，两个代理 Worker，并启用了双向 TLS。

在 Istio 的未来版本中，我们准备把 `istio-policy` 和 `istio-telemetry` 功能移入代理，称为 `MixerV2`。这会减少系统中的数据流，从而降低 CPU 消耗以及延迟。

{{< image width="90%" ratio="75%"
    link="latency.svg?sanitize=true"
    alt="P90 latency vs client connections"
    caption="P90 latency vs client connections"
>}}

- `baseline`：客户端 Pod 直接调用服务端 Pod，不经过 Sidecar。
- `server-sidecar`：只使用服务端 Sidecar。
- `both-sidecars`：使用客户端和服务端的 Sidecar，这也是网格中的缺省案例。
- `nomixer-both`：和 **both-sidecars** 一致，但是去掉了 Mixer。类似 `MixerV2` 的延迟情况。
- `nomixer-server`：和 **server-sidecar** 一致，但是去掉了 Mixer。类似 `MixerV2` 的延迟情况。

### 基准测试工具

Istio 使用下列工具进行基准测试：

- [`fortio.org`](https://fortio.org/)：一个恒定吞吐量的负载测试工具。
- [`blueperf`](https://github.com/blueperf/)：一个仿真的云原生应用。
- [`isotope`](https://github.com/istio/tools/tree/master/isotope)：具备可配置拓扑结构的合成应用。
