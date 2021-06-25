---
title: ISTIO-SECURITY-2021-007
subtitle: Security Bulletin
description: Istio contains a remotely exploitable vulnerability where credentials specified in the Gateway and DestinationRule credentialName field can be accessed from different namespaces.
cves: [CVE-2021-34824]
cvss: "9.1"
vector: "AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L"
releases: ["All 1.8 patch releases", "1.9.0 to 1.9.5", "1.10.0 to 1.10.1"]
publishdate: 2021-06-24
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## Issue

The Istio [`Gateway`](/docs/tasks/traffic-management/ingress/secure-ingress/) and
[`DestinationRule`](/docs/reference/config/networking/destination-rule/) can load private keys and certificates from Kubernetes
secrets via the `credentialName` configuration.
For Istio 1.8 and above, the secrets are conveyed from Istiod to gateways or workloads via the XDS API.

In the above approach, a gateway or workload deployment should only be able to access credentials (TLS certificates and private keys) stored in the
Kubernetes secrets within its namespace.
However, a bug in Istiod permits an authorized client the ability to access and retrieve any TLS certificate and private key cached in Istiod.

## Am I impacted?

Your cluster is impacted if ALL of following conditions are true:

* It is using Istio 1.10.0 to 1.10.1, Istio 1.9.0 to 1.9.5 or Istio 1.8.x.
* It has defined [`Gateways`](/docs/tasks/traffic-management/ingress/secure-ingress/) or
  [`DestinationRules`](/docs/reference/config/networking/destination-rule/) with the `credentialName` field specified.
* It does not specify the Istiod flag `PILOT_ENABLE_XDS_CACHE=false`.

{{< warning >}}
If you are using Istio 1.8, please contact your Istio provider to check for updates.
Otherwise, please upgrade to the newest patch version of Istio 1.9 or 1.10.
{{< /warning >}}

## Mitigation

Update your cluster to the latest supported version:

* Istio 1.9.6 or up, if using 1.9.x
* Istio 1.10.2 or up, if using 1.10.x
* The patch version specified by your cloud provider

If an upgrade isn't feasible, this vulnerability can be mitigated by disabling Istiod caching.
Caching is disabled by setting an Istiod environment variable `PILOT_ENABLE_XDS_CACHE=false`.
System and Istiod performance may be impacted as this disables XDS caching.

## Credit

We would like to thank the team at `Sopra Banking Software` (`Nishant Virmani`, `Stephane Mercier` and `Antonin Nycz`)
as well as John Howard (Google) for reporting this issue.
