---
title: ISTIO-SECURITY-2026-006
subtitle: 安全公告
description: Envoy 报告的 CVE，以及针对 EnvoyFilter 控制平面拒绝服务和 Sidecar 上的 BackendTLSPolicy 故障开放的 Istio 安全修复。
cves: [CVE-2026-73513, CVE-2026-73552, CVE-2026-73512, CVE-2026-73547, CVE-2026-73549, CVE-2026-50572, CVE-2026-73546, CVE-2026-48521, CVE-2026-73551, CVE-2026-73511, CVE-2026-73548, CVE-2026-73550, CVE-2026-73553]
cvss: "7.7"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:N/I:N/A:H"
releases: ["1.29.0 to 1.29.6", "1.30.0 to 1.30.3"]
publishdate: 2026-08-27
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

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

### Istio CVEs

### Istio CVE {istio-cves}

- [GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx) (CVSS score 6.8, Moderate)：
  当 CA 引用未解析时，`BackendTLSPolicy` 无法在 Sidecar 代理上打开明文。
  由 [@thc1006](https://github.com/thc1006) 报告。

## 通过 `EnvoyFilter` `proxyVersion` 控制平面拒绝服务{#control-plane-denial-of-service-via-envoyfilter-proxyversion}

`EnvoyFilter` 资源中的 `proxyVersion` 匹配表达式 (`spec.configPatches[].match.proxy.proxyVersion`) 接受无限长度的正则表达式。
Istiod 在准入验证期间编译此表达式，并在配置分发期间再次编译此表达式。
有权在单个命名空间中创建 `EnvoyFilter` 资源的用户可以提交非常大的表达式，
从而导致 istiod 中内存和 CPU 使用率过高，从而可能导致控制平面崩溃。
由于验证 Webhook 配置为失败关闭，因此当 istiod 不可用时，
网格中所有命名空间的配置更改都会被拒绝，从而将影响扩展到攻击者自己的命名空间之外。

较旧的、不受支持的 Istio 版本也会受到影响。

`proxyVersion` 匹配表达式现在限制为 1024 个字符。

## 我受到影响了吗？{#am-i-impacted}

- **Envoy CVE：**如果您运行受影响的 Istio 版本（该版本捆绑了受影响的 Envoy 代理），
  您可能会受到影响。具体暴露程度取决于所使用的功能（例如 HTTP/3、`ext_authz`、RBAC 或管理统计接口）；请参阅上面的每个 CVE。

- **EnvoyFilter 拒绝服务：**如果允许网格管理员以外的用户创建或更新 `EnvoyFilter` 资源，
  例如在基于命名空间的多租户环境中，您会受到影响。只有管​​理员可以管理 `EnvoyFilter`
  资源的网格不会暴露于不受信任的输入，但仍应升级。

- **`BackendTLSPolicy` 失败开放：**如果您对网格（Sidecar）上游流量使用 `BackendTLSPolicy`，
  并且策略的 `caCertificateRefs` 可能变得无法解析（例如，
  引用的 `ConfigMap` 被删除、重命名或不存在），您会受到影响。在这种情况下，
  Sidecar 以明文形式发送上游流量而不是阻止它，从而丢失策略所需的加密和 CA 验证。
  网关（入口）代理不受影响；他们失败了。

## 缓解措施 {#mitigation}

- 对于 Istio 1.30 用户：升级到 **1.30.4** 或更高版本。
- 对于 Istio 1.29 用户：升级到 **1.29.7** 或更高版本。
- 作为针对 `EnvoyFilter` 拒绝服务的临时措施，使用 Kubernetes RBAC
  将 `EnvoyFilter` 创建和更新权限限制为受信任的管理员。

Istio 安全委员会感谢 [`Artem Cherezov`](https://github.com/cherez0ff) 和 [`@thc1006`](https://github.com/thc1006) 负责任地披露这些问题。
