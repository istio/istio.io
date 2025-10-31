---
title: Platform Requirements
description: Platform requirements for Istio.
weight: 1
skip_seealso: true
keywords: [platform-setup,prerequisites]
owner: istio/wg-environments-maintainers
test: no
aliases: docs/setup/platform-setup/prerequisites
---

## Kernel Module Requirements on Cluster Nodes

Regardless of the Istio {{< gloss >}}data plane{{< /gloss >}} mode, in Kubernetes contexts Istio generally requires Kubernetes nodes running Linux kernels with support for traffic interception and routing. Istio supports two backends for traffic management: `iptables` (default) and `nftables`.

The majority of Linux kernels released in the past decade include built-in support for the features Istio uses - either as kernel modules that will be auto-loaded when required, or built-in. The specific kernel modules required depend on which backend you choose to use.

### iptables Backend

When using the `iptables` backend (the default), the following kernel modules are required for Istio to function correctly:

#### Primary iptables Modules

| Module | Remark |
| --- | --- |
| `br_netfilter` |  |
| `ip6table_mangle` | Only needed for IPv6/dual-stack clusters |
| `ip6table_nat` | Only needed for IPv6/dual-stack clusters |
| `ip6table_raw` | Only needed for IPv6/dual-stack clusters |
| `iptable_mangle` |  |
| `iptable_nat` |  |
| `iptable_raw` | Only needed for `DNS` interception in sidecar mode |
| `xt_REDIRECT` |  |
| `xt_connmark` | Needed for ambient dataplane mode, and sidecar dataplane mode with `TPROXY` interception (default) |
| `xt_conntrack` |  |
| `xt_mark` | Needed for ambient dataplane mode, and sidecar dataplane mode with `TPROXY` interception (default) |
| `xt_owner` |  |
| `xt_tcpudp` |  |
| `xt_multiport` |  |
| `ip_set` | Needed for ambient dataplane mode |

The following additional modules are used by the above listed modules and should also be loaded on the cluster node:

| Module | Remark |
| --- | --- |
| `bridge` |  |
| `ip6_tables` | Only needed for IPv6/dual-stack clusters |
| `ip_tables` |  |
| `nf_conntrack` |  |
| `nf_conntrack_ipv4` |  |
| `nf_conntrack_ipv6` | Only needed for IPv6/dual-stack clusters |
| `nf_nat` |  |
| `nf_nat_ipv4` |  |
| `nf_nat_ipv6` | Only needed for IPv6/dual-stack clusters |
| `nf_nat_redirect` |  |
| `x_tables` |  |
| `ip_set_hash_ip` | Needed for ambient dataplane mode |

### nftables Backend

The `nftables` framework is a modern replacement for `iptables`, offering improved performance and flexibility.
Istio relies on the `nft` CLI tool to configure `nftables` rules. The `nft` binary must be version 1.0.1 or later, and it
requires Linux kernel version 5.13 or higher. For the `nft` CLI to function correctly, the following kernel modules must
be available on the host system.

| Module           | Remark                                   |
|------------------|------------------------------------------|
| `nf_tables`      | Core nftables module                     |
| `nf_conntrack`   | Needed for connection tracking support   |
| `nft_ct`         |                                          |
| `nf_defrag_ipv4` |                                          |
| `nf_defrag_ipv6` | Only needed for IPv6/dual-stack clusters |
| `nft_nat`        |                                          |
| `nft_socket`     |                                          |
| `nft_tproxy`     |                                          |
| `nft_redir`      |                                          |

### Kernel Module Issues

While uncommon, the use of custom or nonstandard Linux kernels or Linux distributions may result in scenarios where the specific modules listed above are not available on the host, or could not be automatically loaded. For example, this [`selinux issue`](https://www.suse.com/support/kb/doc/?id=000020241) describes a scenario in some RHEL releases where `selinux` configuration may prevent the automatic loading of some of the above mentioned kernel modules.

For more details on the specific Istio components that perform traffic interception and routing configuration, see the relevant data plane mode documentation.
