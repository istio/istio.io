---
title: ISTIO-SECURITY-2020-011
subtitle: 安全公告
description: Envoy 错误地为非 HTTP 连接恢复代理协议下游地址。
cves: [N/A]
cvss: "N/A"
vector: ""
releases: ["1.8.0"]
publishdate: 2020-11-21
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy 和 Istio 1.8.0 版本均容易受到新发现隐患的攻击：

- [非 HTTP 连接的代理协议下游地址不正确](https://groups.google.com/g/envoy-security-announce/c/aqtBt5VUor0): Envoy 错误地为非 HTTP 连接恢复代理协议下游地址。Envoy恢复直连对等体的地址，并将其传递给后续的过滤器，而不是恢复代理协议筛选器提供的地址。这将影响非 HTTP 网络连接的日志记录(`%DOWNSTREAM_REMOTE_ADDRESS%`)和授权策略(`remoteIpBlocks`和`remote_ip`)，因为它们将使用不正确的代理协议下游地址。

但这个问题不会影响 HTTP 连接。另外来自 `X-Forwarded-For` 的地址也不受影响。

Istio 不支持代理协议，唯一的方法是使用自定义的 `EnvoyFilter` 资源。然而它没有在 Istio 中测试过，需要您自己承担相应的风险。

## 防范{#mitigation}

- 对于 Istio 1.8.0 部署： 非 HTTP 连接请不使用代理协议。

{{< boilerplate "security-vulnerability" >}}
