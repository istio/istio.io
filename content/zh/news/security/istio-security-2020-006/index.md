---
title: ISTIO-SECURITY-2020-006
subtitle: 安全公告
description: Envoy使用HTTP2库中的拒绝服务。
cves: [CVE-2020-11080]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.4 to 1.4.9", "1.5 to 1.5.4", "1.6 to 1.6.1"]
publishdate: 2020-06-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

已修复并公开披露影响 Envoy 使用的 HTTP2 库的漏洞 (c.f. [拒绝服务：SETTINGS 帧过大](https://github.com/nghttp2/nghttp2/security/advisories/GHSA-q5wr-xfw9-q7xr) ). 不幸的是，Istio 没有从可靠的披露评审中受益。

* __[CVE-2020-11080](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-11080)__：
通过发送特制数据包，攻击者可能会导致 CPU 峰值激增100％。 这可以发送到 Ingress 网关或 Sidecar。
    * CVSS Score: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N&version=3.1)

## 防范{#mitigation}

可以使用以下配置在 Ingress Gateway 上禁用 HTTP2 支持作为临时解决方法，例如（请注意，如果您不通过 Ingress 公开 gRPC 服务，则可以禁用 Ingress 的 HTTP2 支持）：

{{< text yaml >}}

apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: disable-ingress-h2
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: NETWORK_FILTER # http connection manager is a filter in Envoy
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
    patch:
      operation: MERGE
      value:
        typed_config:
          "@type": type.googleapis.com/envoy.config.filter.network.http_connection_manager.v2.HttpConnectionManager
          codec_type: HTTP1
{{< /text >}}

* 对于 Istio 1.4.x 部署：请升级至 [Istio 1.4.10](/zh/news/releases/1.4.x/announcing-1.4.10) 或更高的版本。
* 对于 Istio 1.5.x 部署：请升级至 [Istio 1.5.5](/zh/news/releases/1.5.x/announcing-1.5.5) 或更高的版本。
* 对于 Istio 1.6.x 部署：请升级至 [Istio 1.6.2](/zh/news/releases/1.6.x/announcing-1.6.2) 或更高的版本。

## 鸣谢{#credit}

我们要感谢 `Michael Barton` 引起了我们对这个公开披露漏洞的关注。

{{< boilerplate "security-vulnerability" >}}
