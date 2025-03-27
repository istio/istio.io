---
title: 发布 Istio 1.24.4
linktitle: 1.24.4
subtitle: 补丁发布
description: Istio 1.24.4 补丁发布。
publishdate: 2025-03-25
release: 1.24.4
---


此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.24.3 和 Istio 1.24.4 之间的区别。

{{< relnote >}}

## 安全更新 {#security-updates}

- [CVE-2025-30157](https://nvd.nist.gov/vuln/detail/CVE-2025-30157)
  (CVSS Score 6.5, Medium): 当 HTTP `ext_proc` 处理本地回复时，Envoy 崩溃。

就 Istio 而言，此 CVE 仅在通过 `EnvoyFilter` 配置 `ext_proc` 的情况下可用。

## 变更 {#changes}

- **修复** 修复了网关中大小写混合 Host 和 TLS 重定向导致 RDS 过时的错误。
  ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **修复** 修复了 Ambient `PeerAuthentication` 策略过于严格的问题。
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **修复** 修复了升级到 1.24 版期间无法修补管理网关/waypoint 部署的问题。
  ([Issue #54145](https://github.com/istio/istio/issues/54145))

- **修复** 修复了一个错误，其中 Ambient 模式 `PeerAuthentication`
  策略中的多个 `STRICT` 端口级 mTLS 规则由于不正确的评估逻辑
  （AND 与 OR）实际上会导致过于宽松的策略。
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **修复** 修复了当与 ztunnel 绑定的 AuthorizationPolicy 中存在
  L7 规则时状态消息的措辞，使其更加清晰。
  ([Issue #54334](https://github.com/istio/istio/issues/54334))

- **修复** 修复了请求镜像过滤器错误计算百分比的错误。
  ([Issue #54357](https://github.com/istio/istio/issues/54357))

- **修复** 修复了在网关上使用 `istio.io/rev`
  标签中的标记导致网关编程不当并缺少状态的问题。
  ([Issue #54458](https://github.com/istio/istio/issues/54458))

- **修复** 修复了无序 ztunnel 断开连接可能导致 `istio-cni`
  处于认为没有连接的状态的问题。
  ([Issue #54544](https://github.com/istio/istio/issues/54544)),
  ([Issue #53843](https://github.com/istio/istio/issues/53843))

- **修复** 修复了连接耗尽期间访问日志的顺序导致不稳定的问题。
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

- **修复** 修复了网关 Chart 中 `--set platform` 有效但
  `--set global.platform` 无效的问题。

- **修复** 修复了入口网关未使用 WDS 发现来检索 Ambient 模式目标元数据的问题。

- **修复** 修复了当系统中存在非内置表时导致 `istio-iptables` 命令失败的问题。

- **修复** 修复了当多个服务的 IP 地址部分重叠时导致配置被拒绝的问题。
  例如，一个服务带有 `[IP-A]`，另一个服务带有 `[IP-B, IP-A]`。
  ([Issue #52847](https://github.com/istio/istio/issues/52847))

- **修复** 修复了 DNS 流量（UDP 和 TCP）现在受流量注释
  （如 `traffic.sidecar.istio.io/excludeOutboundIPRanges` 和
  `traffic.sidecar.istio.io/excludeOutboundPorts`）的影响。
  之前，由于规则结构的原因，即使指定了 DNS 端口，UDP/DNS 流量也会唯一地忽略这些流量注释。
  行为变化实际上发生在 1.23 版本系列中，但未包含在 1.23 的发行说明中。
  ([Issue #53949](https://github.com/istio/istio/issues/53949))

- **修复** 修复了验证 Webhook 拒绝原本有效的配置 `connectionPool.tcp.IdleTimeout=0s` 的问题。
  ([Issue #55409](https://github.com/istio/istio/issues/55409))
