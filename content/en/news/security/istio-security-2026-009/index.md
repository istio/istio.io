---
title: ISTIO-SECURITY-2026-009
subtitle: Security Bulletin
description: Istio security fixes for ambient mode authorization and mTLS bypasses, sidecar traffic interception bypass, and istiod and ztunnel denial of service issues.
cves: []
cvss: "8.2"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N"
releases: ["1.31.0 to 1.31.3", "1.30.0 to 1.30.7"]
publishdate: 2026-11-06
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Istio CVEs

- __[GHSA-rr2c-p22p-6r9r](https://github.com/istio/istio/security/advisories/GHSA-rr2c-p22p-6r9r)__ (CVSS score 8.2, High): In ambient mode, an operator-precedence error let a port-level `STRICT` `PeerAuthentication` be skipped when the workload mode was `PERMISSIVE` or `DISABLE` under a mesh-wide `STRICT` policy, allowing plaintext traffic to reach a port that required mTLS.
  Reported by Ravikanth Reddy.
- __[GHSA-7m6f-j3gp-2r53](https://github.com/istio/istio/security/advisories/GHSA-7m6f-j3gp-2r53)__ (CVSS score 7.4, High): An `AuthorizationPolicy` `when` condition on `request.headers[:authority]` or `request.headers[host]` was matched case-sensitively, so a request with a differently-cased host could bypass it.
  Reported by [@akoul](https://github.com/akoul).
- __[GHSA-cxwg-46mx-q8hf](https://github.com/istio/istio/security/advisories/GHSA-cxwg-46mx-q8hf)__ (CVSS score 7.4, High): A new inbound connection reusing the 4-tuple of a torn-down connection could bypass the sidecar proxy by matching a stale conntrack `ESTABLISHED` entry.
  Reported by [@ramaraochavali](https://github.com/ramaraochavali), [@akshayreddyb](https://github.com/akshayreddyb), [@Pawan-Bishnoi](https://github.com/Pawan-Bishnoi), and [@deveshkandpal1224](https://github.com/deveshkandpal1224).
- __[GHSA-635j-qv98-9275](https://github.com/istio/istio/security/advisories/GHSA-635j-qv98-9275)__ (CVSS score 7.7, High): Any workload with a mesh identity could crash istiod by sending an `istio.io/debug` xDS request whose resource name fails URL parsing, leaving the control plane in a crash loop for the whole mesh.
  Reported by Alon Lerner of Checkmarx Research.
- __[GHSA-8jw7-82jp-wr2c](https://github.com/istio/istio/security/advisories/GHSA-8jw7-82jp-wr2c)__ (CVSS score 6.3, Moderate): In ambient mode, an `AuthorizationPolicy` with an empty `to` or `from` entry that was not rejected by the validating webhook caused istiod to crash and crash-loop until the policy was removed.
  Reported by [@r0binak](https://github.com/r0binak).
- __[GHSA-gf6w-6mxv-5fj4](https://github.com/istio/istio/security/advisories/GHSA-gf6w-6mxv-5fj4)__ (CVSS score 6.3, Moderate): In multicluster installations, a proxy could claim another cluster's `CLUSTER_ID` and receive that cluster's `kubernetes://` secrets over SDS.
  Reported by Yonghwa Lee (Xint by Theori).
- __[GHSA-77vw-rg85-wx5x](https://github.com/istio/ztunnel/security/advisories/GHSA-77vw-rg85-wx5x)__ (CVSS score 6.5, Moderate): ztunnel panicked when parsing a 55-byte `traceparent` header that did not contain four dash-separated fields, dropping every stream multiplexed on that inbound HBONE connection.
  Reported by [@RaphaelFakhri](https://github.com/RaphaelFakhri).

### Other Istio Security Fixes

- The JWKS resolver's periodic background refresh cached a fetched response without validating that it looked like a JWKS. The background refresh now applies the same check as the synchronous fetch path.
  Reported by Anthropic and Ada Logics.

## Am I Impacted?

- **Ambient mode:** You are potentially impacted by `GHSA-rr2c-p22p-6r9r` and `GHSA-8jw7-82jp-wr2c` if you use ambient mode with `PeerAuthentication` or `AuthorizationPolicy` resources, respectively.
- **Authorization:** You are potentially impacted by `GHSA-7m6f-j3gp-2r53` if you use `AuthorizationPolicy` conditions on `request.headers[:authority]` or `request.headers[host]`.
- **Sidecar interception:** You are potentially impacted by `GHSA-cxwg-46mx-q8hf` if you use sidecar traffic interception with iptables or nftables.
- **Multicluster:** You are potentially impacted by `GHSA-gf6w-6mxv-5fj4` if you run multicluster installations.
- **Denial of service:** All installations are potentially impacted by `GHSA-635j-qv98-9275`, and ambient mode installations by `GHSA-77vw-rg85-wx5x`.

## Mitigation

- For Istio 1.31 users: upgrade to **1.31.4** or later.
- For Istio 1.30 users: upgrade to **1.30.8** or later.
- Please check the advisory information for each GHSA listed above for more details on the vulnerabilities and their mitigations.
