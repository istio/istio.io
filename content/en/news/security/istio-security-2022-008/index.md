---
title: ISTIO-SECURITY-2022-008
subtitle: Security Bulletin
description: Identity impersonation if user has localhost access.
cves: [CVE-2022-39388]
cvss: "7.6"
vector: "CVSS:3.1/AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.15.2"]
publishdate: 2022-11-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-39388

- __[CVE-2022-39388](https://github.com/istio/istio/security/advisories/GHSA-6c6p-h79f-g6p4)__:
  (CVSS Score 7.6, High): Identity impersonation if user has localhost access.

User can impersonate any workload identity within the service mesh if they have localhost access to the Istiod control plane.

## Am I Impacted?

You are at most risk if you are running Istio 1.15.2 and users have access to the machine where Istiod is running.
