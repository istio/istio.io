---
title: ISTIO-SECURITY-2026-009
subtitle: 安全公告
description: 针对 Ambient 模式授权和 mTLS 绕过、Sidecar 流量拦截绕过，以及 istiod 和 ztunnel 拒绝服务问题的 Istio 安全修复。
cves: []
cvss: "8.2"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N"
releases: ["1.31.0 to 1.31.3", "1.30.0 to 1.30.7"]
publishdate: 2026-11-06
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Istio CVE {#istio-cves}

- __[GHSA-rr2c-p22p-6r9r](https://github.com/istio/istio/security/advisories/GHSA-rr2c-p22p-6r9r)__ (CVSS score 8.2, High)：
  在 Ambient 模式下，由于一个运算符优先级错误，当在网格范围的 `STRICT` 策略下工作负载模式为
  `PERMISSIVE` 或 `DISABLE` 时，端口级别的 `STRICT` `PeerAuthentication` 会被跳过，
  从而允许明文流量到达要求 mTLS 的端口。
  此漏洞由 Ravikanth Reddy 报告。
- __[GHSA-7m6f-j3gp-2r53](https://github.com/istio/istio/security/advisories/GHSA-7m6f-j3gp-2r53)__ (CVSS score 6.5, Moderate)：
  针对 `request.headers[:authority]` 或 `request.headers[host]` 的 `AuthorizationPolicy` `when` 条件
  以区分大小写的方式进行匹配，因此主机名大小写不同的请求可以绕过该条件。
  此漏洞由 [@akoul](https://github.com/akoul) 报告。
- __[GHSA-cxwg-46mx-q8hf](https://github.com/istio/istio/security/advisories/GHSA-cxwg-46mx-q8hf)__ (CVSS score 7.4, High)：
  复用已拆除连接四元组的新入站连接可能会匹配到过时的 conntrack `ESTABLISHED` 条目，从而绕过 Sidecar 代理。
  此漏洞由 [@ramaraochavali](https://github.com/ramaraochavali)、[@akshayreddyb](https://github.com/akshayreddyb)、
  [@Pawan-Bishnoi](https://github.com/Pawan-Bishnoi) 和 [@deveshkandpal1224](https://github.com/deveshkandpal1224) 报告。
- __[GHSA-635j-qv98-9275](https://github.com/istio/istio/security/advisories/GHSA-635j-qv98-9275)__ (CVSS score 7.7, High)：
  任何具有网格身份的工作负载都可以发送资源名称无法通过 URL 解析的 `istio.io/debug` xDS 请求，
  使 istiod 崩溃，从而导致整个网格的控制平面陷入崩溃循环。
  此漏洞由 Checkmarx Research 的 Alon Lerner 报告。
- __[GHSA-8jw7-82jp-wr2c](https://github.com/istio/istio/security/advisories/GHSA-8jw7-82jp-wr2c)__ (CVSS score 6.3, Moderate)：
  在 Ambient 模式下，如果 `AuthorizationPolicy` 包含未被验证 Webhook 拒绝的空 `to` 或 `from` 条目，
  则会导致 istiod 崩溃并陷入崩溃循环，直到该策略被删除为止。
  此漏洞由 [@r0binak](https://github.com/r0binak) 报告。
- __[GHSA-gf6w-6mxv-5fj4](https://github.com/istio/istio/security/advisories/GHSA-gf6w-6mxv-5fj4)__ (CVSS score 6.3, Moderate)：
  在多集群安装中，代理可以冒充另一个集群的 `CLUSTER_ID`，并通过 SDS 获取该集群的 `kubernetes://` Secret。
  此漏洞由 Yonghwa Lee（Xint by Theori）报告。
- __[GHSA-77vw-rg85-wx5x](https://github.com/istio/istio/security/advisories/GHSA-77vw-rg85-wx5x)__ (CVSS score 6.5, Moderate)：
  ztunnel 在解析不包含四个以短横线分隔字段的 55 字节 `traceparent` 标头时会发生 Panic，
  从而丢弃在该入站 HBONE 连接上多路复用的所有流。
  此漏洞由 [@RaphaelFakhri](https://github.com/RaphaelFakhri) 报告。
- __[GHSA-9gqj-583v-mpqp](https://github.com/istio/istio/security/advisories/GHSA-9gqj-583v-mpqp)__ (CVSS score 5.6, Moderate)：
  在 Ambient waypoint 以及接收 HBONE 流量的 Sidecar 上，`AuthorizationPolicy` 的 `ipBlocks`、`notIpBlocks`
  和 `source.ip` 条件匹配的是 Envoy 内部监听器地址而不是客户端 IP，
  因此基于这些字段的 `DENY` 规则可能会失效放行（fail open）。
  此漏洞由 [@adilfulara](https://github.com/adilfulara) 报告。

### 其他 Istio 安全修复 {#other-istio-security-fixes}

- JWKS 解析器的周期性后台刷新会缓存获取到的响应，而不验证该响应看起来是否为 JWKS。
  现在，后台刷新会应用与同步获取路径相同的检查。
  此问题由 Anthropic 和 Ada Logics 报告。

## 我受到影响了吗？{#am-i-impacted}

- **Ambient 模式**：如果您在 Ambient 模式下使用了 `PeerAuthentication` 资源，
  则可能会受到 `GHSA-rr2c-p22p-6r9r` 的影响；如果使用了 `AuthorizationPolicy` 资源，
  则可能会受到 `GHSA-8jw7-82jp-wr2c` 的影响。
- **授权**：如果您在 `AuthorizationPolicy` 中使用了针对 `request.headers[:authority]`
  或 `request.headers[host]` 的条件，则可能会受到 `GHSA-7m6f-j3gp-2r53` 的影响。
  如果您在应用于 Ambient waypoint 或接收 HBONE 流量的 Sidecar 的策略中使用了 `ipBlocks`、
  `notIpBlocks` 或 `source.ip`，则可能会受到 `GHSA-9gqj-583v-mpqp` 的影响。
  作为临时解决方法，请改用 `remoteIpBlocks`、`notRemoteIpBlocks` 和 `remote.ip`。
- **Sidecar 拦截**：如果您使用 iptables 或 nftables 进行 Sidecar 流量拦截，
  则可能会受到 `GHSA-cxwg-46mx-q8hf` 的影响。
- **多集群**：如果您运行的是多集群安装，则可能会受到 `GHSA-gf6w-6mxv-5fj4` 的影响。
- **拒绝服务**：所有安装都可能会受到 `GHSA-635j-qv98-9275` 的影响，
  Ambient 模式安装还可能会受到 `GHSA-77vw-rg85-wx5x` 的影响。

## 缓解措施 {#mitigation}

- 针对 Istio 1.31 用户：升级至 **1.31.4** 或更高版本。
- 针对 Istio 1.30 用户：升级至 **1.30.8** 或更高版本。
- 有关这些漏洞及其缓解措施的更多详细信息，请查阅上面列出的每个 GHSA 的公告信息。
