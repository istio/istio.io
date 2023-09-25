---
title: "深挖 Ambient 与 Sidecar 并存的网络流量路径"
description: "深挖 Ambient 与 Sidecar 并存的流量路径。"
publishdate: 2023-09-18
attribution: "张怀龙 (Intel), John Howard (Google), 曾宇星 (Alibaba), Peter Jausovec (Solo.io); Translated by Wilson Wu (DaoCloud)"
keywords: [traffic,ambient,sidecar,coexistence]
---

Istio 有两种部署模式：Ambient 模式和 Sidecar 模式。
前者还在持续开发中，后者是经典的网格方案。因此，Ambient 模式和 Sidecar
模式并存应该是一种正常的部署形式，这也是这篇博客可能对 Istio 用户有所帮助的原因。

## 背景 {#background}

在现代微服务架构中，服务之间的通信和管理至关重要。为了应对这一挑战，
Istio 作为一种服务网格技术应运而生。它利用 Sidecar 提供流量控制、安全性和卓越的可观察功能。
为了进一步提高 Istio 的适应性和灵活性，Istio 社区开始探索一种新的模式 —— Ambient 模式。
在这种模式下，Istio 不再依赖显式的 Sidecar 注入，而是通过 ztunnel 和 waypoint
代理实现服务之间的通信和网格管理。Ambient 还带来了一系列改进，例如更低的资源消耗、更简单的部署以及更灵活的配置选项。
启用 Ambient 模式后，我们不再需要重新启动 Pod，这使得 Istio 在各种场景中能够更好地发挥作用。

