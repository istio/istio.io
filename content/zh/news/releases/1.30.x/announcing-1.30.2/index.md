---
title: 发布 Istio 1.30.2
linktitle: 1.30.2
subtitle: 补丁发布
description: Istio 1.30.2 补丁发布。
publishdate: 2026-06-24
release: 1.30.2
aliases:
    - /zh/news/announcing-1.30.2
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.30.1 和 Istio 1.30.2 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **改进** 当集群中安装的 Gateway API CRD 低于此 Istio 版本所需的最低版本时，
  改进日志记录。该消息现在记录在 `warn` 级别，并解释说在 CRD 升级之前不会处理此类资源。
  以前，这是在 `info` 级别记录的并且很容易错过，这使得升级到
  1.30 后使用过时的 CRD 很难诊断 TLS 直通破坏。

- **新增** 在 `AuthorizationPolicy` 中的 `Source` 中添加了
  `trustDomains` 和 `notTrustDomains` 字段，
  允许用户根据从对等证书派生的信任域来匹配或排除请求。

- **新增** 添加了一个新的环境变量 `PILOT_AGENT_MERGE_ENVOY_STATS`
  来控制 pilot-agent 是否将 Envoy 统计信息合并到其统计端点中。
  设置为 `false` 以禁用将 Envoy 统计信息与代理统计信息合并。

