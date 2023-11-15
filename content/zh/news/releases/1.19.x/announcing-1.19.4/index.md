---
title: 发布 Istio 1.19.4
linktitle: 1.19.4
subtitle: 补丁发布
description: Istio 1.19.4 补丁发布。
publishdate: 2023-11-13
release: 1.19.4
---

本发布说明描述了 Istio 1.19.3 和 Istio 1.19.4 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **改进** 改进了 `iptables` 锁定功能。新的实现在需要时使用
  `iptables` 内置锁等待，并在不需要时完全禁用锁定。

- **新增** 添加了门控标志 `ISTIO_ENABLE_IPV4_OUTBOUND_LISTENER_FOR_IPV6_CLUSTERS`，
  在只有 IPv6 的集群中用来管理一个附加的出站侦听器，以处理 IPv4 NAT 出站流量。
  这对于只有 IPv6 的集群环境（例如管理只有 Egress IPv4 以及 IPv6 IP 的 EKS）非常有用。
  ([Issue #46719](https://github.com/istio/istio/issues/46719))

- **修复** 修复了根虚拟服务中的多个标头匹配生成错误路由的问题。
  ([Issue #47148](https://github.com/istio/istio/issues/47148))

- **修复** 修复了 `ServiceEntry` 通配符基于 `glibc` 容器的搜索域后缀 DNS 代理解析的问题。
  ([Issue #47264](https://github.com/istio/istio/issues/47264))、
  ([Issue #31250](https://github.com/istio/istio/issues/31250))、
  ([Issue #33360](https://github.com/istio/istio/issues/33360))、
  ([Issue #30531](https://github.com/istio/istio/issues/30531))、
  ([Issue #38484](https://github.com/istio/istio/issues/38484))

- **修复** 修复了如果默认 IP 寻址不是 IPv6，
  则正在使用 `IstioIngressListener.defaultEndpoint` 的
  Sidecar 资源无法使用 [::1]:PORT 的问题。
  ([Issue #47412](https://github.com/istio/istio/issues/47412))

- **修复** 修复了如果未提供 EDS 端点，`istioctl proxy-config` 无法处理文件中的配置转储的问题。
  ([Issue #47505](https://github.com/istio/istio/issues/47505))

- **修复** 修复了 `istioctl tag list` 命令不接受 `--output` 标志的问题。
  ([Issue #47696](https://github.com/istio/istio/issues/47696))

- **修复** 修复了多集群 Secret 过滤导致 Istio 从每个命名空间获取 Secret 的问题。
  ([Issue #47433](https://github.com/istio/istio/issues/47433))

- **修复** 修复了当 `header-name` 设置为 `{}` 时，`VirtualService` HTTP 标头匹配不起作用的问题。
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **修复** 修复了导致正在终止的无头服务实例的流量无法正常运行的问题。
  ([Issue #47348](https://github.com/istio/istio/issues/47348))

## 安全更新 {#security-update}

此版本中没有安全更新。
