---
title: "Istio：性能最高的网络安全解决方案"
description: Ambient 模式提供比 Kubernetes 生态系统中任何其他项目更强的加密吞吐能力。
publishdate: 2025-03-06
attribution: "John Howard (Solo.io); Translated by Wilson Wu (DaoCloud)"
keywords: [istio,performance,ambient]
---

传输过程中加密是当今几乎所有 Kubernetes 环境的基本要求，
并构成了零信任安全态势的基础。

然而，安全性的挑战在于它并非没有代价：
它通常涉及复杂性、用户体验和性能之间的权衡。

虽然大多数 Cloud Native 用户都知道 Istio 是一个服务网格，
可以提供高级 HTTP 功能，但它也可以充当基础网络安全层的角色。
当我们着手构建 [Istio 的 Ambient 模式](/zh/docs/overview/dataplane-modes/#ambient-mode)时，
这两层被明确分开。我们的主要目标之一是能够在提供安全性
（以及一系列[其他功能](/zh/docs/concepts/)！）的同时不受到其他影响。

借助 Ambient 模式，**Istio 现在是实现 Kubernetes 中安全零信任网络的最高带宽方式**。

在我们深入探讨原因和方式之前，让我们先看一些结果。

## 进行测试 {#putting-it-to-the-test}

为了测试性能，我们使用了标准网络基准测试工具 [`iperf`](https://iperf.fr/)，
来测量流经各种流行的 Kubernetes 网络安全解决方案的 TCP 流量的带宽。

{{< image width="60%"
    link="./service-mesh-throughput.svg"
    alt="各种网络安全解决方案的性能。"
    >}}

结果不言而喻：Istio 绝对领先，成为性能最高的网络安全解决方案。
更令人印象深刻的是，随着 Istio 的每次发布，这种差距还在不断扩大：

{{< image width="60%"
    link="./ztunnel-performance.svg"
    alt="ztunnel 各版本性能对比。"
    >}}

Istio 的性能由 [ztunnel](https://github.com/istio/ztunnel) 驱动，
这是一个专门构建的数据平面，轻量、快速且安全。
在过去的 4 个版本中，ztunnel 的性能提高了 75%！

<details>
<summary>测试细节</summary>

测试中的实现：
* Istio：版本 1.26（预发布），默认设置
* <a href="https://linkerd.io/">Linkerd</a>：
  版本 `edge-25.2.2`，默认设置
* <a href="https://cilium.io/">Cilium</a>：
  版本 `v1.16.6`，带有 `kubeProxyReplacement=true`
  * WireGuard 使用 `encryption.type=wireguard`
  * IPsec 使用 `encryption.type=ipsec` 和 `GCM-128-AES` 算法
  * 此外，两种模式均按照
    <a href="https://docs.cilium.io/en/stable/operations/performance/tuning/">Cilium 调优指南</a>中的所有建议进行了测试
    （包括 `netkit`、`native` 路由模式、
    BIGTCP（用于 WireGuard；IPsec 不兼容）、BPF 伪装和 BBR 带宽管理器）。
    但是，应用和不应用这些设置的结果相同，因此仅报告一个结果。
* <a href="https://www.tigera.io/project-calico/">Calico</a>：版本 `v3.29.2`，
  带有 `calicoNetwork.linuxDataplane=BPF` 和 `wireguardEnabled=true`
* <a href="https://kindnet.es/">Kindnet</a>：
  版本 `v1.8.5`，带有 `--ipsec-overlay=true`。

有些实现仅对跨节点流量进行加密，因此被排除在同节点测试之外。

测试在单个 `iperf` 连接（`iperf3 -c iperf-server`）上运行，
取 3 次连续运行结果的平均值。测试在运行 Linux 6.13
的 16 核 x86 机器上运行。由于各种原因，在处理单个连接时，
没有实现会使用超过 1-2 个核心，因此核心数量不是瓶颈。

注意：许多实现都支持 HTTP 控制。此测试不会在任何实现中运用此功能。
[以前的帖子](/zh/blog/2024/ambient-vs-cilium/)重点介绍了 Istio 的这一领域。

</details>

## 超越内核 {#outpacing-the-kernel}

在网络性能方面，一个非常普遍的看法是，在内核中完成所有操作
（无论是原生操作还是使用 eBPF 扩展）是实现高性能的最佳方式。
然而，这些结果显示出相反的效果：用户空间实现（Linkerd 和 Istio）
的性能大大优于内核实现。这是怎么回事呢？

一个主要因素是创新速度。性能并不是一成不变的，微优化、
创新和硬件改进的适应都在不断进步。内核服务于大量用例，
必须谨慎发展。即使有所改进，也可能需要很多年才能渗透到现实世界环境中。

相比之下，用户空间实现能够快速更改并适应其特定的目标用例，
并在任何内核版本上运行。ztunnel 就是这种效果的一个很好的例子，
每个季度发布都会带来显着的性能改进。一些最有影响力的变化：

* 迁移到 `rustls`，一个专注于安全性的高性能 TLS 库
  ([#820](https://github.com/istio/ztunnel/pull/820))。
* 减少出站流量的数据复制 ([#1012](https://github.com/istio/ztunnel/pull/1012))。
* 动态调整活动连接的缓冲区大小 ([#1024](https://github.com/istio/ztunnel/pull/1024))。
* 优化内存复制 ([#1169](https://github.com/istio/ztunnel/pull/1169))。
* 将加密库移至 `AWS-LC`，这是一个针对现代硬件优化的高性能加密库
  ([#1466](https://github.com/istio/ztunnel/pull/1466))。

其他一些因素包括：

* WireGuard 和 Linkerd 使用 `ChaCha20-Poly1305` 加密算法，
  而 Istio 使用 `AES-GCM`。后者在现代硬件上进行了高度优化。
* WireGuard 和 IPsec 对单个数据包进行操作（通常最多 1500 字节，受网络 MTU 限制），
  而 TLS 对最多 16KB 的记录进行操作。

## 即刻尝试 Ambient 模式 {#try-ambient-mode-today}

如果您希望在不影响复杂性或性能的情况下增强集群的安全性，
那么现在是尝试 Istio 的 Ambient 模式的最佳时机！

按照[入门指南](/zh/docs/ambient/getting-started/)了解安装和启用它是多么简单。

您可以在 [Istio Slack](https://slack.istio.io)
上的 #ambient 频道与开发人员进行交流，或使用
[GitHub 上的 Discussions 论坛](https://github.com/istio/istio/discussions)来讨论您可能遇到的任何问题。
