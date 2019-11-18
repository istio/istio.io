---
title: ISTIO-SECURITY-2019-005
subtitle: Security Bulletin
description: Security vulnerability disclosure for CVE-2019-15226.
cve: [CVE-2019-15226]
publishdate: 2019-10-08
keywords: [CVE]
skip_seealso: true
aliases:
    - /news/2019/istio-security-2019-005
---

| Information       | &nbsp;
|-------------------|--------
| CVE               | [CVE-2019-15226](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15226)
| CVSS Impact Score | 7.5 [CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H)
| Affected Releases | 1.1 to 1.1.15<br>1.2 to 1.2.6<br>1.3 to 1.3.1

## Context

Envoy, and subsequently Istio, are vulnerable to the following DoS attack. Upon receiving each incoming request, Envoy will iterate over the request headers to verify that the total size of the headers stays below a maximum limit. A remote attacker may craft a request that stays below the maximum request header size but consists of many thousands of small headers to consume CPU and result in a denial-of-service attack.

## Impact and detection

Both Istio gateways and sidecars are vulnerable to this issue. If you are running one of the affected releases, your cluster is vulnerable.

## Mitigation

* For Istio 1.1.x deployments: update all control plane components (Pilot, Mixer, Citadel, and Galley) and then [upgrade the data plane](/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade) to [Istio 1.1.16](/news/releases/1.1.x/announcing-1.1.16) or later.
* For Istio 1.2.x deployments: update all control plane components (Pilot, Mixer, Citadel, and Galley) and then [upgrade the data plane](/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade) to [Istio 1.2.7](/news/releases/1.2.x/announcing-1.2.7) or later.
* For Istio 1.3.x deployments: update all control plane components (Pilot, Mixer, Citadel, and Galley) and then [upgrade the data plane](/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade) to [Istio 1.3.2](/news/releases/1.3.x/announcing-1.3.2) or later.

{{< boilerplate "security-vulnerability" >}}
