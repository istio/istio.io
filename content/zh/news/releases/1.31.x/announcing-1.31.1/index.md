---
title: 发布 Istio 1.31.1
linktitle: 1.31.1
subtitle: 补丁发布
description: Istio 1.31.1 补丁发布。
publishdate: 2026-09-21
release: 1.31.1
aliases:
    - /zh/news/announcing-1.31.1
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.31.0 和 Istio 1.31.1 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

### Istio CVE {#istio-cves}

- __[GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx)__ (CVSS score 6.8, Moderate)：
  当 CA 引用无法解析时，`BackendTLSPolicy` 会在 Sidecar 代理上故障开放，回退为明文。

## 变更 {#changes}

- **改进** 改进了为给定工作负载获取 `PeerAuthentications` 时的性能。

- **更新** 更新了 Kiali 插件至版本 v2.31.0。

- **修复** 修复了 Ambient 模式下的一个问题：CNI 节点代理自动检测到的
  iptables 后端（`legacy` 或 `nft`）可能会在代理重启前后发生变化，
  导致重复的重定向规则被写入已纳管的 Pod 中。
  ([Issue #61020](https://github.com/istio/istio/issues/61020))

- **修复** 修复了无法通过将 `ca-crl.pem` 指定为空字符串或将其删除
  来清除证书吊销列表（CRL）的问题。
  ([Issue #61073](https://github.com/istio/istio/issues/61073))

- **修复** 修复了 JWKS 解析器强制所有公钥获取都使用 HTTP/1.1 的问题。
  用于 TLS 固定和 CIDR 阻止的自定义 `TLSClientConfig` 和 `DialContext`
  导致 Go 的 `net/http` 禁用了自动 HTTP/2，因此 ALPN 从未协商出 h2。
  现在已重新启用 HTTP/2（与 `http.DefaultTransport` 一致），
  从而修复了通过某些 HTTP CONNECT 代理使用 HTTP/1.1 时会失败的 JWKS 获取。
  ([Issue #61250](https://github.com/istio/istio/issues/61250))

- **修复** 修复了 istiod 的 CPU 使用率随着 `AuthorizationPolicies` 数量的增加而增加的问题。
  ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **修复** 修复了在仅支持 IPv6 的集群中，由于 Envoy 使用 IPv4 环回地址访问 DNS 代理，
  导致 `ALLOW_ANY_DYNAMIC_DNS` 流量失败的问题。
  ([Issue #61330](https://github.com/istio/istio/issues/61330))

- **修复** 修复了 istiod 在将工作负载元数据推送到 Envoy 代理时重复序列化相同工作负载的问题。
  ([Issue #61502](https://github.com/istio/istio/issues/61502))

- **修复** 修复了在启用 `AMBIENT_SCOPED_ADDRESS_PUSHES`（默认启用）时，
  订阅工作负载元数据发现（MDS）的 Envoy 代理收不到仅涉及地址变更的增量工作负载更新的问题。

- **修复** 修复了当某个服务仅通过 `istio.io/use-waypoint-canary` 标签
  将 agentgateway waypoint 引用为其金丝雀时，该 waypoint 未被配置该服务所附加的路由和策略的问题。
  转移到金丝雀 waypoint 的连接会被拒绝，因为该 waypoint 没有其所代理服务的配置。
  ([Issue #61036](https://github.com/istio/istio/issues/61036))

- **修复** 修复了影响 Istiod Ambient 多集群模式的内存泄漏问题：
  轮换远程集群的凭证会泄漏该集群的全部缓存状态。
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **修复** 修复了 `istioctl analyze` 直接基于 `istio-system` 中的多集群 Secret
  构建 Kubernetes 客户端，而未对 kubeconfig 进行清理的问题。
  这可能使精心构造的 Secret 在运行 `istioctl` 的机器上执行 `exec` 凭证插件
  （或通过其他不安全的身份验证字段读取本地文件）。
  现在，kubeconfig 的清理方式与 istiod 清理这些 Secret 的方式相同。

  **致谢**：此漏洞由 Adam Korczynski 发现并报告。

- **修复** 修复了 `istio.io/use-waypoint-canary` 标签会绕过 `serviceEntryVisibility`
  NAMESPACE 隔离的问题：可见性为 NAMESPACE 的 `ServiceEntry`
  可以将其金丝雀份额的流量路由到另一个命名空间中的 waypoint。
  现在，金丝雀 waypoint 与主 waypoint 一样，会受到相同的跨命名空间拒绝规则约束。

  **致谢**：此问题由 Raphael Zanarelli 报告。

- **修复** 修复了 `default` Chart 的 `ValidatingWebhookConfiguration`
  仍然硬编码 `failurePolicy: Ignore` 的问题。这会导致在使用服务器端应用执行 `helm upgrade` 时，
  出现与先前已在 `base` 和 `istiod` Chart 中修复过的相同的字段管理器冲突。
  ([Issue #61613](https://github.com/istio/istio/issues/61613))

- **修复** 修复了 istiod 会为每个发送了 `initial_resource_versions` 的 Envoy MDS
  （WDS，用于遥测元数据查找）连接永久保留一份所有工作负载资源名称副本的问题。

- **修复** 修复了 `sidecar.istio.io/statsFlushInterval` 注解在取值为一分钟或更长、
  以及小于一秒时会生成无效的 Envoy 引导配置，从而导致代理无法启动的问题。

- **修复** 修复了 `sidecar.istio.io/statsEvictionInterval` 注解会静默截断亚秒级精度的问题。

- **修复** 修复了一个 Gateway API 问题：跨命名空间的 TLS `certificateRef` 或 `caCertificateRef`
  会在 `ReferenceGrant` 授权检查之前被解析，因此即使没有任何 `ReferenceGrant` 允许该引用，
  侦听器的 `ResolvedRefs` 状态也能反映出所引用的 Secret 或 ConfigMap 是否存在。
  现在会先执行授权检查，对于任何未经授权的跨命名空间引用都返回 `RefNotPermitted`。

  **致谢**：此问题由 Darryl Jaskolski 报告。

- **修复** 修复了 istiod 获取 `RequestAuthentication` `jwksUri` 时存在的 SSRF 防护缺口。
  现在，istiod 默认会在建立连接时阻止链路本地地址和已知的云元数据地址（例如 `169.254.169.254`），
  并拒绝不是有效 JWKS 的获取响应。私有地址段和环回地址段仍可访问，
  并且可以通过 `BLOCKED_CIDRS_IN_JWKS_URIS` 进行阻止。

- **修复** 修复了 Ambient 多集群模式中的内存泄漏问题：集合会注册到 krt 调试器中，
  但在删除远程集群或其配置发生变化时从未取消注册，导致调试器注册项随时间不断累积。
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **修复** 修复了侦听器冲突跟踪会将命名空间和名称都相同的 `Gateway` 与 `ListenerSet`
  视为同一对象的问题。这会导致为其中一个对象记录的冲突把另一个对象中胜出的侦听器
  标记为 `Conflicted`，并导致其配置无法下发。

- **修复** 修复了工作负载选择器存在但为空的 ServiceEntry 会错误地匹配其命名空间中所有工作负载的问题。

- **修复** 修复了远程集群中被 `ServiceEntry` 选中的 Pod 在成为该服务的端点时可能不会被重新计算的问题。
  重新计算被发往了 istiod 所在的集群，而不是该 Pod 所属的集群。

- **修复** 修复了被 `Service` 选中的 WorkloadEntry 在成为该服务的端点时，
  其对应的代理不会被重新计算的问题。

- **修复** 修复了多个 `sidecar.istio.io/*` 注解
  （`proxyImage`、`bootstrapOverride`、`logLevel`、`componentLogLevel`、`agentLogLevel`）
  在未进行输出转义的情况下被插入到 Sidecar/网关注入模板中的问题，
  这可能使精心构造的注解值向生成的 Pod 或 Deployment 规约中注入额外的字段。
  现在，这些注解在每个模板输出位置都会被一致地转义。

  **致谢**：此漏洞由 localhost-detect 发现并报告。

- **修复** 修复了当资源被再次修改而先前的状态写入仍在排队时，
  `observedGeneration` 会停留在过时值上的问题。
