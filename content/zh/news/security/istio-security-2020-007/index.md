---
title: ISTIO-SECURITY-2020-007
subtitle: 安全公告
description: Envoy 中的多个拒绝服务漏洞。
cves: [CVE-2020-12603, CVE-2020-12605, CVE-2020-8663, CVE-2020-12604]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.5 to 1.5.6", "1.6 to 1.6.3"]
publishdate: 2020-06-30
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy 和 Istio 容易受到4个新发现漏洞的攻击：

* __[CVE-2020-12603](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12603)__：
通过发送特制数据包，攻击者可能会导致 Envoy 在代理 HTTP/2 请求或响应时消耗过多的内存。
    * CVSS Score: 7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-12605](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12605)__：
在处理特制 HTTP/1.1 的数据包时，攻击者可能会导致 Envoy 消耗过多的内存。
    * CVSS Score: 7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-8663](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8663)__：
当接受太多连接时，攻击者可能导致 Envoy 耗尽文件描述符。
    * CVSS Score: 7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-12604](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12604)__：
在处理特制数据包时，攻击者可能会导致内存使用增加。
    * CVSS Score: 5.3 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

## 防范{#mitigation}

* 对于 1.5.x 部署： 请升级至  [Istio 1.5.7](/zh/news/releases/1.5.x/announcing-1.5.7) 或更高的版本。
* 对于 1.6.x 部署： 请升级至  [Istio 1.6.4](/zh/news/releases/1.6.x/announcing-1.6.4) 或更高的版本。

{{< warning >}}
您必须采取以下附加步骤来防范 CVE-2020-8663。
{{< /warning >}}

通过添加[下游连接](https://www.envoyproxy.io/docs/envoy/v1.14.3/configuration/operations/overload_manager/overload_manager#limiting-active-connections)的配置限制，在 Envoy 解决 CVE-2020-8663。 必须配置此限制以防范此漏洞。 在 Ingress 网关上执行如下步骤来配置限制。

1. 通过下载 [custom-bootstrap-runtime.yaml](/zh/news/security/istio-security-2020-007/custom-bootstrap-runtime.yaml)创建配置映射。 根据部署中各个网关实例所需的并发连接数，在配置映射中更新 `global_downstream_max_connections` 。 一旦达到限制，Envoy 将开始拒绝 TCP 连接。

    {{< text bash >}}
    $ kubectl -n istio-system apply -f custom-bootstrap-runtime.yaml
    {{< /text >}}

1. 使用以上配置来修补 Ingress 网关。 下载 [gateway-patch.yaml](/zh/news/security/istio-security-2020-007/gateway-patch.yaml) 文件并使用如下命令。

    {{< text bash >}}
    $ kubectl --namespace istio-system patch deployment istio-ingressgateway --patch "$(cat gateway-patch.yaml)"
    {{< /text >}}

1. 确认新限制已经配置。

    {{< text bash >}}
    $ ISTIO_INGRESS_PODNAME=$(kubectl get pods -l app=istio-ingressgateway -n istio-system  -o jsonpath="{.items[0].metadata.name}")
    $ kubectl --namespace istio-system exec -i -t  ${ISTIO_INGRESS_PODNAME} -c istio-proxy -- curl -sS http://localhost:15000/runtime

    {
    "entries": {
     "overload.global_downstream_max_connections": {
      "layer_values": [
       "",
       "250000",
       ""
      ],
      "final_value": "250000"
     }
    },
    "layers": [
     "static_layer_0",
     "admin"
    ]
    }
    {{< /text >}}

{{< boilerplate "security-vulnerability" >}}
