---
title: Security Update - ISTIO-SECURITY-003 and ISTIO-SECURITY-004
description: Security vulnerability disclosure for multiple CVEs.
publishdate: 2019-08-13
attribution: The Istio Team
keywords: [CVE]
---

Today we are releasing two new versions of Istio. Istio [1.1.13](/about/notes/1.1.13/) and [1.2.4](/about/notes/1.2.4/) address vulnerabilities that can be used to mount a Denial of Service (DoS) attack against services using Istio.

__ISTIO-SECURITY-2019-003__: An Envoy user reported publicly an issue (c.f. [Envoy Issue 7728](https://github.com/envoyproxy/envoy/issues/7728)) about regular expressions (or regex) matching that crashes Envoy with very large URIs.
   After investigation, the Istio team has found that this issue could be leveraged for a DoS attack in Istio, if users are employing regular expressions in some of the Istio APIs: `JWT`, `VirtualService`, `HTTPAPISpecBinding`, `QuotaSpecBinding`.

__ISTIO-SECURITY-2019-004__: Envoy, and subsequently Istio are vulnerable to a series of trivial HTTP/2-based DoS attacks:
  * __[CVE-2019-9512](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9512)__: HTTP/2 flood using `PING` frames and queuing of response `PING` ACK frames that results in unbounded memory growth (which can lead to out of memory conditions).
  * __[CVE-2019-9513](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9513)__: HTTP/2 flood using PRIORITY frames that results in excessive CPU usage and starvation of other clients.
  * __[CVE-2019-9514](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9514)__: HTTP/2 flood using `HEADERS` frames with invalid HTTP headers and queuing of response `RST_STREAM` frames that results in unbounded memory growth (which can lead to out of memory conditions).
  * __[CVE-2019-9515](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9515)__: HTTP/2 flood using SETTINGS frames and queuing of `SETTINGS` ACK frames that results in unbounded memory growth (which can lead to out of memory conditions).
  * __[CVE-2019-9518](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9518)__: HTTP/2 flood using frames with an empty payload that results in excessive CPU usage and starvation of other clients.
  * See [this security bulletin](https://github.com/Netflix/security-bulletins/blob/master/advisories/third-party/2019-002.md) for more information

Those HTTP/2-based vulnerabilities were reported externally and affect multiple proxy implementations.

## Affected Istio releases

The following Istio releases are vulnerable:

* 1.1, 1.1.1, 1.1.2, 1.1.3, 1.1.4, 1.1.5, 1.1.6, 1.1.7, 1.1.8, 1.1.9, 1.1.10, 1.1.11, 1.1.12
* 1.2, 1.2.1, 1.2.2, 1.2.3

All versions prior to 1.1 are no longer supported and are considered vulnerable.

## Impact score

* Overall CVSS score for __ISTIO-SECURITY-2019-003__: 7.5 [CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H)
* Overall CVSS score for __ISTIO-SECURITY-2019-004__: 7.5 [CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H)

## Vulnerability impact and detection

__ISTIO-SECURITY-2019-003__: To detect if there is any regular expressions used in Istio APIs in your cluster, run the following command which prints either of the following output:
  * YOU ARE AFFECTED: found regex used in `AuthenticationPolicy` or `VirtualService`
  * YOU ARE NOT AFFECTED: did not find regex usage

```bash
cat <<'EOF' | bash -
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
```

__ISTIO-SECURITY-2019-004__: If Istio terminates externally originated HTTP then it is vulnerable.   If Istio is instead fronted by an intermediary that terminates HTTP (e.g., a HTTP load balancer), then that intermediary would protect Istio, assuming the intermediary is not itself vulnerable to the same HTTP/2 exploits.

## Mitigations

For both vulnerabilities:
  * For Istio 1.1.x deployments: update to a minimum version of Istio 1.1.13
  * For Istio 1.2.x deployments: update to a minimum version of Istio 1.2.4

We’d like to remind our community to follow the [vulnerability reporting process](/about/security-vulnerabilities/) to report any bug that can result in a security vulnerability.
