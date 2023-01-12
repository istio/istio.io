---
title: ISTIO-SECURITY-2022-006
subtitle: Security Bulletin
description: Ill-formed headers sent to Envoy in certain configurations can lead to unexpected memory access resulting in undefined behavior or crashing.
cves: [CVE-2022-31045]
cvss: "5.9"
vector: "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.13.6", "1.14.2"]
publishdate: 2022-07-26
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## Do not use Istio 1.14.2 and Istio 1.13.6

Due to a process issue, [CVE-2022-31045](/news/security/istio-security-2022-005/#cve-2022-31045) was not included in our Istio 1.14.2 and Istio 1.13.6 builds.

At this time we suggest you do not install 1.14.2 or 1.13.6 in a production environment. If you have, you may downgrade to Istio 1.14.1 or Istio 1.13.5. Istio 1.14.3 and Istio 1.13.7 are expected to be released later this week.
