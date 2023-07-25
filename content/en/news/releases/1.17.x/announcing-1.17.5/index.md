---
title: Announcing Istio 1.17.5
linktitle: 1.17.5
subtitle: Patch Release
description: Istio 1.17.4 patch release.
publishdate: 2023-07-25
release: 1.17.5
---

This release fixes the security vulnerabilities described in our July 25th post, [ISTIO-SECURITY-2023-003](/news/security/istio-security-2023-003).

This release note describes what’s different between Istio 1.17.4 and 1.17.5.

{{< relnote >}}

## Security update

- __CVE-2023-35941__: (CVSS Score 8.6, High): OAuth2 credentials exploit with permanent validity.
- __CVE-2023-35942__: (CVSS Score 6.5, Moderate): gRPC access log crash caused by the listener draining.
- __CVE-2023-35943__: (CVSS Score 6.3, Moderate): CORS filter segfault when origin header is removed.
- __CVE-2023-35944__: (CVSS Score 8.2, High): Incorrect handling of HTTP requests and responses with mixed case schemes in Envoy.
