---
title: ISTIO-SECURITY-2019-003
subtitle: Security Bulletin
description: 解析正则表达式导致的拒绝服务。
cves: [CVE-2019-14993]
cvss: "7.5"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.1 to 1.1.12", "1.2 to 1.2.3"]
publishdate: 2019-08-13
keywords: [CVE]
skip_seealso: true
aliases:
    - /zh/blog/2019/istio-security-003-004
    - /zh/news/2019/istio-security-003-004
---

{{< security_bulletin >}}

## 内容{#context}

一位 Envoy 用户报告了一个 (c.f. [Envoy Issue 7728](https://github.com/envoyproxy/envoy/issues/7728)) 关于非常大的URI的正则表达式会导致 Envoy 崩溃的问题。通过调查，Istio 团队发现如果用户正在这些 Istio API（`JWT`, `VirtualService`, `HTTPAPISpecBinding`, `QuotaSpecBinding`）中使用正则表达式，那么这个问题可能在 Istio 中引发 Dos 攻击。

## 影响范围{#impact-and-detection}

运行下面的命令可以打印下面的输出，检测在你的集群中是否使用了 Istio 正则表达式相关的 API。

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

## 防范{#mitigation}

* Istio 1.1.x: 升级到 [Istio 1.1.13](/zh/news/releases/1.1.x/announcing-1.1.13) 或者更高
* Istio 1.2.x: 升级到 [Istio 1.2.4](/zh/news/releases/1.2.x/announcing-1.2.4) 或者更高

{{< boilerplate "security-vulnerability" >}}
