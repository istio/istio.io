---
title: Announcing Istio 1.29.10
linktitle: 1.29.10
subtitle: Patch Release
description: Istio 1.29.10 patch release.
publishdate: 2026-10-21
release: 1.29.10
aliases:
    - /news/announcing-1.29.10
---

This release contains security fixes. This release note describes what's different between Istio 1.29.9 and 1.29.10. 1.29 reached [end of life](/news/support/announcing-1.29-eol/) on October 15, 2026, and this is an exceptional release to address [ISTIO-SECURITY-2026-008](/news/security/istio-security-2026-008). We encourage you to upgrade to a supported release.

{{< relnote >}}

## Security update

For more information, see [ISTIO-SECURITY-2026-008](/news/security/istio-security-2026-008).

- **Removed** trust in the compromised eMudhra intermediate CA certificates. The CA bundle in the `ubuntu`-based and `distroless` images no longer includes `emSign ECC Root CA - G3`.
- **Updated** `rustls-webpki` in ztunnel to 0.103.16, which rejects certificate chains that contain any of the compromised eMudhra intermediate keys.
- Istio 1.29 is built with Go 1.25, which no longer receives fixes, so this release does not include the Go fix for [CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943). istiod, `istioctl`, and `pilot-agent` rely on the updated CA bundle only. Upgrade to 1.30.7 or 1.31.3 to get the Go fix.
