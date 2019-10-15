---
title: Security Update - ISTIO-SECURITY-2019-005
description: Security vulnerability disclosure for CVE-2019-15226.
publishdate: 2019-10-08
attribution: The Istio Team
---

Today we are releasing three new Istio versions: 1.1.16, 1.2.7, and 1.3.2. These new Istio versions address vulnerabilities that can be used to mount Denial of Service (DoS) attacks against services using Istio.

__ISTIO-SECURITY-2019-005__: Envoy, and subsequently Istio, are vulnerable to the following DoS attack:
* __[CVE-2019-15226](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15226)__: Upon receiving each incoming request, Envoy will iterate over the request headers to verify that the total size of the headers stays below a maximum limit. A remote attacker may craft a request that stays below the maximum request header size but consists of many thousands of small headers to consume CPU and result in a denial-of-service attack.

## Affected Istio Releases

The following Istio releases are vulnerable:

* 1.1, 1.1.1, 1.1.2, 1.1.3, 1.1.4, 1.1.5, 1.1.6, 1.1.7, 1.1.8, 1.1.9, 1.1.10, 1.1.11, 1.1.12, 1.1.13, 1.1.14, 1.1.15
* 1.2, 1.2.1, 1.2.2, 1.2.3, 1.2.4, 1.2.5, 1.2.6
* 1.3, 1.3.1

## Impact Score

Overall CVSS score: 7.5 [CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H)

## Vulnerability impact and Detection

Both Istio gateways and sidecars are vulnerable to this issue. If you are running one of the versions listed above, your cluster is vulnerable.

## Mitigation

* For Istio 1.1.x deployments: update all control plane components (Pilot, Mixer, Citadel, and Galley) and then [upgrade the data plane](/docs/setup/upgrade/#sidecar-upgrade) to a minimum version of [Istio 1.1.16](/news/2019/announcing-1.1.16).
* For Istio 1.2.x deployments: update all control plane components (Pilot, Mixer, Citadel, and Galley) and then [upgrade the data plane](/docs/setup/upgrade/#sidecar-upgrade) to a minimum version of [Istio 1.2.7](/news/2019/announcing-1.2.7).
* For Istio 1.3.x deployments: update all control plane components (Pilot, Mixer, Citadel, and Galley) and then [upgrade the data plane](/docs/setup/upgrade/#sidecar-upgrade) to a minimum version of [Istio 1.3.2](/news/2019/announcing-1.3.2).

We'd like to remind our community to follow the [vulnerability reporting process](/about/security-vulnerabilities/) to report any bug that can result in a security vulnerability.


