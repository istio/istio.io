---
title: ISTIO-SECURITY-2022-007
subtitle: Security Bulletin
description: Denial of service attack due to Go Regex Library.
cves: [CVE-2022-39278]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.13", "1.13.0 to 1.13.8", "1.14.0 to 1.14.4", "1.15.0 to 1.15.1"]
publishdate: 2022-10-12
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-39278

- __[CVE-2022-39278](https://github.com/istio/istio/security/advisories/GHSA-86vr-4wcv-mm9w)__:
  (CVSS Score 7.5, High): Denial of service attack due to Go Regex Library.

The Istio control plane, istiod, is vulnerable to a request processing error, allowing a malicious attacker that sends a
specially crafted or oversized message, to crash the control plane process. This can be exploited when the Kubernetes validating or
mutating webhook service is exposed publicly. This endpoint is served over TLS port 15017, but does not require any
authentication from an attacker.

For simple installations, Istiod is typically only reachable from within the cluster, limiting the blast radius. However,
for some deployments, especially those where the control plane runs in a different cluster, this port is exposed over the public internet.

### Go CVE

The following Go issue points to the security vulnerability caused by the Go regex library. It is publicly fixed in Go 1.18.7 and Go 1.19.2
- [CVE-2022-41715](https://github.com/golang/go/issues/55949)

## Am I Impacted?

You are at most risk if you are running Istio in an external istiod environment, or if you have exposed your istiod externally and you are using any of the affected Istio versions.
