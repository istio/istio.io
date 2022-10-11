---
title: ISTIO-SECURITY-2022-003
subtitle: Security Bulletin
description: Multiple CVEs related to istiod Denial of Service and Envoy.
cves: [CVE-2022-23635, CVE-2021-43824, CVE-2021-43825, CVE-2021-43826, CVE-2022-21654, CVE-2022-21655, CVE-2022-23606]
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

| CVE ID                                                                                        | Score, Rating | Description                                                                                                               | Fixed in 1.13.1   | Fixed in 1.12.4   | Fixed in 1.11.7                  |
|-----------------------------------------------------------------------------------------------|---------------|---------------------------------------------------------------------------------------------------------------------------|-------------------|-------------------|----------------------------------|
| [CVE-2021-43824](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vj5m-rch8-5r2p) | 6.5, Medium   | Potential null pointer dereference when using JWT filter `safe_regex` match.                                              | Yes               | Yes               | Yes                              |
| [CVE-2021-43825](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h69p-g6xg-mhhh) | 6.1, Medium   | Use-after-free when response filters increase response data, and increased data exceeds downstream buffer limits.         | Yes               | Yes               | Yes                              |
| [CVE-2021-43826](https://github.com/envoyproxy/envoy/security/advisories/GHSA-cmx3-fvgf-83mf) | 6.1, Medium   | Use-after-free when tunneling TCP over HTTP, if downstream disconnects during upstream connection establishment.          | Yes               | Yes               | Yes                              |
| [CVE-2022-21654](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5j4x-g36v-m283) | 7.3, High     | Incorrect configuration handling allows mTLS session re-use without re-validation after validation settings have changed. | Yes               | Yes               | Yes                              |
| [CVE-2022-21655](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7r5p-7fmh-jxpg) | 7.5, High     | Incorrect handling of internal redirects to routes with a direct response entry.                                          | Yes               | Yes               | Yes                              |
| [CVE-2022-23606](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9vp2-4cp7-vvxf) | 4.4, Moderate | Stack exhaustion when a cluster is deleted via Cluster Discovery Service.                                                 | Yes               | Yes               | N/A                              |
| [CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2) | 3.1, Low      | X.509 `subjectAltName` matching (and `nameConstraints`) bypass.                                                           | No, next release. | No, next release. | Envoy did not backport this fix. |
| [CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g) | 3.1, Low      | X.509 Extended Key Usage and Trust Purposes bypass                                                                        | No, next release. | No, next release. | No, next release.                |

## Am I Impacted?

You are at most risk if you are running Istio in a multi-cluster environment, or if you have exposed your istiod externally.

## Credit

We would like to thank Adam Korczynski ([`ADA Logics`](https://adalogics.com)) and John Howard (Google) for the report and the fix.
