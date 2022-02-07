---
title: ISTIO-SECURITY-2022-001
subtitle: Security Bulletin
description: Authorization Policy For Host Rules During Upgrades.
cves: [CVE-2022-21679]
cvss: "6.8"
vector: "AV:N/AC:H/PR:N/UI:R/S:U/C:H/I:H/A:N"
releases: ["1.12.0 to 1.12.1"]
publishdate: 2022-01-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-21679

Istio 1.12.0/1.12.1 will generate incorrect configuration for proxies of version 1.11 affecting the `hosts` and `notHosts` field in the authorization policy. The incorrect configuration could cause requests to accidentally bypass or get rejected by the authorization policy when using the `hosts` and `notHosts` fields.

The issue happens when mixing the 1.12.0/1.12.1 control plane with the 1.11 data plane and using the `hosts` or `notHosts` field in the authorization policy.

### Mitigation

* Upgrade to latest 1.12.2 or;
* Do not mix the 1.12.0/1.12.1 control plane with 1.11 data plane if using `hosts` or `notHosts` field in authorization policy

## Credit

We would like to thank Yangmin Zhu and @Aakash2017.
