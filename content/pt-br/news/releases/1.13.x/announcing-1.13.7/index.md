---
title: Announcing Istio 1.13.7
linktitle: 1.13.7
subtitle: Patch Release
description: Istio 1.13.7 patch release.
publishdate: 2022-08-01
release: 1.13.7
---

This release contains a fix for [CVE-2022-31045](/news/security/istio-security-2022-005/#cve-2022-31045) and
bug fixes to improve robustness. We recommend users install this release instead of Istio 1.13.6,
which does not contain the above CVE fix.
This release note describes what’s different between Istio 1.13.6 and Istio 1.13.7.

FYI, [Go 1.18.4 has been released](https://groups.google.com/g/golang-announce/c/nqrv9fbR0zE),
which includes 9 security fixes. We recommend you to upgrade to this newer Go version if you are using Go locally.

{{< relnote >}}

## Changes

- **Fixed** an issue causing `outboundTrafficPolicy` changes in `Sidecar` to not always take effect.  ([Issue #39794](https://github.com/istio/istio/issues/39794))

- **Removed** `archs` from `istio-ingress/egress` helm value templates and conditionally populate `nodeAffinity`.

# Security update

- **Fixed** [CVE-2022-31045](/news/security/istio-security-2022-005/#cve-2022-31045).
