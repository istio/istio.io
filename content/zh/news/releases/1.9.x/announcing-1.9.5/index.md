---
title: Istio 1.9.5 发布公告
linktitle: 1.9.5
subtitle: 补丁发布
description: Istio 1.9.5 补丁发布。
publishdate: 2021-05-11
release: 1.9.5
aliases:
    - /zh/news/announcing-1.9.5
---

此版本修复了我们在 5 月 11 日的文章中描述的 [ISTIO-SECURITY-2021-005](/zh/news/security/istio-security-2021-005) 和 [ISTIO-SECURITY-2021-006](/zh/news/security/istio-security-2021-006) 两个安全漏洞。

{{< relnote >}}

## 安全更新{#security-update}

{{< tip >}}
这与前两个 CVE 高度相关。
{{< /tip >}}

- __[CVE-2021-31920](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-31920)__:
Istio 包含一个可远程利用的漏洞，当使用基于路径的授权规则时，带有多个斜杠或转义斜杠字符 (`%2F` 或 `%5C`) 的 HTTP 请求路径可能会绕过 Istio 的授权策略。有关更多详细信息，请参阅 [ISTIO-SECURITY-2021-005 bulletin](/zh/news/security/istio-security-2021-005) 公告。
    - __CVSS Score__: 8.1 [AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N)
- __[CVE-2021-29492](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-29492)__:
  Envoy 包含一个可远程利用的漏洞，其中带有转义斜杠字符的 HTTP 请求可以绕过 Envoy 的授权机制。
    - __CVSS Score__: 8.3 [AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:L/I:L/A:L)
- __[CVE-2021-31921](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-31921)__:
  Istio 包含一个可远程利用的漏洞，当网关配置了 `AUTO_PASSTHROUGH` 路由配置时，外部客户端可以访问集群中的意外服务，从而绕过授权检查。有关更多详细信息，请参阅 [ISTIO-SECURITY-2021-006 bulletin](/zh/news/security/istio-security-2021-006) 公告。
    - __CVSS Score__: 10.0 [AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H)

## 改变{#changes}

- **新增** 新增了[授权策略的安全最佳实践](/zh/docs/ops/best-practices/security/#authorization-policies)。

## 重大变化{#breaking-Changes}

作为 [ISTIO-SECURITY-2021-006](/zh/news/security/istio-security-2021-006/) 修复的一部分，[之前弃用](/zh/news/releases/1.8.x/announcing-1.8/upgrade-notes/#multicluster-global-stub-domain-deprecation) `.global` 的多集群存根域将不再起作用。

如果需要，可以通过 `PILOT_ENABLE_LEGACY_AUTO_PASSTHROUGH=true` 在 Istiod 中设置环境变量来暂时禁用此更改。但是强烈建议不要这样做，因为它会否定对 [ISTIO-SECURITY-2021-006](/zh/news/security/istio-security-2021-006/) 的修复。

请参照[多集群安装文档](/zh/docs/setup/install/multicluster/)了解更多信息。
