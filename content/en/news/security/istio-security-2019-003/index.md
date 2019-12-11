---
title: ISTIO-SECURITY-2019-003
subtitle: Security Bulletin
description: Denial of service in regular expression parsing.
cves: [CVE-2019-14993]
cvss: "7.5"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.1 to 1.1.12", "1.2 to 1.2.3"]
publishdate: 2019-08-13
keywords: [CVE]
skip_seealso: true
aliases:
    - /blog/2019/istio-security-003-004
    - /news/2019/istio-security-003-004
---

{{< security_bulletin >}}

An Envoy user reported publicly an issue (c.f. [Envoy Issue 7728](https://github.com/envoyproxy/envoy/issues/7728)) about regular expressions (or regex) matching
that crashes Envoy with very large URIs. After investigation, the Istio team has found that this issue could be leveraged for a DoS attack in Istio, if users are employing regular expressions in some of the Istio APIs: `JWT`, `VirtualService`, `HTTPAPISpecBinding`, `QuotaSpecBinding`.

## Impact and detection

To detect if there is any regular expressions used in Istio APIs in your cluster, run the following command which prints either of the following output:

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

## Mitigation

* For Istio 1.1.x deployments: update to [Istio 1.1.13](/news/releases/1.1.x/announcing-1.1.13) or later
* For Istio 1.2.x deployments: update to [Istio 1.2.4](/news/releases/1.2.x/announcing-1.2.4) or later.

{{< boilerplate "security-vulnerability" >}}
