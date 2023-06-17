---
title: 发布 Istio 1.6.5
linktitle: 1.6.5
subtitle: 补丁更新
description: Istio 1.6.5 补丁更新.
publishdate: 2020-07-09
release: 1.6.5
aliases:
    - /news/announcing-1.6.5
---

此版本解决了[我们2020年7月9日的安全公告](/zh/news/security/istio-security-2020-008)中描述的安全漏洞。

此版本包含修复错误以提高健壮性。本版本说明介绍了 Istio 1.6.5 和 Istio 1.6.4 之间的差异。

{{< relnote >}}

## 安全更新

- __[CVE-2020-15104](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-15104)__：在验证 TLS 证书时，Envoy 错误地允许通配符 DNS 主体替代名称应用于多个子域。例如，使用 `*.example.com` 的 SAN，Envoy 错误地允许 `nested.subdomain.example.com`，而应该只允许 `subdomain.example.com`。
    - CVSS 评分: 6.6 [AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C&version=3.1)

## 变更

- **修复** 当 Mixer 按 IP 查找时，返回具有相同 IP 的多个 Pod 的正确源名称。
- **改进** 在每个 Pod 级别基于版本改进了 Sidecar 注入控制([Issue 24801](https://github.com/istio/istio/issues/24801))
- **改进** `istioctl validate` 以禁止未包含在 Open API 规范中的未知字段 ([Issue 24860](https://github.com/istio/istio/issues/24860))
- **更新** 在 Envoy 的引导文件中将 `stsPort` 改为 `sts_port`。
- **保留** 现有 WASM 状态模式，以便稍后根据需要引用它。
- **新增** 向 `stackdriver_grpc_service` 添加了 `targetUri`。
- **更新** 用于访问日志服务的 WASM 状态。
- **新增** 将默认协议检测超时时间从 100 ms 增加到 5 s ([Issue 24379](https://github.com/istio/istio/issues/24379))
- **删除** 从 Istiod 中删除了 UDP 端口53。
- **允许** 将 `status.sidecar.istio.io/port` 设置为零 ([Issue 24722](https://github.com/istio/istio/issues/24722))
- **修复** 当子集没有或标签选择器为空时的 EDS 端点选择。([Issue 24969](https://github.com/istio/istio/issues/24969))
- **允许** `BaseComponentSpec` 上的 `k8s.overlays`。([Issue 24476](https://github.com/istio/istio/issues/24476))
- **修复** 在设置了 `ECC_SIGNATURE_ALGORITHM` 时创建 _elliptical_ 曲线 CSR 的 `istio-agent`。
- **优化** 将 gRPC 状态代码映射到 HTTP 领域中以进行遥测的方法。
- **修复** Istiod 中的 `HorizontalPodAutoscaler` 修复了 `scaleTargetRef` 命名 ([Issue 24809](https://github.com/istio/istio/issues/24809))