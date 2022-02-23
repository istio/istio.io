---
title: ISTIO-SECURITY-2022-003
subtitle: Security Bulletin
description: Multiple CVEs related to istiod Denial of Service and Envoy.
cves: [CVE-2022-21701, CVE-2021-43824, CVE-2021-43825, CVE-2021-43826, CVE-2022-21654, CVE-2022-21655, CVE-2022-23606]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.11.0", "1.11.0 to 1.11.6", "1.12.0 to 1.12.3", "1.13.0"]
publishdate: 2022-02-22
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-23635

- __[CVE-2022-23635](https://github.com/istio/istio/security/advisories/GHSA-856q-xv3c-7f2f)__:
  (CVSS Score 7.5, High):  Unauthenticated control plane denial of service attack.

The Istio control plane, istiod, is vulnerable to a request processing error, allowing a malicious attacker that
sends a specially crafted message which results in the control plane crashing. This endpoint is served over TLS port 15012,
but does not require any authentication from the attacker.

For simple installations, istiod is typically only reachable from within the cluster, limiting the blast radius. However, for some deployments, especially [multicluster topologies](/docs/setup/install/multicluster/primary-remote/), this port is exposed over the public internet.

### Envoy CVEs

At this time it is not believed that Istio is vulnerable to these CVEs in Envoy. They are listed, however,
to be transparent.


CVE-2021-43824
CVE-2021-43825
CVE-2021-43826
CVE-2022-21654
CVE-2022-21655

CVE-2022-21656
CVE-2022-21657

CVE-2022-23606


- __[CVE-2021-43824](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2021-43824])__:
  (CVSS Score 6.5, Medium): Potential null pointer dereference when using JWT filter `safe_regex` match.

- __[CVE-2021-43825](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2021-43825])__:
  (CVSS Score 6.1, Medium):  Use-after-free when response filters increase response data, and increased data exceeds downstream buffer limits.

- __[CVE-2021-43826](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2021-43826])__:
  (CVSS Score 6.1, Medium): Use-after-free when tunneling TCP over HTTP, if downstream disconnects during upstream connection establishment.

- __[CVE-2022-21654](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-21654])__:
  (CVSS Score 7.3, High): Incorrect configuration handling allows mTLS session re-use without re-validation after validation settings have changed.

- __[CVE-2022-21655](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-21655])__:
  (CVSS Score 7.5, High): Incorrect handling of internal redirects to routes with a direct response entry.

The following CVEs only affected Istio 1.12.0-1.12.3 and 1.13.0. It did not affect Istio 1.11.

- __[CVE-2022-23606](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9vp2-4cp7-vvxf])__:
  (CVSS Score 4.4, Moderate): Stack exhaustion when a cluster is deleted via Cluster Discovery Service.

The following CVEs did not have patches for the version of Envoy used in Istio 1.11. While the CVE exists, Istio
does not believe that it is affected by this issue.

- __[CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2])__:
  (CVSS Score 3.1, Low): X.509 `subjectAltName` matching (and nameConstraints) bypass

The following CVEs were not patched as they were not provided to Istio prior to Envoy's release. It will be patched in a
future version of Istio. Istio is not affected by this vulnerability, however, Istio 1.11.7, 1.12.4 and 1.13.1 did not patch this.

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g])__:
  (CVSS Score 3.1, Low): X.509 Extended Key Usage and Trust Purposes bypass

## Am I Impacted?

You are at most risk if you are running Istio in a multi-cluster environment, or if you have exposed your istiod externally.

## Credit

We would like to thank `Adam Koratz` ([`ADA Logics`](https://adalogics.com)) and `John Howard` (Google) for the report and the fix.
