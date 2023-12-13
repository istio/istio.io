---
title: 发布 Istio 1.18.6
linktitle: 1.18.6
subtitle: 补丁发布
description: Istio 1.18.6 补丁发布。
publishdate: 2023-12-12
release: 1.18.6
---

本次发布实现了 12 月 12 日公布的安全更新 [`ISTIO-SECURITY-2023-005`](/zh/news/security/istio-security-2023-005)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.18.5 和 Istio 1.18.6 之间的不同之处。
本次发布是 Istio 1.18 计划的最后一个版本，
更多细节请参阅 11 月 29 日发布的[支持结束公告](/zh/news/support/announcing-1.18-eol/)。

{{< relnote >}}

## 变更 {#changes}

- **改进** 改进了 `iptables` 锁定。新的实现会在需要时使用 `iptables` 内置的锁定等待，
  并在不需要时完全禁用锁定。

- **修复** 修复了使用通配符 `ServiceEntry` 搭配搜索域名后缀搜索基于 glibc 的容器时 DNS 代理解析的问题。
  ([Issue #47264](https://github.com/istio/istio/issues/47264)),
  ([Issue #31250](https://github.com/istio/istio/issues/31250)),
  ([Issue #33360](https://github.com/istio/istio/issues/33360)),
  ([Issue #30531](https://github.com/istio/istio/issues/30531)),
  ([Issue #38484](https://github.com/istio/istio/issues/38484))

- **修复** 修复了在默认 IP 寻址不是 IPv6 时使用 `IstioIngressListener.defaultEndpoint`
  的 Sidecar 资源无法使用 [::1]:PORT 的问题。
  ([Issue #47412](https://github.com/istio/istio/issues/47412))

- **修复** 修复了在未提供 EDS 端点时 `istioctl proxy-config` 无法处理来自文件的配置转储的问题。
  ([Issue #47505](https://github.com/istio/istio/issues/47505))

- **修复** 修复了在设置 `header-name: {}` 时 `VirtualService` 中的
  HTTP 头存在匹配无法正常工作的问题。
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **修复** 修复了在没有追踪选项的情况下使用 `datadog` 或 `stackdriver` 时的空遍历问题。
  ([Issue #45855](https://github.com/istio/istio/issues/45855))

- **修复** 修复了多集群领导者选举时未优先考虑本地领导者而考虑远程领导者的问题。
  ([Issue #47901](https://github.com/istio/istio/issues/47901))

- **修复** 修复了在双栈模式下安装时客户端能够通过 IPv6 与 ServiceEntries 中定义的主机通信的问题。
  ([Issue #46743](https://github.com/istio/istio/issues/46743)),
  ([Issue #47406](https://github.com/istio/istio/issues/47406))

- **修复** 修复了导致流量无法正确运行到终止的无头服务实例的问题。
  ([Issue #47348](https://github.com/istio/istio/issues/47348))

- **修复** 修复了 `hostNetwork` 的 Pod 扩缩时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **修复** 修复了 `WorkloadEntries` 更改 IP 地址时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **修复** 修复了删除 `ServiceEntry` 时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

## 安全更新 {#security-update}

- 按照 [`ISTIO-SECURITY-2023-005`](/zh/news/security/istio-security-2023-005) 所述，
  对 Istio CNI 权限进行了变更。
