---
title: 发布 Istio 1.29.4
linktitle: 1.29.4
subtitle: 补丁发布
description: Istio 1.29.4 补丁发布。
publishdate: 2026-06-04
release: 1.29.4
aliases:
    - /zh/news/announcing-1.29.4
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.29.3 和 Istio 1.29.4 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (CVSS score 7.5, High)：
  未经身份验证的远程攻击者可通过耗尽 Envoy 进程的内存来导致拒绝服务。
  在验证请求头大小时，系统未完全计入 Cookie 头部字节；
  此外，HPACK 头部块限制仅针对编码后的字节实施，而未对解码后的头部总大小进行相应限制，
  这使得攻击者能够利用特制的 HTTP/2 请求引发过度的内存消耗。

## 变更 {#changes}

- **新增** 添加了初始化检查，验证捆绑的 `nft` 二进制文件是否支持 JSON 输出。
  本机 nftables 后端需要 JSON 在 Pod 删除期间读取配置。
  在 `nft` 二进制文件不支持 JSON 的主机上，每次删除时这些调用都会失败并显示
  `Error: JSON support not compiled-in`，并且 CNI 代理会无限期地重试。
  新的检查在启动时检测到此错误并回退到 iptables 后端。
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **修复** 修复了当父 `Gateway` 使用手动部署时，
  通过 `ListenerSet`
  定义的 HTTPS 侦听器无法传递 TLS 证书的问题。
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **修复** 修复了以下问题：具有无效标头值的 `HTTPRoute` 和
  `GRPCRoute` 过滤器会从 Envoy 配置中静默删除，而不是报告无效的过滤器状态。
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **修复** 修复了当一个网络上的入口调用另一网络上的服务时，
  即使 `Service` 配置为 `istio.io/ingress-use-waypoint`，
  多网络 Ambient 也不会路由到 waypoint 的问题。

- **修复** 修复了当两个 Pod 同时添加到同一节点上的 Ambient 网格时，
  istio-cni 代理中出现致命的 `concurrent map writes` 恐慌。
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **修复** 修复了一个 Ambient 模式错误，其中单个 `Service` 将
  `publishNotReadyAddresses: true` 与 `PreferSameZone` 或
  `PreferSameNode` 流量分配相结合，导致 ztunnel 使用相同的流量分配预设为每个其他 `Service`
  接收 `healthPolicy: AllowAll`，导致流量被路由到集群范围内未就绪的端点。
  ([Issue #60422](https://github.com/istio/istio/issues/60422))