- **修复** 修复了更改 Kubernetes `Gateway`（或 `ListenerSet`）上的 `istio.io/rev`
  标签时出现的短暂流量中断。先前拥有的控制平面不再删除资源并将空的
  xDS 配置推送到仍在旧版本上运行的网关 Pod。非拥有修订版的状态写入仍会受到抑制，
  因此修订版不会因彼此的状态而波动。
  ([Issue #59959](https://github.com/istio/istio/issues/59959))

- **修复** 修复了使用 `WasmPlugin` 资源时由于 `TrafficExtension` 转换而导致的重复和过多推送。

- **修复** 修复了以下问题：在节点或 kubelet 重新启动后，
  Ambient 注册的 Pod 可能会被排除在主机运行状况探测 ipset 之外，
  导致 kubelet 探测被重定向到 ztunnel 并被拒绝，直到 `istio-cni` 节点代理重新启动。
  启动时，节点代理可以在 IP 尚未可观察到时从 ipset 中逐出仍注册的 Pod，
  并且现在在协调期间重新断言已注册 Pod 的探测 ipset 成员身份。

- **修复** 修复了 1.29.2 之前的 Sidecar 配置生成。

- **修复** 修复了 `krt` 控制器框架中的内存泄漏，其中更改 `Fetch`
  过滤器中使用的密钥（例如，重新标记 Pod 以指向不同的路径点）留下了从未清理过的陈旧反向索引条目。
  随着时间的推移，这可能会增加内存使用量并导致不必要的重新计算。

- **修复** 修复了当 Envoy 使用 protobuf 内容类型报告指标时，
  试点代理指标合并产生不正确结果的问题。 pilot-agent 无法正确处理 protobuf 内容类型，
  因此允许的内容类型现在仅限于 `text/plain` 和 `application/openmetrics-text`。
  ([Issue #60322](https://github.com/istio/istio/issues/60322))

## 安全更新 {#security-update}

有关更多信息，请参阅 [ISTIO-SECURITY-2026-005](/zh/news/security/istio-security-2026-005)。

### Envoy CVE {#envoy-cves}

- __[GHSA-p7c7-7c47-pwch](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p7c7-7c47-pwch)__: (CVSS score 7.5)：
  修复了 HTTP/3 堆栈中通过 QPACK 阻止解码的拒绝服务漏洞。
  当 QPACK 标头块被阻止等待动态表更新时，标头有效负载字节将从 QUIC 接收流控制记帐中释放，
  同时仍保留在内部解码器堆缓冲区中，从而允许远程攻击者驱动无限内存增长并触发内存不足情况。
- __[CVE-2026-47692](https://nvd.nist.gov/vuln/detail/CVE-2026-47692)__: (CVSS score 4.8)：
  修复了直通 TLV 与添加的 TLV 组合可能超过最大长度，
  导致标头中报告的大小与写入的字节数不匹配的错误。这可能允许来自将
  PROXY 协议标头写入上游主机的主机的走私请求。
- __[CVE-2026-47207](https://nvd.nist.gov/vuln/detail/CVE-2026-47207)__: (CVSS score 6.5)：
  修复了 `ext_proc` 服务器向 Envoy 发送意外 `ProcessingResponses` 的问题。
- __[CVE-2026-47205](https://nvd.nist.gov/vuln/detail/CVE-2026-47205)__: (CVSS score 5.9)：
  修复了当每条路线服务覆盖处于活动状态且下游连接在飞行中授权检查期间重置时，
  ext_authz 过滤器中的释放后使用崩溃问题。
- __[CVE-2026-47220](https://nvd.nist.gov/vuln/detail/CVE-2026-47220)__: (CVSS score 7.5)：
  修复了 `%REQUESTED_SERVER_NAME%` 格式化程序中的崩溃错误，
  其中主机或原始主机设置不正确，但格式化程序配置为访问主机值。
- __[CVE-2026-47221](https://nvd.nist.gov/vuln/detail/CVE-2026-47221)__: (CVSS score 5.9)：
  修复了处理无正文请求的 HTTP 303 内部重定向时的问题。
  重定向处理代码尝试耗尽从未分配的请求正文缓冲区，从而导致分段错误。
- __[CVE-2026-48044](https://nvd.nist.gov/vuln/detail/CVE-2026-48044)__: (CVSS score 7.5)：
  修复了 Zstd 解压缩器中的内存耗尽漏洞，其中仅在完全处理每个输入切片后才检查
  `MaxInflateRatio` 限制，从而允许恶意制作的压缩有效负载在单个 `process()`
  调用中扩展到数百 MB。现在，在内部解压循环内强制执行膨胀比率限制，
  匹配 gzip 和 brotli 解压器，并在突破阈值后立即中止解压。
- __[CVE-2026-48090](https://nvd.nist.gov/vuln/detail/CVE-2026-48090)__: (CVSS score 5.9)：
  修复了一个错误：异步令牌（token）变更回调可能会在过滤器被销毁（即 `onDestroy()` 已被调用）后触发，
  这可能导致访问悬空指针，进而引发 UAF（释放后使用）或程序崩溃。
- __[CVE-2026-47778](https://nvd.nist.gov/vuln/detail/CVE-2026-47778)__: (CVSS score 4.4)：
  修复了以下问题：如果 SAN 包含嵌入的 NUL 字节，则 Envoy
  可能无法验证对等证书的使用者备用名称 (SAN)。以前，
  SAN 解析在某些配置中容易受到 NUL 字节截断的影响，可能导致错误的信任决策。
- __[CVE-2026-47204](https://nvd.nist.gov/vuln/detail/CVE-2026-47204)__: (CVSS score 6.5)：
  修复了当 gRPC 统计过滤器在直接响应路由上执行统计跟踪时发生崩溃或释放后使用的问题。
- __[CVE-2026-48497](https://nvd.nist.gov/vuln/detail/CVE-2026-48497)__: (CVSS score 5.9)：
  修复了查询名称长度的健全性检查，以避免进程异常终止。如果健全性检查失败，请使用 `ENVOY_BUG`。
- __[CVE-2026-48706](https://nvd.nist.gov/vuln/detail/CVE-2026-48706)__: (CVSS score 5.9)：
  修复了统计名称较大时的 `TcpStatsdSink` 缓冲区溢出问题。
- __[CVE-2026-48743](https://nvd.nist.gov/vuln/detail/CVE-2026-48743)__: (CVSS score 7.5)：
  修复了仅 HTTP/3 标头请求和响应内容长度验证以及不一致时重置流的问题。
  该更改由运行时防护 `envoy.reloadable_features.quic_validate_headers_only_content_length` 保护。
- __[CVE-2026-47775](https://nvd.nist.gov/vuln/detail/CVE-2026-47775)__: (CVSS score 6.8)：
  解决了 OAuth2 过滤器的 AES-256-CBC cookie 解密中的填充 oracle。
  该过滤器现在支持带有 `gcm.` 算法标记的 AES-256-GCM 加密，该标记可验证密文并删除预言。
- __[CVE-2026-48042](https://nvd.nist.gov/vuln/detail/CVE-2026-48042)__: (CVSS score 7.5)：
  JSON 嵌套深度限制为 1000。通过将 `envoy.reloadable_features.limit_json_parser_nesting_depth`
  设置为 `false`，可以将限制放宽到 10K。
