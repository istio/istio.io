---
title: ISTIO-SECURITY-2022-004
subtitle: Security Bulletin
description: Unauthenticated control plane denial of service attack due to stack exhaustion.
cves: [CVE-2022-24726, CVE-2022-24921]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.11.0", "1.11.0 to 1.11.7", "1.12.0 to 1.12.4", "1.13.0 to 1.13.1"]
publishdate: 2022-03-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-24726

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (CVSS Score 7.5, High): Unauthenticated control plane denial of service attack due to stack exhaustion.

The Istio control plane, istiod, is vulnerable to a request processing error, allowing a malicious attacker that sends a
specially crafted or oversized message, to crash the control plane process. This can be exploited when the Kubernetes validating or
mutating webhook service is exposed publicly. This endpoint is served over TLS port 15017, but does not require any
authentication from an attacker.

For simple installations, Istiod is typically only reachable from within the cluster, limiting the blast radius. However,
for some deployments, especially those where the control plane runs in a different cluster, this port is exposed over the public internet.

Istio considers this a 0-day vulnerability due to the publication of
[CVE-2022-24921](https://github.com/advisories/GHSA-6685-ffxp-xm6f) by the Go team.

### Envoy CVEs

The following Envoy CVEs for Envoy were also patched for Istio 1.11.8, 1.12.5 and Istio 1.13.2. They were publicly fixed in
[https://github.com/envoyproxy/envoy](https://github.com/envoyproxy/envoy) for versions of Envoy used in prior Istio versions. As detailed in
[ISTIO-SECURITY-2022-003](/news/security/istio-security-2022-003), Istio was not vulnerable to attack.

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
  (CVSS Score 3.1, Low): X.509 Extended Key Usage and Trust Purposes bypass.

The following was also fixed in Istio 1.12.5 and Istio 1.13.2.

- __[CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2)__
  (CVSS Score 3.1, Low):X.509 `subjectAltName` matching (and `nameConstraints`) bypass.

## Am I Impacted?

You are at most risk if you are running Istio in an external istiod environment, or if you have exposed your istiod externally.

## Credit

We would like to thank John Howard (Google) for the report and the fix.
