---
title: 发布 Istio 1.29.7
linktitle: 1.29.7
subtitle: 补丁发布
description: Istio 1.29.7 补丁发布。
publishdate: 2026-08-27
release: 1.29.7
aliases:
    - /zh/news/announcing-1.29.7
---

此版本包含一些安全修复，以提高稳定性。
本发行说明描述了 Istio 1.29.6 和 Istio 1.29.7 之间的区别。

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

- **升级** Istio distroless 镜像使用的 `nftables` 的升级版本。
  `nftables` 版本之前固定为 1.1.1，以避免在 Istio 使用打包在同一节点上的镜像中的新版本后，
  可能导致 K8s 节点上的旧版本 `nftables` 崩溃的错误。
  主要 Linux 发行版已获悉该问题并已发布修复程序。因此，
  Istio 正在删除 `nftables` 版本固定。建议用户将节点上的 `nftables` 软件包更新到最新可用版本，
  以确保安装修复版本。如果您的节点上继续遇到 `nftables` 崩溃，
  请降级到较旧版本的 Istio，并联系您的节点操作系统提供商以请求将修复程序修补到您的操作系统版本中。
  ([Issue #58492](https://github.com/istio/istio/issues/58492))

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

- **修复** 修复了 `istio-cni` 认为 `hostNetwork` Pod 符合 Ambient 注册条件的问题。
  ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **修复** 修复了 `istio-cni` 节点代理中的文件描述符泄漏：
  当 `procfs` 扫描发现同一 Pod 的多个网络命名空间时，
  失败候选者的 netns 文件描述符将被删除而不关闭，从而将命名空间固定在内核中直到垃圾回收。

- **修复** 修复了一个错误，当扫描期间第三方进程位于该命名空间内时，
  `istio-cni` 节点代理可以将 Ambient Pod 与另一个 Pod 的网络命名空间配对，
  这可能会导致流量使用错误的身份进行代理。节点代理现在会在注册 Pod 之前验证命名空间是否拥有 Pod 的 IP 之一。
  ([Issue #61211](https://github.com/istio/istio/issues/61211))

- **修复** 修复了 istiod 永久保留发送 `initial_resource_versions` 的每个
  Envoy MDS（WDS，用于遥测元数据查找）连接的每个工作负载资源名称的副本的问题。

- **修复** 修复了 ztunnel 重新连接（例如从 `keepaliveMaxServerConnectionAge` 定期连接回收）触发完整工作负载 (WDS) 推送的错误。
  Istiod 现在为每个 WDS 资源分配一个基于内容的版本，并且当重新连接的客户端通过
  `initial_resource_versions` 报告其已持有的版本时，
  仅重新发送在客户端断开连接时发生更改的资源。不报告版本的较旧 ztunnel 版本将继续接收完整集。
  ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **修复** 修复了 Gateway API 问题，其中跨命名空间 TLS `certificateRef`
  或 `caCertificateRef` 在 `ReferenceGrant` 授权检查之前已解析，
  因此侦听器的 `ResolvedRefs` 状态可以显示引用的 `Secret` 或 `ConfigMap` 是否存在，
  即使没有授权允许引用。现在，授权首先运行，对于授权不允许的任何跨命名空间引用返回 `RefNotPermitted`。
  **来源**：此问题由 Darryl Jaskolski 报告。

- **修复** 修复了 istiod 的 `RequestAuthentication` `jwksUri` 获取中的 SSRF 差距。
  istiod 现在默认在拨号级别阻止链接本地和已知云元数据地址（例如 `169.254.169.254`），
  并拒绝获取的不是有效 JWKS 的响应。私有和环回范围仍然可以访问，
  并且可以使用 `BLOCKED_CIDRS_IN_JWKS_URIS` 进行阻止。

- **修复** 修复了 XDS `api` 生成器（MCP 配置服务）以需要经过验证的控制平面身份。
  以前，任何可以访问 Istiod 的 XDS 端口的客户端都可以跨所有命名空间读取 Istio 配置。
  默认 `ENABLE_XDS_API_GENERATOR_AUTH=true`；如果需要兼容性，
  请使用 `ENABLE_XDS_API_GENERATOR_AUTH=false` 禁用。

- **修复** 修复了多个 `sidecar.istio.io/*` 注解
  （`proxyImage`、`bootstrapOverride`、`logLevel`、`componentLogLevel`、`agentLogLevel`）
  被插入到 Sidecar/网关注入模板中而没有输出转义，
  这可能允许精心设计的注解值将其他字段注入到生成的 Pod 或部署规范中。
  这些注释现在在每个模板接收器中一致地转义。**来源**：此漏洞是由 `localhost-detect` 发现并报告的。

- **修复** 修复了当远程集群被删除或更新时，Ambient 多集群模式下 istiod 中的 goroutine 和内存泄漏。
  为每个远程集群构建的内部集合在拆除时不会释放它们在输入上注册的事件处理程序，
  导致 goroutine 和内存随着集群被删除或重新配置而随着时间的推移而累积。
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **修复** 修复了 istiod 领导者选举中的一个 goroutine 泄漏，
  其中每个选举周期（领导权丢失和重新获得）都会泄漏一个 goroutine，直到进程退出。
  ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **修复** 修复了 istiod CPU 使用率随着 `AuthorizationPolicy` 资源数量的增加而增加的问题。
  ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **修复** 修复了当两个侦听器名称清理为相同的服务端口名称（名称仅在句点与破折号不同，或仅超过 63 个字符的限制）时，
  生成的网关 `Service` 被拒绝，这会阻止网关上的每个未发布的端口。
  现在，冲突的端口名称与侦听器的端口号已消除歧义。

- **改进** 为给定工作负载获取 `PeerAuthentication` 资源时的性能。
