---
title: ISTIO-SECURITY-2026-007
subtitle: 安全公告
description: Envoy 报告的 CVE，以及针对 HTTP/2 上利用方法大小写绕过 AuthorizationPolicy 问题和 Ambient 模式下 istiod 拒绝服务问题的 Istio 安全修复。
cves: []
cvss: "7.7"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:N/I:N/A:H"
releases: ["1.31.0 to 1.31.1", "1.30.0 to 1.30.5", "1.29.0 to 1.29.8"]
publishdate: 2026-10-15
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[GHSA-8vc2-jrm4-835w](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8vc2-jrm4-835w)__: (CVSS score 7.5)：
  修复了 OAuth2 HTTP 过滤器在处理不带 `:path` 标头的 CONNECT 请求时，
  可被未经身份验证的远程攻击者触发的崩溃（空指针解引用）问题。

- __[GHSA-47vj-9r25-wv5j](https://github.com/envoyproxy/envoy/security/advisories/GHSA-47vj-9r25-wv5j)__: (CVSS score 6.5)：
  修复了 `api_key_auth` HTTP 过滤器在对不带 `:path` 标头的 CONNECT 请求隐藏凭证时发生崩溃的问题。

### Istio CVE {#istio-cves}

- __[GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)__ (CVSS score 7.4, High)：
  通过在 HTTP/2 上更改方法的大小写，可以绕过 `AuthorizationPolicy` 的方法规则。
  **致谢**：此漏洞由 [izzy0101010101](https://github.com/izzy0101010101) 发现并报告。

- __[GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)__ (CVSS score 7.7, High)：
  在 Ambient 模式下，当 `ServiceEntry` 或其他服务声明了以
  IP 地址寻址的 waypoint 的地址时，istiod 会崩溃（拒绝服务）。
  **致谢**：此漏洞由 [yshch](https://github.com/yshch) 发现并报告。

## 通过 HTTP/2 绕过 `AuthorizationPolicy` 方法规则 {#authorizationpolicy-method-rules-bypassed-over-http2}

带有 `methods` 的 `AuthorizationPolicy` `DENY` 规则（或带有 `notMethods` 的 `ALLOW` 规则）
会被编译为区分大小写的 `:method` 匹配器。在 HTTP/2 上，如果请求的方法仅在大小写上不同
（例如使用 `post` 而不是 `POST`），该请求就不会匹配该规则，而是会被转发到工作负载，从而绕过策略。
HTTP/1.1 不受影响，因为其编解码器会在授权之前拒绝非大写的方法。
现在，方法匹配已改为不区分大小写。

## 通过 waypoint 地址冲突导致 istiod 拒绝服务 {#istiod-denial-of-service-via-waypoint-address-collision}

在 Ambient 模式下，istiod 仅通过网络和 IP 地址来解析拥有某个以 IP 地址寻址的 waypoint 的服务。
当第二个服务（例如任意命名空间中的 `ServiceEntry`）声明了相同的地址时，
istiod 会发生 Panic 并陷入崩溃循环，直到冲突的资源被删除为止。
有权在自己的命名空间中创建 `ServiceEntry` 资源的用户，
可以借此使整个网格的配置分发和证书轮换陷入停滞。
现在，冲突的地址会被跳过，并记录一条警告。

## 我受到影响了吗？{#am-i-impacted}

- **Envoy CVE**：如果您运行的是受影响的 Istio 版本，并且使用了 OAuth2 或 `api_key_auth` HTTP 过滤器，
  则可能会受到影响。

- **`AuthorizationPolicy` 方法绕过**：如果您使用了带有 `methods` 的 `AuthorizationPolicy` `DENY` 规则
  或带有 `notMethods` 的 `ALLOW` 规则，并且客户端可以通过 HTTP/2 访问工作负载，则会受到影响。
  仅使用带有显式 `methods` 列表的 `ALLOW` 规则的策略不受影响。

- **istiod 拒绝服务**：如果您在 Ambient 模式下使用以 IP 地址寻址的 waypoint
  （例如带有 `networking.istio.io/address-type: IPAddress` 注解的 waypoint `Gateway`），
  并且网格管理员以外的用户可以创建 `ServiceEntry` 资源，则会受到影响。
  报告主机名的 waypoint（默认情况）不受影响。

## 缓解措施 {#mitigation}

- 针对 Istio 1.31 用户：升级至 **1.31.2** 或更高版本。
- 针对 Istio 1.30 用户：升级至 **1.30.6** 或更高版本。
- 针对 Istio 1.29 用户：升级至 **1.29.9**。这是 1.29 的最后一个版本，
  因为 [1.29 已于 2026 年 10 月 15 日结束生命周期](/zh/news/support/announcing-1.29-eol/)。
  请计划升级至 1.30 或更高版本。
- 作为针对 `AuthorizationPolicy` 绕过问题的临时措施，请使用带有显式 `methods` 允许列表的 `ALLOW` 策略，
  而不是 `DENY` 规则或 `notMethods` 规则。
- 作为针对 istiod 拒绝服务问题的临时措施，请使用 Kubernetes RBAC 将 `ServiceEntry`
  的创建和更新权限限制为仅受信任的管理员拥有，或者使用以主机名寻址的 waypoint。

## 其他 Istio 安全修复 {#other-istio-security-fixes}

此版本还包含以下未分配 CVE 的安全修复。有关详细信息，请参阅各版本的发行说明。

- `istioctl` 在使用服务账号令牌连接到 XDS 时，现在会验证 istiod 证书。
  **致谢**：此问题由 [Leon Zlobecki](https://leonz.is) 报告。
- `istioctl manifest translate` 现在会对写入所生成的安装 Shell 脚本中的值进行转义。
  **致谢**：此漏洞由 OpenSec Intelligence 发现并报告。
- 修复了 OIDC/JWT 身份验证器收到 `sub` 声明格式错误的令牌时 istiod 发生 Panic 的问题。
  **致谢**：此问题由 Kaizhe Huang 报告。
- 加固了实验性的 Kubernetes CSR RA 路径（`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`）：
  向调用方返回不透明的错误、使 watch 循环受超时约束，并新增 `MAX_RA_WORKLOAD_CERT_TTL` 上限。
  **致谢**：此问题由 Juno Im 报告。
- 对于未在 `WASM_INSECURE_REGISTRIES` 中列出的镜像仓库，Wasm OCI 镜像获取器不再回退到明文 HTTP。
  **致谢**：此漏洞由 Adam Korczynski 发现并报告。
- istiod 调试端点现在要求 `proxyID` 精确匹配。
  **致谢**：此问题由 박현범 报告。
- 为 1.29 和 1.30 添加了 `PILOT_ENABLE_STRICT_GATEWAY_MERGING`，
  以防止 Istio `Gateway` 资源与托管的 Gateway API 网关进行跨命名空间合并。
  该选项在 1.29 和 1.30 中默认禁用，从 1.31 开始默认启用。
