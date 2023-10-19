---
title: Platform Prerequisites
description: Prerequisites for platform setup for Istio.
weight: 1
skip_seealso: true
keywords: [platform-setup,prerequisites]
owner: istio/wg-environments-maintainers
test: no
---


## Kernel Module Requirements on Cluster Nodes

The cluster node running application pods with Istio proxy sidecar container, when using iptables interception mode,
requires certain kernel modules to be loaded. Istio can also work in `whitebox` mode where iptables interception is not done
and in such cases this section can be skipped as there is no need of any special kernel module.

The modules are needed specifically by the `istio-init` container or `istio-cni` daemon which sets up iptables rules in the pod to
redirect any incoming or outgoing traffic towards the sidecar proxy in the istio-proxy container. While in many platforms, these seem
to be automatically loaded, it is always good to make sure the prerequisites are met, as there were incidents reported where some of
the specific modules listed down below were not available on the host or could not be automatically loaded by the iptables. For example,
this [`selinux issue`](https://www.suse.com/support/kb/doc/?id=000020241) talks about selinux in RHEL sometimes preventing
the automatic loading of some of the below mentioned kernel modules.

| Module | Remark |
| --- | --- |
| `br_netfilter` |  |
| `ip6table_mangle` | Only needed for IPv6 or dual-stack clusters |
| `ip6table_nat` | Only needed for IPv6 or dual-stack clusters |
| `ip6table_raw` | Only needed for IPv6 or dual-stack clusters |
| `iptable_mangle` |  |
| `iptable_nat` |  |
| `iptable_raw` | Only needed for `DNS` interception |
| `xt_REDIRECT` |  |
| `xt_connmark` | Only needed for `TPROXY` interception mode |
| `xt_conntrack` |  |
| `xt_mark` | Only needed for `TPROXY` interception mode |
| `xt_owner` |  |
| `xt_tcpudp` |  |
| `xt_multiport`|  |

The following additional modules are used by the above listed modules and should be also loaded on the cluster node:

| Module | Remark |
| --- | --- |
| `bridge` |  |
| `ip6_tables` | Only needed for IPv6 or dual-stack clusters |
| `ip_tables` |  |
| `nf_conntrack` |  |
| `nf_conntrack_ipv4` |  |
| `nf_conntrack_ipv6` | Only needed for IPv6 or dual-stack clusters |
| `nf_nat` |  |
| `nf_nat_ipv4` |  |
| `nf_nat_ipv6` | Only needed for IPv6 or dual-stack clusters |
| `nf_nat_redirect` |  |
| `x_tables` |  |
