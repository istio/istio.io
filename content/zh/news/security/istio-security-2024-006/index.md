---
title: ISTIO-SECURITY-2024-006
subtitle: 安全公告
description: Envoy 上报的 CVE 漏洞。
cves: [CVE-2024-45807, CVE-2024-45808, CVE-2024-45806, CVE-2024-45809, CVE-2024-45810]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 to 1.22.4", "1.23.0 to 1.23.1"]
publishdate: 2024-09-19
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVE {#envoy-cves}

- __[CVE-2024-45807](https://github.com/envoyproxy/envoy/security/advisories/GHSA-qc52-r4x5-9w37)__:
  (CVSS Score 7.5, High)：oghttp2 可能在 `OnBeginHeadersForStream` 上崩溃。

- __[CVE-2024-45808](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p222-xhp9-39rc)__:
  (CVSS Score 6.5, Moderate)：访问记录器的 `REQUESTED_SERVER_NAME` 字段缺乏验证，导致访问日志中注入意外内容。

- __[CVE-2024-45806](https://github.com/envoyproxy/envoy/security/advisories/GHSA-ffhv-fvxq-r6mf)__:
  (CVSS Score 6.5, Moderate)：`x-envoy` 标头可能被外部来源操纵。

- __[CVE-2024-45809](https://github.com/envoyproxy/envoy/security/advisories/GHSA-wqr5-qmq7-3qw3)__:
  (CVSS Score 5.3, Moderate)：JWT 过滤器在使用远程 JWK 的清除路由缓存中崩溃。

- __[CVE-2024-45810](https://github.com/envoyproxy/envoy/security/advisories/GHSA-qm74-x36m-555q)__:
  (CVSS Score 6.5, Moderate)：Envoy 因 HTTP 异步客户端中的 `LocalReply` 崩溃。

## 我受到影响了吗？{#am-i-impacted}

如果您使用 Istio 1.22.0 到 1.22.4 或 1.23.0 到 1.23.1，则会受到影响。

如果您部署了 Istio Ingress Gateway，则可能会受到外部来源的 `x-envoy` 标头操纵。
Envoy 以前默认将所有私有 IP 视为内部 IP，因此不会清理来自具有私有 IP 的外部来源的标头。
Envoy 增加了对标志 `envoy.reloadable_features.explicit_internal_address_config` 的支持，
以明确取消信任所有 IP。Envoy 和 Istio 目前默认禁用该标志以实现向后兼容。
在未来的 Envoy 和 Istio 版本中，将默认启用标志 `envoy.reloadable_features.explicit_internal_address_config`。
可以通过 `runtimeValues` 中的
[ProxyConfig](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig)
在网格范围内或每个代理中设置 Envoy 标志。

网格范围的示例配置：

{{< text yaml >}}
meshConfig:
  defaultConfig:
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
{{< /text >}}

每个代理的示例配置：

{{< text yaml >}}
annotations:
  proxy.istio.io/config: |
    runtimeValues:
      "envoy.reloadable_features.explicit_internal_address_config": "true"
{{< /text >}}

注意，ProxyConfig 中的字段不是动态配置的；更改需要重新启动工作负载才能生效。
