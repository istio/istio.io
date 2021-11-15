---
title: ISTIO-SECURITY-2021-008
subtitle: 安全公告
description: 多个与 AuthorizationPolicy、EnvoyFilter 和 Envoy 相关的 CVEs。
cves: [CVE-2021-32777, CVE-2021-32781, CVE-2021-32778, CVE-2021-32780, CVE-2021-39155, CVE-2021-39156]
cvss: "8.6"
vector: "AV:L/AC:L/PR:N/UI:R/S:C/C:H/I:H/A:H"
releases: ["All releases prior to 1.9.8", "1.10.0 to 1.10.3", "1.11.0"]
publishdate: 2021-08-24
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE{#cves}

Envoy 以及下面的 Istio 容易受到六个新发现的漏洞的攻击（注意 Envoy 的 CVE-2021-32779 与 Istio 的 CVE-2021-39156 合并）：

### CVE-2021-39156 (CVE-2021-32779)

Istio 包含一个可远程利用的漏洞，[CVE-2021-39156](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-39156)，
其中 HTTP 请求中 `#` 在 URL 路径中的片段（URI 末尾以字符 `#` 开头的部分）可以绕过 Istio 的基于 URI 路径的授权策略。例如，Istio 授权策略[拒绝](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) 发送到 URI 路径 `/user/profile` 的请求。在易受攻击的版本中，带有 URI 路径的请求 `/user/profile#section1` 会绕过拒绝策略并路由到后端 （使用规范化的 URI 路径 `/user/profile%23section1`），这可能会导致安全事件。

该修复取决于 Envoy 的修复，该修复与 [CVE-2021-32779](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32779) 相关联。

* CVSS 得分： 8.1 [AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:N&version=3.1)

如果出现以下情况，你会受到此漏洞的影响：

* 您使用早于 1.9.8, 1.10.4 或 1.11.1 的 Istio 补丁版本。
* 您将授权策略与
  [DENY 操作](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) 和
  [`operation.paths`](/zh/docs/reference/config/security/authorization-policy/#Operation), 或
  [ALLOW 操作](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) 和
  [`operation.notPaths`](/zh/docs/reference/config/security/authorization-policy/#Operation) 一起使用。

如果采用 [防范措施](#mitigation)，在授权和路由之前删除请求 URI 的片段部分。这可以防止在其 URI 中包含片段的请求绕过基于没有片段部分的 URI 的授权策略。

如果不采用 [防范措施](#mitigation) 的新策略，将保留 URI 中的片段部分。您可以按照如下方式配置您的安装：

{{< warning >}}
禁止新策略将使您的路径正常化，如上所述，并且被认为是不安全的。在使用此选项之前，请确保您已在任何安全策略中对此进行了调整。
{{< /warning >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: opt-out-fragment-cve-fix
  namespace: istio-system
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        HTTP_STRIP_FRAGMENT_FROM_PATH_UNSAFE_IF_DISABLED: "false"
{{< /text >}}

### CVE-2021-39155

Istio 包含一个可远程利用的漏洞，当使用基于 `hosts` 或 `notHosts` 的规则时， HTTP 请求可能会绕过 Istio 授权策略。在易受攻击的版本中， Istio 授权策略以区分大小写的方式比较 HTTP 的 `Host` 或 `:authority` 头，这与 [RFC 4343](https://datatracker.ietf.org/doc/html/rfc4343) 不一致。例如，用户可能有一个拒绝带有 host `secret.com` 的请求的授权策略，但攻击者可以通过发送带有主机名 `Secret.com` 的请求来绕过这一点，流量将被路由到 `secret.com` ，这一行为违反了授权策略。

有关更多信息，请参阅 [CVE-2021-39155](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-39155)。

* CVSS 得分: 8.3 [AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:R/S:U/C:H/I:H/A:L&version=3.1)

如果出现以下情况，您会受到此漏洞的影响：

* 您使用早于 1.9.8, 1.10.4 或 1.11.1 的 Istio 补丁版本。
* 您将 Istio 授权策略与
  [DENY actions](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) 和
  [`operation.hosts`](/zh/docs/reference/config/security/authorization-policy/#Operation), 或
  [ALLOW actions](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) 和
  [`operation.notHosts`](/zh/docs/reference/config/security/authorization-policy/#Operation) 一起使用。

通过 [防范措施](#mitigation)，当使用基于 `hosts` 或 `notHosts` 的授权策略时， Istio 授权策略比较 HTTP 的 `Host` 或 `:authority` 报头，对 `hosts` 或 `notHosts` 规格不区分大小写。

### CVE-2021-32777

Envoy 包含一个可远程利用的漏洞，当使用 `ext_authz` 扩展时，带有多个值标头的 HTTP 请求可能会执行不完整的授权策略检查。当请求头包含多个值时，外部授权服务器只会看到给定头的最后一个值。有关更多信息，请参阅 [CVE-2021-32777](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32777) 。

* CVSS 得分: 8.6

如果出现一下情况，您会受此漏洞的影响：

* 您使用早于 1.9.8，1.10.4 或 1.11.1 的 Istio 补丁版本。
* 您用 [`EnvoyFilters`](/zh/docs/reference/config/networking/envoy-filter/)。

### CVE-2021-32778

Envoy 包含一个可远程利用的漏洞，其中 Envoy 客户端打开后重置大量的 HTTP/2 请求，可能会导致 CPU 消耗过多。有关信息，请参阅 [CVE-2021-32778](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32778)。

* CVSS 得分: 8.6

如果您使用早于 1.9.8，1.10.4 或 1.11.1 的 Istio 补丁版本，则会受到此漏洞的影响。

### CVE-2021-32780

Envoy 包含一个可远程利用的漏洞，其中不受信任的上游服务可能会导致 Envoy 通过发送 GOAWAY 祯和设置 `SETTINGS_MAX_CONCURRENT_STREAMS` 参数为 0 的 SETTINGS 帧异常终止。有关更多信息，请参阅 [CVE-2021-32780](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32780)。

* CVSS 得分：8.6

如果您使用 Istio 1.10.0 至 1.10.3 或 1.11.0 的补丁版本，则会受到此漏洞的影响，

### CVE-2021-32781

Envoy 包含一个可远程利用的漏洞，它会影响 Envoy 的 `decompressor`, `json-transcoder` 或者 `grpc-web` 插件，同时会影响能够修改或增加请求或响应主体的大小的专有插件。在 Envoy 插件中修改和增加主体的大小超出内部缓冲区大小可能会导致 Envoy 访问已释放的内存并异常终止。有关更多信息，请参阅 [CVE-2021-32781](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-32781)。

* CVSS 得分: 8.6

如果出现以下情况，您会受到此漏洞的影响：

* 您使用早于 1.9.8， 1.10.4 或 1.11.1 的 Istio 补丁版本。
* 您使用 [`EnvoyFilters`](/zh/docs/reference/config/networking/envoy-filter/).

### 防范措施{#mitigation}

要防范上述 CVE，请将您的集群更新到最新的受支持的版本：

* Istio 1.9.8 或更高版本，如果使用 1.9.x
* Istio 1.10.4 或更高版本，如果使用 1.10.x
* Istio 1.11.1 或更高版本， 如果使用 1.11.x
* 您的云提供商指定的补丁版本

## 非 CVE 漏洞{#Non-CVE-vulnerabilities}

### Istio 不会忽略 `AuthorizationPolicy` 中 `host` 和 `notHosts` 的端口比较

创建 `VirtualService` 或 `Gateway` 时，Istio 生成匹配主机名本身和具有所有匹配端口的主机名的配置。例如，主机 `httpbin.foo` 生成的 `VirtualService` 或 `Gateway` 配置匹配 `httpbin.foo` 和 `httpbin.foo:*` 。但是，`AuthorizationPolicy` 使用精确匹配时，仅匹配 `hosts` 或 `notHosts` 字段给出的精确字符串。

如果您使用 `AuthorizationPolicy` 对 [`hosts` 或 `notHosts`](/zh/docs/reference/config/security/authorization-policy/#Operation) 进行精确的字符串比较，您的集群会受到影响。

#### `AuthorizationPolicy` 防范{#AuthorizationPolicy-mitigation}

更新您的授权策略[规则](/zh/docs/reference/config/security/authorization-policy/#Rule) 以使用前缀匹配而不是精确匹配。例如，要匹配主机 `httpbin.com` 的 `VirtualService` 或 `Gateway` ，请使用 `hosts: ["httpbin.com", "httpbin.com:*"]` 创建一个 `AuthorizationPolicy` ，如下所示。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        namespaces: ["dev"]
    to:
    - operation:
        hosts: ["httpbin.com", "httpbin.com:*"]
{{< /text >}}

## 致谢 {#credit}

我们要感谢 Yangmin Zhu (Google) 报告了上述一些问题。
