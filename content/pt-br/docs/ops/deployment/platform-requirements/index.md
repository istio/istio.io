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

Regardless of the Istio {{< gloss >}}data plane{{< /gloss >}} mode, in Kubernetes contexts Istio generally requires Kubernetes nodes running Linux kernels with `iptables` support in order to function. The majority of Linux kernels released in the past decade include built-in support for all the `iptables` features Istio uses by default - either as kernel modules that will be auto-loaded when required, or built-in.

For reference, the following lists all the `iptables`-related kernel modules required for Istio to function correctly:

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
| `xt_multiport`|  |
| `ip_set`| Needed for ambient dataplane mode |

The following additional modules are used by the above listed modules and should be also loaded on the cluster node:

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
| `ip_set_hash_ip`| Needed for ambient dataplane mode |

While uncommon, the use of custom or nonstandard Linux kernels or Linux distributions may result in scenarios where the specific modules listed above are not available on the host, or could not be automatically loaded by `iptables`. For example, this [`selinux issue`](https://www.suse.com/support/kb/doc/?id=000020241) describes a scenario in some RHEL releases where `selinux` configuration may prevent the automatic loading of some of the above mentioned kernel modules.

For more details on the specific Istio components that perform `iptables`-based configuration, see the relevant data plane mode documentation.
