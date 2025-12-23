---
title: 发布 Istio 1.28.2
linktitle: 1.28.2
subtitle: 补丁发布
description: Istio 1.28.2 补丁发布。
publishdate: 2025-12-22
release: 1.28.2
aliases:
    - /zh/news/announcing-1.28.2
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.28.1 和 Istio 1.28.2 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

- [CVE-2025-62408](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fg9g-pvc4-776f)
  (CVSS score 5.3, Moderate)：释放后使用漏洞可能导致 Envoy 因 DNS 故障或被入侵而崩溃。
  这是 c-ares 库中的一个堆释放后使用漏洞，攻击者可以通过控制本地
  DNS 基础设施来利用此漏洞对 Envoy 发起拒绝服务 (DoS) 攻击。

## 变更 {#changes}

- **修复** 修复了在罕见的竞态条件下，即删除与同一命名空间中的另一个 `ServiceEntry`
  共享主机名的 `ServiceEntry` 时，偶尔会导致 Ambient 客户端失去向该主机名发送流量的能力，直到 istiod 重新启动。

- **修复** 修复了从 Ambient 后端 iptables 升级到 nftables 后，
  网络中 iptables 规则失效的问题。现在，代码会继续在节点上使用 iptables，直到节点重启。
  ([Issue #58353](https://github.com/istio/istio/issues/58353))

- **修复** 修复了无头服务的 DNS 名称表创建问题，其中 Pod 条目没有考虑到 Pod 可能有多个 IP 地址。
  ([Issue #58397](https://github.com/istio/istio/issues/58397))

- **修复** 修复了注解 `sidecar.istio.io/statsEvictionInterval`
  的值大于等于 60 秒时导致 `istio-proxy` Sidecar 启动失败的问题。
  ([Issue #58500](https://github.com/istio/istio/issues/58500))

- **修复** 修复了 Envoy 代理连接到航点代理时，在极少数情况下会获得多余的 XDS 更新或完全错过某些更新的问题。
