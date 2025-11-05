---
title: 平台要求
description: Istio 的平台要求。
weight: 1
skip_seealso: true
keywords: [platform-setup,prerequisites]
owner: istio/wg-environments-maintainers
test: no
aliases: /zh/docs/setup/platform-setup/prerequisites
---

## 集群节点上的 Linux 内核模块要求 {#kernel-module-requirements-cluster-nodes}

无论 Istio 处于何种{{< gloss "data plane" >}}数据平面{{< /gloss >}}模式，
在 Kubernetes 环境中，Istio 通常要求 Kubernetes
节点运行支持流量拦截和路由的 Linux 内核。
Istio 支持两种流量管理后端：`iptables`（默认）和 `nftables`。

过去十年发布的大多数 Linux 内核都内置了对 Istio 所用功能的支持 - 要么是以内核模块的形式在需要时自动加载，
要么是直接内置的。所需的具体内核模块取决于您选择使用的后端。

### iptables 后端 {#iptables-backend}

使用 `iptables` 后端（默认）时，Istio 需要以下内核模块才能正常运行：

#### 主要 iptables 模块 {#primary-iptables-modules}

| 模块                   |   备注                   |
| --------------------- | ------------------------ |
| `br_netfilter`        |                          |
| `ip6table_mangle`     | 仅适用于 IPv6/双栈集群    |
| `ip6table_nat`        | 仅适用于 IPv6/双栈集群    |
| `ip6table_raw`        | 仅适用于 IPv6/双栈集群    |
| `iptable_mangle`      |                          |
| `iptable_nat`         |                          |
| `iptable_raw`         | 仅需要 `DNS` 拦截          |
| `xt_REDIRECT`         |                          |
| `xt_connmark`         | Ambient 数据平面模式和带有 `TPROXY` 拦截的 Sidecar 数据平面模式需要（默认）  |
| `xt_conntrack`        |                          |
| `xt_mark`             | Ambient 数据平面模式和带有 `TPROXY` 拦截的 Sidecar 数据平面模式需要（默认）  |
| `xt_owner`            |                          |
| `xt_tcpudp`           |                          |
| `xt_multiport`        |                          |
| `ip_set`              | Ambient 数据平面模式所需   |

以下更多模块由上述列出的模块使用，也应该加载到集群节点上：

| 模块                  | 备注                  |
| -------------------- | --------------------- |
| `bridge`             |                       |
| `ip6_tables`         | 仅适用于 IPv6/双栈集群  |
| `ip_tables`          |                       |
| `nf_conntrack`       |                       |
| `nf_conntrack_ipv4`  |                       |
| `nf_conntrack_ipv6`  | 仅适用于 IPv6/双栈集群  |
| `nf_nat`             |                       |
| `nf_nat_ipv4`        |                       |
| `nf_nat_ipv6`        | 仅适用于 IPv6/双栈集群  |
| `nf_nat_redirect`    |                       |
| `x_tables`           |                       |
| `ip_set_hash_ip`     | Ambient 数据平面模式所需 |

### nftables 后端 {#nftables-backend}

`nftables` 框架是 `iptables` 的现代替代方案，提供更高的性能和灵活性。
Istio 依赖 `nft` 命令行工具来配置 `nftables` 规则。
`nft` 二进制文件必须为 1.0.1 或更高版本，并且需要 Linux 内核版本 5.13 或更高版本。
为了使 `nft` 命令行工具正常运行，主机系统上必须安装以下内核模块。

| 模块              | 备注                                      |
|------------------|------------------------------------------|
| `nf_tables`      | 核心 nftables 模块.                        |
| `nf_conntrack`   | 需要连接跟踪支持.                           |
| `nft_ct`         |                                          |
| `nf_defrag_ipv4` |                                          |
| `nf_defrag_ipv6` | 仅适用于 IPv6/双栈集群                      |
| `nft_nat`        |                                          |
| `nft_socket`     |                                          |
| `nft_tproxy`     |                                          |
| `nft_redir`      |                                          |

### 内核模块问题 {#kernel-module-issues}

虽然不常见，但使用自定义或非标准的 Linux 内核或 Linux 发行版可能会导致上述特定模块在主机上不可用，
或者无法自动加载。例如，这篇 [`selinux issue`](https://www.suse.com/support/kb/doc/?id=000020241)
描述了某些 RHEL 版本中 `selinux` 配置可能会阻止自动加载上述某些内核模块的情况。

有关执行流量拦截和路由配置的具体 Istio 组件的更多详细信息，请参阅相关的数据平面模式文档。
