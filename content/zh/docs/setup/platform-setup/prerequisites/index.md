---
title: 平台前提条件  
description: 在各平台上安装 Istio 的前提条件。  
weight: 1  
skip_seealso: true
keywords: [platform-setup,prerequisites]
owner: istio/wg-environments-maintainers
test: no
---

## 集群节点上的 Linux 内核模块要求 {#kernel-module-requirements-cluster-nodes}

在用 Istio 代理 Sidecar 容器运行应用程序 Pod 的集群节点上使用 iptables 拦截模式时，需要加载某些内核模块。Istio 也可以工作在没有 iptables 的 `whitebox` 模式下。如果使用的是这种模式，可以忽略本节内容，因为这种模式不需要任何专用的内核模块。

具体而言，`istio-init` 容器或 `istio-cni` 守护进程需要这些内核模块，才能在 Pod 中设置 iptables 规则，将任何传入或传出的流量重定向到 istio-proxy 容器中的 Sidecar 代理。尽管在许多平台上这些模块看起来像是自动加载的，但请务必确保满足相应的前提条件，因为我们曾多次接报以下列出的某些专用模块在主机上不可用，或无法通过 iptables 自动加载。例如，这个 [`selinux issue`](https://www.suse.com/support/kb/doc/?id=000020241) 就在讨论 RHEL 中的 selinux 有时会阻止自动加载下述某些内核模块。

| 模块 | 备注 |
| --- | --- |
| `br_netfilter` |  |
| `ip6table_mangle` | 仅适用于 IPv6 或双栈集群 |
| `ip6table_nat` | 仅适用于 IPv6 或双栈集群 |
| `ip6table_raw` | 仅适用于 IPv6 或双栈集群 |
| `iptable_mangle` |  |
| `iptable_nat` |  |
| `iptable_raw` | 仅适用于 `DNS` 拦截 |
| `xt_REDIRECT` |  |
| `xt_connmark` | 仅适用于 `TPROXY` 拦截模式 |
| `xt_conntrack` |  |
| `xt_mark` | 仅适用于 `TPROXY` 拦截模式 |
| `xt_owner` |  |
| `xt_tcpudp` |  |

以下更多模块由上述列出的模块使用，也应该加载到集群节点上：

| 模块 | 备注 |
| --- | --- |
| `bridge` |  |
| `ip6_tables` | 仅适用于 IPv6 或双栈集群 |
| `ip_tables` |  |
| `nf_conntrack` |  |
| `nf_conntrack_ipv4` |  |
| `nf_conntrack_ipv6` | 仅适用于 IPv6 或双栈集群 |
| `nf_nat` |  |
| `nf_nat_ipv4` |  |
| `nf_nat_ipv6` | 仅适用于 IPv6 或双栈集群 |
| `nf_nat_redirect` |  |
| `x_tables` |  |
