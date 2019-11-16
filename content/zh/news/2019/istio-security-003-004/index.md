---
title: 安全更新 - ISTIO-SECURITY-2019-003 and ISTIO-SECURITY-2019-004
description: 多个 CVE 相关的安全漏洞披露。
publishdate: 2019-08-13
attribution: The Istio Team
keywords: [CVE]
aliases:
    - /zh/blog/2019/istio-security-003-004
---

今天，我们发布了两个版本的 Istio。Istio [1.1.13](/news/2019/announcing-1.1.13/) 和 [1.2.4](/news/2019/announcing-1.2.4/) 来解决会被利用于针对使用 Istio 的服务发起拒绝服务攻击（DoS）的多个漏洞。

__ISTIO-SECURITY-2019-003__: Envoy 报告了一个正则表达式匹配匹配过程中超大的 URI 会导致 Envoy 崩溃的公开问题（c.f. [Envoy Issue 7728](https://github.com/envoyproxy/envoy/issues/7728)）。
  * __[CVE-2019-14993](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-14993)__: 在经过调研之后，Istio 团队发现如果用户在一些 Istio 的 API （如：`JWT`、`VirtualService`、`HTTPAPISpecBinding`、`QuotaSpecBinding`）中使用正则表达，就可能被用于针对 Istio 发起 DoS 攻击。

__ISTIO-SECURITY-2019-004__: Envoy，以及随后在 Istio 发现了一系列基于 HTTP/2 的简单被利用于 DoS 攻击的漏洞：
  * __[CVE-2019-9512](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9512)__: 使用 HTTP/2 的 `PING` 报文泛洪并使得 `PING` ACK 回应报文进入队列，这会导致内存无界增长（这可能导致内存耗尽）。
  * __[CVE-2019-9513](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9513)__: 使用 HTTP/2 的 PRIORITY 报文泛洪会导致 CPU 被过度占用和其他客户端的缺乏 CPU 资源。
  * __[CVE-2019-9514](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9514)__: 使用 HTTP/2 的含有无效 HTTP 头的 `HEADERS` 报文泛洪并使得响应的 `RST_STREAM` 报文进入队列，这会导致内存无界增长（这可能导致内存耗尽）。
  * __[CVE-2019-9515](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9515)__: 使用 HTTP/2 SETTINGS 报文泛洪并使得 `SETTINGS` ACK 回应报文进入队列，，这会导致内存无界增长（这可能导致内存耗尽）。
  * __[CVE-2019-9518](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9518)__: 使用 HTTP/2 包含空荷载的报文泛洪会导致 CPU 被过度占用和其他客户端的缺乏 CPU 资源。
  * 查阅 [安全公告牌](https://github.com/Netflix/security-bulletins/blob/master/advisories/third-party/2019-002.md) 获取更多的信息。

以上这些基于 HTTP/2 的漏洞是外部报告的，影响到多个代理实现。

## 受影响的 Istio 版本

下面是受漏洞影响的 Istio 发布版：

* 1.1, 1.1.1, 1.1.2, 1.1.3, 1.1.4, 1.1.5, 1.1.6, 1.1.7, 1.1.8, 1.1.9, 1.1.10, 1.1.11, 1.1.12
* 1.2, 1.2.1, 1.2.2, 1.2.3

1.1 之前的所有版本都不再支持，应被视为受漏洞影响的版本。

## 影响评分

* CVSS 总分 __ISTIO-SECURITY-2019-003__: 7.5 [CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H)
* CVSS 总分 __ISTIO-SECURITY-2019-004__: 7.5 [CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H)

## 漏洞的影响和检测

__ISTIO-SECURITY-2019-003__: 为了检测在你的集群中是否有 Istio API 使用了正则表达式，请运行以下命令，该命令输出以下任何一个输出：

* YOU ARE AFFECTED: found regex used in `AuthenticationPolicy` or `VirtualService`
* YOU ARE NOT AFFECTED: did not find regex usage

{{< text bash >}}
$ cat <<'EOF' | bash -
set -e
set -u
set -o pipefail

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "Checking regex usage in Istio API ..."

AFFECTED=()

JWT_REGEX=()
JWT_REGEX+=($(kubectl get Policy --all-namespaces -o jsonpath='{..regex}'))
JWT_REGEX+=($(kubectl get MeshPolicy --all-namespaces -o jsonpath='{..regex}'))
if [ "${#JWT_REGEX[@]}" != 0 ]; then
  AFFECTED+=("AuthenticationPolicy")
fi

VS_REGEX=()
VS_REGEX+=($(kubectl get VirtualService --all-namespaces -o jsonpath='{..regex}'))
if [ "${#VS_REGEX[@]}" != 0 ]; then
  AFFECTED+=("VirtualService")
fi

HTTPAPI_REGEX=()
HTTPAPI_REGEX+=($(kubectl get HTTPAPISpec --all-namespaces -o jsonpath='{..regex}'))
if [ "${#HTTPAPI_REGEX[@]}" != 0 ]; then
  AFFECTED+=("HTTPAPISpec")
fi

QUOTA_REGEX=()
QUOTA_REGEX+=($(kubectl get QuotaSpec --all-namespaces -o jsonpath='{..regex}'))
if [ "${#QUOTA_REGEX[@]}" != 0 ]; then
  AFFECTED+=("QuotaSpec")
fi

if [ "${#AFFECTED[@]}" != 0 ]; then
  echo "${red}YOU ARE AFFECTED: found regex used in ${AFFECTED[@]}${reset}"
  exit 1
fi

echo "${green}YOU ARE NOT AFFECTED: did not find regex usage${reset}"
EOF
{{< /text >}}

__ISTIO-SECURITY-2019-004__: 如果 Istio 终止了外部发起的 HTTP 请求，那么他就存在漏洞。如果 Istio 被前端代理替代，并且由这个前端代理终止 HTTP（e.g. HTTP 负载均衡），那么这个前端代理就会保护 Istio，前提是前端代理本身不受相同的利用代码影响。

## 缓解

对于这两个漏洞：

* 对于 Istio 1.1.x 部署：升级到最低 Istio 1.1.13 版本以上
* 对于 Istio 1.2.x 部署：升级到最低 Istio 1.2.4 版本以上

我们想提醒我们的社区遵循 [漏洞报告流程](/about/security-vulnerabilities/) 来报告任何会导致安全漏洞的问题。
