---
title: Announcing Istio 1.23.2
linktitle: 1.23.2
subtitle: Patch Release
description: Istio 1.23.2 patch release.
publishdate: 2023-09-19
release: 1.23.2
---

This release fixes the security vulnerabilities described in our September 19th post, [ISTIO-SECURITY-2024-006](/news/security/istio-security-2024-006).
This release note describes what’s different between Istio 1.23.1 and 1.23.2.

{{< relnote >}}

## Security update

- __CVE-2024-XXXXX__:
  (CVSS Score 7.5, High): oghttp2 may crash on ObBeginHeadersForStream.

- __CVE-2024-XXXXX__:
  (CVSS Score 6.5, Moderate): Lack of validation for REQUESTED_SERVER_NAME field for access loggers enables injection of unexpected content into access logs.

- __CVE-2024-XXXXX__:
  (CVSS Score 6.5, Moderate): Potential for `x-envoy` headers to be manipulated by external sources.

- __CVE-2024-XXXXX__:
  (CVSS Score 5.3, Moderate): JWT filter crash in the clear route cache with remote JWKs.

- __CVE-2024-XXXXX__:
  (CVSS Score 6.5, Moderate): Envoy crashes for LocalReply in http async client.

# Changes

- **Fixed** `PILOT_SIDECAR_USE_REMOTE_ADDRESS` functionality on sidecars to support setting internal addresses to mesh network rather than localhost
to prevent header sanitzation.
  ([Issue #XXXXX](https://github.com/istio/istio/issues/XXXXX))