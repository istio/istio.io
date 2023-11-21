---
title: "Istio ambient 模式中使用 eBPF 进行流量重定向"
description: 将 POD 流量重定向至每节点 ztunnel 代理的另一种方法。
publishdate: 2023-03-31

attribution: "丁少君 (Intel), 李纯 (Intel)"
keywords: [istio,ambient,ztunnel,eBPF]
---

在 Istio [Ambient](/zh/blog/2022/introducing-ambient-mesh/) 模式中，运行在每个 Kubernetes
工作节点上的 `istio-cni` 组件负责将应用程序流量重定向到该节点上的零信任隧道代理（ztunnel）。
默认情况下，这依赖于 iptables 和 [Generic Network Virtualization Encapsulation (Geneve)](https://www.rfc-editor.org/rfc/rfc8926.html)
隧道来实现这种重定向。现在我们增加了基于 eBPF 的流量重定向方法的支持。

## 为何采用 eBPF

虽然在实现 Istio Ambient 模式重定向时需要考虑性能问题，但对于可编程性的考量也非常重要，
以满足转发规则多样化和可定制化的要求。使用 eBPF，
你可以利用内核中的额外上下文来绕过繁杂的路由，并快速简单地将数据包发送到最终目的地。

此外，与 iptables 相比，eBPF 对内核中数据包具有更深入的可见性以及额外的上下文操作，
使更有效和灵活的管理数据流成为可能。

## eBPF 流量重定向如何工作

一个 eBPF 程序被预编译到 Istio CNI 组件中，这个 eBPF 程序会被加载到
[traffic control](https://man7.org/linux/man-pages/man8/tc-bpf.8.html) ingress
和 egress 的 hook 点上。`istio-cni` 会监听 Pod 事件，并在 Pod 加入或离开 Istio Ambient
模式时将 eBPF 程序加载/卸载到 Pod 相关的网络接口上。

使用 eBPF 程序替代 iptables 模式消除了对于 Geneve 的封包/解包的需求，
并使流量的转发可以在内核空间中自定义。这既提高了性能，又提供了额外的灵活性。

{{< image width="55%"
    link="ambient-ebpf.png"
    caption="Ambient eBPF 架构"
    >}}

所有进出应用程序 Pod 的流量都将被 eBPF 截获并重定向到相应的 ztunnel Pod。
在 ztunnel 一侧，eBPF 程序将根据 connection 状态的查找结果执行对应的重定向操作。
这提供了更有效的控制应用程序 Pod 和 ztunnel Pod 之间网络流量的方法。

## 在 Ambient 模式下如何使用 eBPF

请按照 [Istio Ambient Mesh 入门](/zh/blog/2022/get-started-ambient/)设置您的集群，
但需以下一个小修改：在安装 Istio 时，请将 `values.cni.ambient.redirectMode` 配置参数设置为 `ebpf`。

{{< text bash >}}
$ istioctl install --set profile=ambient --set values.cni.ambient.redirectMode="ebpf"
{{< /text >}}

检查 istio-cni 的日志以确认 eBPF 重定向是否已启用：

{{< text plain >}}
ambient Writing ambient config: {"ztunnelReady":true,"redirectMode":"eBPF"}
{{< /text >}}

## 性能提升

使用 eBPF 重定向的延迟和吞吐量（QPS）比使用 iptables 稍好。以下测试是在一个 `kind`
集群中运行，其中 Fortio 客户端向在 Ambient 模式下运行的 Fortio 服务器发送请求
（eBPF 调试日志已禁用），并且两者都在同一 Kubernetes 工作节点上运行。

{{< text bash >}}
$ fortio load -uniform -t 60s -qps 0 -c <num_connections> http://<fortio-svc-name>:8080
{{< /text >}}

{{< image width="90%" link="./MaxQPS.png" alt="Max QPS with varying number of connections" title="Max QPS with varying number of connections" caption="Max QPS, with varying number of connections" >}}

{{< text bash >}}
$ fortio load -uniform -t 60s -qps 8000 -c <num_connections> http://<fortio-svc-name>:8080
{{< /text >}}

{{< image width="90%" link="./P75-Latency-with-8000-qps.png" alt="Latency (ms) for QPS 8000 with varying number of connections" title="P75 Latency (ms) for 8000 QPS, with varying number of connections" caption="P75 Latency (ms) for QPS 8000 with varying number of connections" >}}

## 总结

在流量重定向方面，eBPF 和 iptables 都有其优缺点。eBPF 是一种现代、灵活和强大的替代方案，
允许在规则创建方面进行更多的自定义，并提供更好的性能。但是，它需要一个较新的内核版本（4.20 或更高版本），
这使得 eBPF 在一些系统上可能并不可用。另一方面，iptables 被广泛使用，并且与大多数 Linux
发行版兼容，即使是那些使用较旧内核的发行版也可以兼容。但是，它缺乏 eBPF 的灵活性和可扩展性，并且可能具有较低的性能。

最终，在流量重定向方面，选择 eBPF 还是 iptables 取决于系统的具体需求和要求，
以及用户在使用每个工具方面的专业水平。一些用户可能更喜欢 iptables 的简单性和兼容性，
而另一些用户可能需要 eBPF 的灵活性和性能。

目前，仍有许多工作需要完成，包括与各种 CNI 插件的集成，非常欢迎大家一同贡献以改善其易用性。
请加入我们在 [Istio slack](https://slack.istio.io/) 上的 #ambient 频道与我们一起交流。
