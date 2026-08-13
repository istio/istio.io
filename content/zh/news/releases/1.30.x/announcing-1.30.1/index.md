---
title: 发布 Istio 1.30.1
linktitle: 1.30.1
subtitle: 补丁发布
description: Istio 1.30.1 补丁发布。
publishdate: 2026-06-04
release: 1.30.1
aliases:
    - /zh/news/announcing-1.30.1
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.30.0 和 Istio 1.30.1 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

- [CVE-2026-47774](https://github.com/envoyproxy/envoy/security/advisories/GHSA-22m2-hvr2-xqc8) (CVSS score 7.5, High)：
  未经身份验证的远程攻击者可能会耗尽 Envoy 进程中的内存，从而导致拒绝服务。
  在请求标头大小验证期间未完全考虑 Cookie 标头字节，
  并且对编码字节强制执行 HPACK 标头块限制，而对总解码标头大小没有相应限制，
  从而允许攻击者通过特制的 HTTP/2 请求触发过多的内存消耗。

## 变更 {#changes}

- **更新** 更新了 Kiali 插件到版本至 `v2.26.0`。

- **新增** 添加了当 `BackendTLSPolicy` 或 `XBackendTrafficPolicy`
  对象上的 `istio.io/ignore-policy-attachment` 注解设置为 `"true"` 时，
  从 Istio 排除策略配置的支持。当特定策略用于与 Istio 不同的网关控制器时，
  这允许用户防止将特定策略转换为 Istio 配置。
  ([Issue #60122](https://github.com/istio/istio/issues/60122))

- **新增** 添加了初始化检查，验证捆绑的 `nft` 二进制文件是否支持 JSON 输出。
  本机 nftables 后端需要 JSON 在 Pod 删除期间读取配置。
  在 `nft` 二进制文件不支持 JSON 的主机上，每次删除时这些调用都会失败并显示
  `Error: JSON support not compiled-in`，并且 CNI 代理会无限期地重试。
  新的检查在启动时检测到此错误并回退到 iptables 后端。
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **新增** 添加了 `istioctlanalyze` 检查 `IST0176`，
  标记安装的 Gateway API CRD 的版本低于当前 Istio 版本所需的最低版本。
  此类 CRD 支持的资源会被 istiod 静默过滤，以前使用过时的 Gateway API CRD
  升级到 Istio 1.30 后，很难发现 TLS 直通损坏。

- **修复** 修复了 Gateway API 上的 `BackendTLSPolicy` 冲突解决。
  ([Issue #57817](https://github.com/istio/istio/issues/57817))

- **修复** 修复了当父 `Gateway` 使用手动部署时，
  通过 `ListenerSet`
  定义的 HTTPS 侦听器无法传递 TLS 证书的问题。
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **修复** 修复了以下问题：具有无效标头值的 `HTTPRoute` 和
  `GRPCRoute` 过滤器会从 Envoy 配置中静默删除，而不是报告无效的过滤器状态。
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **修复** 修复了当一个网络上的入口调用另一网络上的服务时，
  即使 `Service` 配置为 `istio.io/ingress-use-waypoint`，
  多网络环境也不会路由到 waypoint 的问题。

- **修复** 修复了由于 Envoy 回归（`envoyproxy/envoy#45212`），
  在批量更新期间不会在端点更改上重建 `RING_HASH` 环，
  因此 `DestinationRule` 中的 `consistencyHash`
  负载平衡在扩展后不会将流量发送到新端点的问题。
  ([Issue #60312](https://github.com/istio/istio/issues/60312))

- **修复** 修复了当两个 Pod 同时添加到同一节点上的 Ambient 网格时，
  istio-cni 代理中出现致命的 `concurrent map writes` 恐慌。
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **修复** 修复了一个 Ambient 模式错误，其中单个 `Service` 将
  `publishNotReadyAddresses: true` 与 `PreferSameZone` 或
  `PreferSameNode` 流量分配相结合，导致 ztunnel 使用相同的流量分配预设为每个其他 `Service`
  接收 `healthPolicy: AllowAll`，导致流量被路由到集群范围内未就绪的端点。
  ([Issue #60422](https://github.com/istio/istio/issues/60422))

- **修复** 修复了 Pilot 为代理网关生成的配置忽略了 `ListenerSet` 资源和附加到它们的路由的问题。
  Pilot 现在可以在代理网关配置中正确包含 `ListenerSet` 资源，
  使 Istio 中的代理网关能够正确处理 `ListenerSet` 资源。

- **修复** 修复了当代理网关的父 `Gateway` 资源不允许 `ListenerSet` 时，
  `ListenerSet` 状态报告。当父 `Gateway` 不允许 `ListenerSet` 时，
  `Accepted` 条件状态现在正确报告为 `False`。
  此外，鉴于 `ListenerSet` 功能在 Gateway API `v1.5.0` 中不是实验性的，
  因此它不再受 `PILOT_ENABLE_ALPHA_GATEWAY_API` 功能标志的保护。

- **修复** 修复了网关的外部 SDS 提供程序使用凭证名称（去除 `sds://` 前缀后）作为 SDS
  资源名称而不是提供程序名称。这允许使用同一 SDS 提供商的多个网关请求不同的证书。
  对于双向 TLS，CA 证书资源名称正确派生为 `<credential-name>-cacert`。
  当 UDS 套接字和 SDS 扩展提供程序均未配置时，网关现在会回退到通过
  ADS（Kubernetes `Secrets`）获取证书，而不是默默地失败。
  ([Issue #57080](https://github.com/istio/istio/issues/57080))

- **修复** 修复了多集群 `ClusterStore` 中的死锁，
  其中 `AllReady`
  可以在写入者等待时递归获取存储 `RWMutex` 以通过 `triggerRecomputeOnSync` -> `GetByID` 读取，
  从而阻止对存储的进一步读取和写入。