在本文的[参考资源](#reference-resources)一节列出了几篇在社区和技术论坛中介绍和分析 Ambient 的博客，
本文将分析 Istio Ambient 和 Sidecar 模式下的网络流量路径。

为了阐明网络流量路径并使其更容易理解，本博文探讨了以下两种场景并配有相应的图表：

- **Ambient 模式下的服务到 Sidecar 模式下服务的网络路径**
- **Sidecar 模式下的服务到 Ambient 模式下服务的网络路径**

## 关于分析的信息 {#information-about-the-analysis}

分析基于 Istio 1.18.2，其中 Ambient 模式使用 iptables 进行重定向。

## Ambient 模式 `sleep` 到 Sidecar 模式 `httpbin` {#ambient-mode-sleep-to-sidecar-mode-httpbin}

### 第一个场景的部署和配置 {#deployment-and-configuration-for-the-first-scenario}

- `sleep` 部署在命名空间 foo 中
    - `sleep` Pod 被调度到节点 A
- `httpbin` 部署在命名空间 bar 中
    - `httpbin` 被调度到节点 B
- foo 命名空间启用 Ambient 模式（foo 命名空间包含标签：`istio.io/dataplane-mode=ambient`）
- bar 命名空间启用 Sidecar 注入（bar 命名空间包含标签：`istio-injection：enabled`）

根据以上描述，部署和网络流量路径为：

{{< image width="100%"
    link="ambient-to-sidecar.png"
    caption="Ambient 模式 sleep 到 Sidecar 模式 httpbin"
    >}}

如果启用 Ambient 模式，ztunnel 将作为 DaemonSet 部署在 istio-system 命名空间中，
而 istio-cni 和 ztunnel 将为 ztunnel Pod 和每个节点上的 Pod 生成 iptables 规则和路由。

启用 Ambient 模式时进出 Pod 的所有网络流量都将根据网络重定向逻辑流经 ztunnel。
然后 ztunnel 会将流量转发到正确的端点。

### Ambient 模式 `sleep` 到 Sidecar 模式 `httpbin` 的网络流量路径分析 {#network-traffic-path-analysis-of-ambient-mode-sleep-to-sidecar-mode-httpbin}

根据上图，网络流量路径的详细情况如下所示：

**(1) (2) (3)** `sleep` 服务的请求流量从 `sleep` Pod 的 `veth` 发出，
遵循 iptables 规则和路由规则该 Pod 被标记并转发到节点中的 `istioout` 设备。
节点 A 中的 `istioout` 设备是一个 [Geneve](https://www.rfc-editor.org/rfc/rfc8926.html) 隧道，
隧道的另一端是 `pistioout`，即位于同一节点上的 ztunnel Pod 内。

**(4) (5)** 当流量经由 `pistioout` 设备到达时，
Pod 内的 iptables 规则会拦截并通过 Pod 中的 `eth0` 接口将其重定向到端口 `15001`。

**(6)** 根据原始请求信息，ztunnel 可以获取目标服务的端点列表。
然后，它将处理请求并将其发送到端点，例如某个 `httpbin` Pod。
最后，请求流量将通过容器网络进入 `httpbin` Pod。

**(7)** 到达 `httpbin` Pod 的请求流量将被 Sidecar 的 iptables
规则拦截并重定向到 Sidecar 的端口 `15006`。

**(8)** Sidecar 处理通过端口 15006 传入的入站请求流量，
并将流量转发到同一 Pod 中的 `httpbin` 容器。

## Sidecar 模式 `sleep` 到 Ambient 模式 `httpbin` 和 `helloworld` {#sidecar-mode-sleep-to-ambient-mode-httpbin-and-helloworld}

### 第二种场景的部署和配置 {#deployment-and-configuration-for-the-second-scenario}

- `sleep` 部署在命名空间 foo 中
    - `sleep` Pod 被调度到节点 A
- `httpbin` 部署在命名空间 bar-1 中
    - `httpbin` Pod 被调度到节点 B
    - `httpbin` 的 waypoint 代理被禁用
- `helloworld` 部署在命名空间 bar-2 中
    - `helloworld` Pod 被调度到节点 D
    - `helloworld` 的 waypoint 代理被启用
    - waypoint 代理被调度到节点 C
- foo 命名空间启用 Sidecar 注入（foo 命名空间包含标签：`istio-injection:enabled`）
- bar-1 命名空间启用 Ambient 模式（bar-1 命名空间包含标签：`istio.io/dataplane-mode=ambient`）

根据以上描述，部署和网络流量路径为：

{{< image width="100%"
    link="sidecar-to-ambient.png"
    caption="sleep 到 httpbin 和 helloworld"
    >}}

### Sidecar 模式 `sleep` 到 Ambient 模式 `httpbin` 的网络流量路径分析 {#network-traffic-path-analysis-of-sidecar-mode-sleep-to-ambient-mode-httpbin}

上图的上半部分描述了从 `sleep` Pod（Sidecar 模式）到 `httpbin` Pod（Ambient 模式）的请求的网络流量路径。

**(1) (2) (3) (4)** `sleep` 容器向 `httpbin` 发送一个请求。该请求被 iptables 规则拦截，
并定向到 `sleep` Pod 中 Sidecar 上的端口 `15001`。
然后，Sidecar 处理请求并根据从 istiod（控制平面）收到的配置路由流量，
将流量转发到与节点 B 上的 `httpbin` Pod 对应的 IP 地址。

**(5) (6)** 将请求发送到设备对（`veth httpbin <-> eth0 inside httpbin pod`）后，
请求根据 iptables 和路由规则被拦截和转发到节点 B 上的 `istioin` 设备，
在节点 B 上遵循 iptables 和路由规则来运行 `httpbin` Pod。节点 B 上的 `istioin` 设备和同一节点上
ztunnel Pod 内的 `pistion` 设备通过 [Geneve](https://www.rfc-editor.org/rfc/rfc8926.html) 连接隧道。

**(7) (8)** 请求进入 ztunnel Pod 的 `pistioin` 设备后，ztunnel Pod 中的 iptables
规则会拦截并通过 Pod 内运行的 ztunnel 代理上的端口 15008 重定向流量。

**(9)** 进入端口 15008 的流量将被视为入站请求，
然后 ztunnel 会将请求转发到同一节点 B 中的 `httpbin` Pod。

### 通过 waypoint 代理从 Sidecar 模式 `sleep` 到 Ambient 模式 `httpbin` 的网络流量路径分析 {#network-traffic-path-analysis-of-sidecar-mode-sleep-to-ambient-mode-httpbin-via-waypoint-proxy}

与图中的顶部相比，底部在 `sleep`、ztunnel 和 `httpbin` Pod 之间的路径中插入了一个 waypoint 代理。
Istio 控制平面拥有服务网格的所有服务和配置信息。当使用 waypoint 代理部署 `helloworld` Pod 时，
`sleep` Pod 的 Sidecar 接收到的 `helloworld` 服务的 EDS 配置将更改为 `envoy_internal_address` 类型。
这会导致通过 Sidecar 的请求流量通过
[基于 HTTP 的覆盖网络（HBONE）](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit)
协议被转发到节点 C 上的 waypoint 代理的 15008 端口。

waypoint 代理是 Envoy 代理的一个实例，它根据从控制平面收到的路由配置将请求转发到 `helloworld` Pod。
一旦流量到达节点 D 上的 `veth`，它就会遵循与之前场景相同的路径。

## 总结 {#wrapping-up}

Sidecar 模式使 Istio 成为一个出色的服务网格。但是，Sidecar 模式也会导致问题，
因为它要求应用程序和 Sidecar 容器在同一个 Pod 中运行。
Istio Ambient 模式通过集中式代理（ztunnel 和 waypoint）实现服务之间的通信。
Ambient 模式提供了更大的灵活性和可扩展性，减少了资源消耗，因为它不需要网格中的每个 Pod 都有 Sidecar，
并且允许更精确的配置。 因此，毫无疑问，Ambient 模式是 Istio 的下一个演进。
显然，Sidecar 和 Ambient 模式的并存可能会持续很长一段时间，
虽然 Ambient 模式还处于 Alpha 阶段且 Sidecar 模式仍然是 Istio 的推荐模式，
但随着 Ambient 模式进阶至 Beta 和后续完善，它将给用户提供一种更轻量级的选择来运行并采用 Istio 服务网格。

## 参考资源 {#reference-resources}

- [Ambient 网格中的流量：Istio CNI 和节点配置](https://www.solo.io/blog/traffic-ambient-mesh-istio-cni-node-configuration/)
- [Ambient 网格中的流量：使用 iptables 和 Geneve 隧道进行重定向](https://www.solo.io/blog/traffic-ambient-mesh-redirection-iptables-geneve-tunnels/)
- [Ambient 网格中的流量：ztunnel、eBPF 配置和 waypoint 代理](https://www.solo.io/blog/traffic-ambient-mesh-ztunnel-ebpf-waypoint/)
