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

无论 Istio {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式如何，
在 Kubernetes 上下文中，Istio 通常需要运行具有 `iptables` 支持的 Linux 内核的 Kubernetes 节点才能正常运行。
过去十年中发布的大多数 Linux 内核都包含对 Istio 默认使用的所有 `iptables`
功能的内置支持 - 要么作为需要时自动加载的内核模块，要么内置。

作为参考，下面列出了 Istio 正常运行所需的所有 `iptables` 相关内核模块：

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

虽然不常见，但使用自定义或非标准 Linux 内核或 Linux 发行版可能会导致上面列出的特定模块在主机上不可用，
或者无法由 `iptables` 自动加载的情况。例如，此 [`selinux issues`](https://www.suse.com/support/kb/doc/?id=000020241)
描述了某些 RHEL 版本中的一种情况，其中 `selinux` 配置可能会阻止自动加载上面提到的一些内核模块。

有关执行基于 `iptables` 配置的特定 Istio 组件的更多详细信息，请参阅相关的数据平面模式文档。
