---
title: ISTIO-SECURITY-2020-004
subtitle: Security Bulletin
description: Default Kiali security configuration allows full control of mesh.
cves: [CVE-2020-1764]
cvss: "8.7"
vector: "AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N"
releases: ["1.4 to 1.4.6", "1.5"]
publishdate: 2020-03-25
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 1.4 到 1.4.6 和 Istio 1.5 包含以下漏洞:

* __[`CVE-2020-1764`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-1764)__:
  Istio 对 Kiali 使用默认的 `signing_key`。这允许攻击者查看和修改 Istio 配置。
    * CVSS Score: 8.7 [AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N&version=3.1)

此外，此版本中还修复了另一个CVE，如下所述：
[Kiali 安全告](https://kiali.io/news/security-bulletins/kiali-security-001/).

## 检测{#detection}

您的安装在以下配置中容易受到攻击：

* Kiali 版本为1.15或更早版本。
* Kiali 登录令牌和签名密钥未设置。

请运行以下命令，检查您的 Kiali 版本：

{{< text bash >}}
$ kubectl get pods -n istio-system -l app=kiali -o yaml | grep image:
{{< /text >}}

请运行以下命令确定您的登录令牌是否未设置，并检查输出是否为空：

{{< text bash >}}
$ kubectl get deploy kiali -n istio-system -o yaml | grep LOGIN_TOKEN_SIGNING_KEY
{{< /text >}}

请运行以下命令确定您的签名密钥是否未设置，并检查输出是否为空：

{{< text bash >}}
$ kubectl get cm kiali -n istio-system -o yaml | grep signing_key
{{< /text >}}

## 防范{#mitigation}

* 对于 1.4.x 部署： 请升级至 [Istio 1.4.7](/zh/news/releases/1.4.x/announcing-1.4.7) 或更高的版本。
* 对于 1.5.x 部署： 请升级至 [Istio 1.5.1](/zh/news/releases/1.5.x/announcing-1.5.1) 或更高的版本。
* 解决方法：您可以使用以下命令将签名密钥手动更新为随机令牌：

    {{< text bash >}}
    $ kubectl get cm kiali -n istio-system -o yaml | sed "s/server:/login_token:\\\n \
    signing_key: $(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 20 | head -n 1)\\\nserver:/" \
    | kubectl apply -f - ; kubectl delete pod -l app=kiali -n istio-system
    {{< /text >}}
