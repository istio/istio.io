---
title: 发布 Istio 1.29.3
linktitle: 1.29.3
subtitle: 补丁发布
description: Istio 1.29.3 补丁发布。
publishdate: 2026-05-18
release: 1.29.3
aliases:
    - /zh/news/announcing-1.29.3
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.29.2 和 Istio 1.29.3 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加对 Gateway API v1.4.1 的支持。

- **新增** 添加了一项 `istioctl analyze` 警告 (IST0175)，
  用于提示当存在 `RequestAuthentication` 资源，但 istiod 上未配置 `BLOCKED_CIDRS_IN_JWKS_URIS` 的情况。
  ([Issue #59523](https://github.com/istio/istio/issues/59523))

- **新增** 添加了特性标志 `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE`
  和 `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`。
  通过它们，可以配置 HBONE 连接（针对 waypoint 和东西向网关生成）至上游集群时的初始流窗口大小和连接窗口大小。
  利用这些配置，有助于减少不必要的缓冲。
  ([Issue #59961](https://github.com/istio/istio/issues/59961))

- **修复** 修复了一个问题：istiod 可能会签发其 `NotAfter` 时间晚​​于签发证书过期时间的叶证书。
  ([Issue #59768](https://github.com/istio/istio/issues/59768))

- **修复** 修复了多集群 Secret 控制器中一处可能在远程集群更新期间发生的死锁问题。
  ([Issue #59875](https://github.com/istio/istio/issues/59875))

- **修复** 修复了 `AuthorizationPolicy` 在匹配 SPIFFE 身份和命名空间时存在的授权绕过漏洞。
  在生成的 Envoy 配置中，`source.principals`（后缀匹配）和
  `source.namespaces` 等字段中的正则表达式元字符未被正确转义，
  这可能导致非预期的身份意外匹配到策略规则。

- **修复**：在使用“Pod 安全组”（即分支 ENI）的 AWS EKS 环境中，
  Ambient 网格 Pod 出现 kubelet 健康探针失败的问题。
  Istio-CNI 现在能够识别分支 ENI Pod，并添加 IP 规则，
  将探针流量通过 veth 对进行路由，而非经由 VPC 网络架构。
  此功能受特性标志 `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` 控制（默认启用）。

- **修复** 修复了一个问题：`istioctl ztunnel-config service`
  命令的 JSON 和 YAML 输出中，未包含来自 ztunnel 配置转储的 `canonical` 字段。
  ([Issue #59962](https://github.com/istio/istio/issues/59962))

- **修复** 由 `StatusGen` 提供的 XDS 调试端点（`istio.io/debug/syncz` 和 `istio.io/debug/config_dump`）现已强制执行同命名空间授权，
  以限制非系统调用者。此前，来自任意命名空间的已认证工作负载均可枚举代理，
  并获取其他命名空间内工作负载的配置转储。

**致谢**：此漏洞由 [1seal](https://github.com/1seal) 发现并报告。

## 安全更新 {#security-update}

- **修复** 修复了 `AuthorizationPolicy` 中的一处授权绕过漏洞：在某些身份字段中，
  正则表达式元字符被直接嵌入到生成的 Envoy `SafeRegex` 规则中，
  而未进行转义。因此，包含诸如 `.` 或 `[` 等字符的合法 Kubernetes 名称可能会被误解析为正则表达式通配符，
  从而允许了超出策略制定者预期的身份通过验证。此问题影响了
  `source.principals`（具体而言是那些以 `*` 开头的后缀匹配规则）以及 `source.namespaces`。
  ([Issue #59992](https://github.com/istio/istio/issues/59992))

**致谢**：此漏洞由 [Alex](https://github.com/Alex0Young) 发现并报告。
