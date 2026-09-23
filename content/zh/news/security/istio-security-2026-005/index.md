---
title: ISTIO-SECURITY-2026-005
subtitle: 安全公告
description: Envoy 报告的 CVE 及 Istio 安全修复。
cves: [CVE-2026-47692, CVE-2026-47207, CVE-2026-47205, CVE-2026-47220, CVE-2026-47221, CVE-2026-48044, CVE-2026-48090, CVE-2026-47778, CVE-2026-47204, CVE-2026-48497, CVE-2026-48706, CVE-2026-48743, CVE-2026-47775, CVE-2026-48042]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.30.1 to 1.30.2", "1.29.4 to 1.29.5", "1.28.8 to 1.28.9"]
publishdate: 2026-06-24
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

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
