---
title: 发布 Istio 1.28.8
linktitle: 1.28.8
subtitle: 补丁发布
description: Istio 1.28.8 补丁发布。
publishdate: 2026-06-04
release: 1.28.8
aliases:
    - /zh/news/announcing-1.28.8
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.28.7 和 Istio 1.28.8 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (CVSS score 7.5, High)：
  未经身份验证的远程攻击者可能会耗尽 Envoy 进程中的内存，从而导致拒绝服务。
  在请求标头大小验证期间未完全考虑 Cookie 标头字节，
  并且对编码字节强制执行 HPACK 标头块限制，而对总解码标头大小没有相应限制，
  从而允许攻击者通过特制的 HTTP/2 请求触发过多的内存消耗。

## 变更 {#changes}

- **修复** 修复了当父 `Gateway` 使用手动部署时，
  通过 `ListenerSet` 定义的 HTTPS 侦听器无法传递 TLS 证书的问题。
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **修复** 修复了以下问题：具有无效标头值的 `HTTPRoute` 和
  `GRPCRoute` 过滤器会从 Envoy 配置中静默删除，而不是报告无效的过滤器状态。
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **修复** 修复了一个 Ambient 模式错误，其中单个 `Service` 将
  `publishNotReadyAddresses: true` 与 `PreferSameZone` 或
  `PreferSameNode` 流量分配相结合，导致 ztunnel 使用相同的流量分配预设为每个其他 `Service`
  接收 `healthPolicy: AllowAll`，导致流量被路由到集群范围内未就绪的端点。
  ([Issue #60422](https://github.com/istio/istio/issues/60422))
