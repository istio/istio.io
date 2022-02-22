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

- __[CVE-2022-23635](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-23635])__:
  CVE-2022-23635 (CVSS Score 7.5, High):  Unauthenticated control plane denial of service attack.

The Istio control plane, istiod, is vulnerable to a request processing error, allowing a malicious attacker that
sends a specially crafted message which results in the control plane crashing. This endpoint is served over TLS port 15012,
but does not require any authentication from the attacker.

For simple installations, istiod is typically only reachable from within the cluster, limiting the blast radius. However, for some deployments, especially [multicluster topologies](/docs/setup/install/multicluster/primary-remote/), this port is exposed over the public internet.

### Envoy CVEs

At this time it is not believed that Istio is vulnerable to these CVEs in Envoy. They are listed, however,
to be transparent.

- __[CVE-2021-43824](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2021-43824])__:
  CVE-2021-43824 (CVSS Score 6.5, Medium): Envoy 1.21.0 and earlier - Potential null pointer dereference when using JWT filter `safe_regex` match.

- __[CVE-2021-43825](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2021-43825])__:
  CVE-2021-43825 (CVSS Score 6.1, Medium): Envoy 1.21.0 and earlier - Use-after-free when response filters increase response data, and increased data exceeds downstream buffer limits.

- __[CVE-2021-43826](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2021-43826])__:
  CVE-2021-43826 (CVSS Score 6.1, Medium): Envoy 1.21.0 and earlier - Use-after-free when tunneling TCP over HTTP, if downstream disconnects during upstream connection establishment.

- __[CVE-2022-21654](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-21654])__:
  CVE-2022-21654 (CVSS Score 7.3, High): Envoy 1.7.0 and later - Incorrect configuration handling allows mTLS session re-use without re-validation after validation settings have changed.

- __[CVE-2022-21655](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-21655])__:
  CVE-2022-21655 (CVSS Score 7.5, High): Envoy 1.21 and earlier - Incorrect handling of internal redirects to routes with a direct response entry.

The following CVE did not apply to Istio 1.11.6.

- __[CVE-2022-23606](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-23606])__:
  CVE-2022-23606 (CVSS Score 4.4, Moderate): Envoy 1.20 and later - Stack exhaustion when a cluster is deleted via Cluster Discovery Service.

## Am I Impacted?

You are at most risk if you are running Istio in a multi-cluster environment, or if you have exposed your istiod externally.

## Credit

We would like to thank John Howard (Google) for the report and the fix.
