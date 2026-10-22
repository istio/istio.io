---
title: ISTIO-SECURITY-2026-008
subtitle: Security Bulletin
description: Distrust of compromised eMudhra intermediate CA certificates in Istio images, Go, and ztunnel.
cves: [CVE-2026-111943]
cvss: "N/A"
vector: ""
releases: ["1.31.0 to 1.31.2", "1.30.0 to 1.30.6", "1.29.0 to 1.29.9"]
publishdate: 2026-10-21
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## eMudhra intermediate CA compromise

The private keys of eight eMudhra intermediate CA certificates, including their Sectigo cross-signs, were [disclosed as compromised](https://emudhra.we-have-a-problem.com/) on October 20, 2026. Anyone holding one of these keys can issue certificates for any domain that chains to roots trusted by the public CA bundles shipped in Istio images. Browsers that enforce Certificate Transparency were protected, but Envoy, Go, and ztunnel do not enforce Certificate Transparency.

This release removes trust in these intermediates:

- The CA bundle in the Istio `ubuntu`-based images is updated to `ca-certificates` `20260816ubuntu0.24.04.1`, which removes `emSign ECC Root CA - G3`.
- The `distroless` images are rebuilt on an updated `cgr.dev/chainguard/static` base, which removes `emSign ECC Root CA - G3`.
- __[CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943)__: istiod, `istioctl`, and `pilot-agent` are built with Go 1.26.10 (Istio 1.30 and 1.31), which rejects certificate chains that contain any of the compromised intermediate keys, regardless of the trusted roots. Istio 1.29 is built with Go 1.25, which no longer receives fixes, and relies on the updated CA bundle only. We encourage 1.29 users to upgrade to a supported release to get the Go fix.
- ztunnel is updated to `rustls-webpki` 0.103.16, which rejects certificate chains that contain any of the compromised intermediate keys.

Envoy has no built-in list of distrusted keys and does not check revocation unless a CRL is configured, so sidecars and gateways rely on the updated CA bundle.

## Am I Impacted?

Istio's own mesh mTLS certificates are not affected. You are potentially impacted if Istio trusts the public CA bundle in the image, for example:

- A `DestinationRule` with `tls.mode: SIMPLE` and no `caCertificates` or `credentialName`, which is common for egress to external HTTPS services through a `ServiceEntry`.
- `RequestAuthentication` with a `jwksUri`, which istiod fetches using the system CA bundle.
- `XDS_ROOT_CA=SYSTEM` or other configurations where `pilot-agent` or ztunnel connect to istiod using the system CA bundle.

## Mitigation

- For Istio 1.31 users: upgrade to **1.31.3** or later.
- For Istio 1.30 users: upgrade to **1.30.7** or later.
- For Istio 1.29 users: upgrade to **1.29.10**. 1.29 reached [end of life](/news/support/announcing-1.29-eol/) on October 15, 2026, and this is an exceptional release. Plan an upgrade to 1.30 or later.
- If you cannot upgrade, set `caCertificates` (or `credentialName`) on `DestinationRule` resources for external services instead of relying on the system CA bundle, or set `caCrl` with the CRLs of the revoked intermediates.
