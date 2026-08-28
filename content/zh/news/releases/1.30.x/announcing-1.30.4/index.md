---
title: Announcing Istio 1.30.4
linktitle: 1.30.4
subtitle: Patch Release
description: Istio 1.30.4 patch release.
publishdate: 2026-08-27
release: 1.30.4
aliases:
    - /news/announcing-1.30.4
---

此版本包含一些安全修复，以提高稳定性。
本发行说明描述了 Istio 1.30.3 和 Istio 1.30.4 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

有关更多信息，请参阅 [ISTIO-SECURITY-2026-006](/zh/news/security/istio-security-2026-006)。

### Envoy CVE {#envoy-cves}

- __[CVE-2026-73513](https://nvd.nist.gov/vuln/detail/CVE-2026-73513)__: (CVSS score 7.5)：
  修复了当接收到不带 `END_STREAM` 标志的 HTTP/2 拖挂时 `oghttp2` 中的堆释放后使用问题。
- __[CVE-2026-73552](https://nvd.nist.gov/vuln/detail/CVE-2026-73552)__: (CVSS score 7.5)：
  修复了 `safe_regex` 在负匹配 RBAC 策略中无法打开非 UTF-8 标头字节的错误。
- __[CVE-2026-73512](https://nvd.nist.gov/vuln/detail/CVE-2026-73512)__: (CVSS score 7.5)：
  修复了 QUIC HTTP 数据报处理程序中存在的释放后使用问题。
- __[CVE-2026-73547](https://nvd.nist.gov/vuln/detail/CVE-2026-73547)__: (CVSS score 7.5)：
  修复了处理没有 `:path` 标头的 CONNECT 请求时 `ext_authz` 中的异常终止问题。
- __[CVE-2026-73549](https://nvd.nist.gov/vuln/detail/CVE-2026-73549)__: (CVSS score 5.3)：
  修复了 HTTP/3 范围内 IPv6 客户端地址的异常终止问题。
- __[CVE-2026-50572](https://nvd.nist.gov/vuln/detail/CVE-2026-50572)__: (CVSS score 5.9)：
  修复了 `ext_authz` 原始 HTTP 客户端中存在的释放后使用问题。
- __[CVE-2026-73546](https://nvd.nist.gov/vuln/detail/CVE-2026-73546)__: (CVSS score 7.4)：
  修复了 HTML 统计界面中存储的跨站点脚本漏洞。
- __[CVE-2026-48521](https://nvd.nist.gov/vuln/detail/CVE-2026-48521)__: (CVSS score 5.9)：
  修复了基于 ALPN 的 HTTP/3 连接池选择期间的空指针取消引用。
- __[CVE-2026-73551](https://nvd.nist.gov/vuln/detail/CVE-2026-73551)__: (CVSS score 5.3)：
  修复了带参数的点和点-点路径段的 URL 规范化。
- __[CVE-2026-73511](https://nvd.nist.gov/vuln/detail/CVE-2026-73511)__: (CVSS score 5.3)：
  修复了针对分段参数的路径匹配问题。
- __[CVE-2026-73548](https://nvd.nist.gov/vuln/detail/CVE-2026-73548)__: (CVSS score 7.5)：
  修复了通用 HTTP 升级中的跨用户响应投毒问题。
- __[CVE-2026-73550](https://nvd.nist.gov/vuln/detail/CVE-2026-73550)__: (CVSS score 7.5)：
  通过丢弃重复的主机标头修复了 HTTP/2 内存耗尽问题。
- __[CVE-2026-73553](https://nvd.nist.gov/vuln/detail/CVE-2026-73553)__: (CVSS score 7.5)：
  修复了通过 `ignore_path_parameters_in_path_matching` 绕过 RBAC 的问题。

### Istio CVE {istio-cves}

- [GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx) (CVSS score 6.8, Moderate)：
  当 CA 引用未解析时，`BackendTLSPolicy` 无法在 Sidecar 代理上打开明文。

### 其他 Istio 安全修复 {#other-istio-security-fixes}

- **修复** 修复了 `EnvoyFilter` 验证差距，其中无上限的 `proxyVersion`
  匹配表达式可能会在正则表达式编译期间驱动过多的 istiod 内存和 CPU。
  匹配表达式现在限制为 1024 个字符。**来源**：此问题由 [`Artem Cherezov`](https://github.com/cherez0ff) 报告。

## 变更 {#changes}

- **修复** 修复了 istio-cni 节点代理 Pod 可能无法启动的死锁（例如在节点重新启动后），
  因为在启用 Ambient 模式时，CNI 插件仅跳过为其自己的代理 Pod 创建 Kubernetes 客户端。
  抢占式检查现在也在 Sidecar 模式下运行，因此代理 Pod 不再阻塞尚未写入的 kubeconfig。
  ([Issue #60668](https://github.com/istio/istio/issues/60668))

- **修复** 修复了一个错误，即远程集群的网络网关在凭证轮换后可能会从跨网络路由中消失，
  并且直到 istiod 重新启动后才能恢复。就地注册表交换现在将新注册表重新连接到聚合控制器的处理程序，
  以便其未来的网关和服务事件传播，并重新加载网关一次以获取在预交换同步期间发现的网关。
  ([Issue #60920](https://github.com/istio/istio/issues/60920))

- **修复** 修复了多集群部署中的一个问题，即旋转远程集群的 `istio-remote-secret`
  可能会永久擦除该集群中具有稳定端点的服务的端点分片，从而使它们在重新启动 istiod 之前无法跨集群访问。
  ([Issue #61043](https://github.com/istio/istio/issues/61043))

- **修复** 修复了 istiod 启动时的竞争条件，其中就绪探针可以在专用注入和验证
  Webhook 服务器（`--httpsAddr`，默认 `:15017`）接受连接之前报告准备就绪，
  从而在 istiod 准备就绪后立即创建资源时导致间歇性的 `failed calling webhook` 超时。
  这不会影响 Webhooks 共享主 HTTP 服务器（空 `--httpsAddr`）的部署。
  ([Issue #61049](https://github.com/istio/istio/issues/61049))

- **修复** 修复了当远程工作负载位于不同网络上时，
  入口网关绕过多集群服务的 waypoint 代理，导致授权策略无法执行的问题。
  ([Issue #61092](https://github.com/istio/istio/issues/61092))

- **修复了** 修复了在 istiod 启动期间可能永久无法创建网关代理 `Deployment` 资源的问题。
  ([Issue #61095](https://github.com/istio/istio/issues/61095))

- **修复** 修复了由 `ServiceEntry` `workloadSelector` 选择的
  Pod 启动时可能会在其 Sidecar 的入站配置中缺少该服务的问题。
  到端口的流量未按照 `ServiceEntry` 中声明的协议进行处理，
  并且未应用端口级 `PeerAuthentication`。该 Pod 无法自行恢复；只有重新启动 istiod 才能修复它。
  ([Issue #61157](https://github.com/istio/istio/issues/61157))

- **修复** 修复了 `istio-cni` 认为 `hostNetwork` Pod 符合 Ambient 注册条件的问题。
  ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **修复** 修复了 `istio-cni` 节点代理中的文件描述符泄漏：
  当 `procfs` 扫描发现同一 Pod 的多个网络命名空间时，
  失败候选者的 netns 文件描述符将被删除而不关闭，从而将命名空间固定在内核中直到垃圾回收。

- **Fixed** external SDS providers configured through `extensionProviders` to use the configured service hostname as the gRPC authority.
- **修复** 修复了通过 `extensionProviders` 配置的外部 SDS 提供程序，
  以使用配置的服务主机名作为 gRPC 权限。

- **修复** 修复了 istiod 领导者选举中的一个 goroutine 泄漏，
  其中每个选举周期（领导权丢失和重新获得）都会泄漏一个 goroutine，直到进程退出。
  ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **修复** 修复了 istiod CPU 使用率随着 `AuthorizationPolicy` 资源数量的增加而增加的问题。
  ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **修复** 修复了主机名和协议冲突的 `ListenerSet` 冲突解决。
  现在可以正确拒绝冲突的侦听器，并且 `ListenerSet` 状态条件报告符合 Gateway API 1.5。
  ([PR #60775](https://github.com/istio/istio/pull/60775))

- **修复** 修复了 ztunnel 重新连接（例如从 `keepaliveMaxServerConnectionAge` 定期连接回收）触发完整工作负载 (WDS) 推送的错误。
  Istiod 现在为每个 WDS 资源分配一个基于内容的版本，并且当重新连接的客户端通过
  `initial_resource_versions` 报告其已持有的版本时，
  仅重新发送在客户端断开连接时发生更改的资源。不报告版本的较旧 ztunnel 版本将继续接收完整集。
  ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **修复** 修复了 XDS `api` 生成器（MCP 配置服务）以需要经过验证的控制平面身份。
  以前，任何可以访问 Istiod 的 XDS 端口的客户端都可以跨所有命名空间读取 Istio 配置。
  默认 `ENABLE_XDS_API_GENERATOR_AUTH=true`；如果需要兼容性，
  请使用 `ENABLE_XDS_API_GENERATOR_AUTH=false` 禁用。

- **修复** 修复了 Gateway API 问题，其中跨命名空间 TLS `certificateRef`
  或 `caCertificateRef` 在 `ReferenceGrant` 授权检查之前已解析，
  因此侦听器的 `ResolvedRefs` 状态可以显示引用的 `Secret` 或 `ConfigMap` 是否存在，
  即使没有授权允许引用。现在，授权首先运行，对于授权不允许的任何跨命名空间引用返回 `RefNotPermitted`。
  **来源**：此问题由 Darryl Jaskolski 报告。

- **修复** 修复了 istiod 的 `RequestAuthentication` `jwksUri` 获取中的 SSRF 差距。
  istiod 现在默认在拨号级别阻止链接本地和已知云元数据地址（例如 `169.254.169.254`），
  并拒绝获取的不是有效 JWKS 的响应。私有和环回范围仍然可以访问，
  并且可以使用 `BLOCKED_CIDRS_IN_JWKS_URIS` 进行阻止。

- **修复** 修复了多个 `sidecar.istio.io/*` 注解
  （`proxyImage`、`bootstrapOverride`、`logLevel`、`componentLogLevel`、`agentLogLevel`）
  被插入到 Sidecar/网关注入模板中而没有输出转义，
  这可能允许精心设计的注解值将其他字段注入到生成的 Pod 或部署规范中。
  这些注释现在在每个模板接收器中一致地转义。**来源**：此漏洞是由 `localhost-detect` 发现并报告的。
