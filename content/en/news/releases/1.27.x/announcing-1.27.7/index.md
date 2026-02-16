---
title: Announcing Istio 1.27.7
linktitle: 1.27.7
subtitle: Patch Release
description: Istio 1.27.7 patch release.
publishdate: 2026-02-16
release: 1.27.7
aliases:
    - /news/announcing-1.27.7
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.27.7 and 1.27.6.

{{< relnote >}}

## Security update

- [CVE-2025-61732](https://github.com/advisories/GHSA-8jvr-vh7g-f8gx) (CVSS score 8.6, High): A discrepancy between how Go and C/C++ comments were parsed allowed for code smuggling into the resulting cgo binary.
- [CVE-2025-68121](https://github.com/advisories/GHSA-h355-32pf-p2xm) (CVSS score 4.8, Moderate): A flaw in crypto/tls session resumption allows resumed handshakes to succeed when they should fail if ClientCAs or RootCAs are mutated between the initial and resumed handshake. This can occur when using `Config.Clone` with mutations or `Config.GetConfigForClient`. As a result, clients may resume sessions with unintended servers, and servers may resume sessions with unintended clients.
