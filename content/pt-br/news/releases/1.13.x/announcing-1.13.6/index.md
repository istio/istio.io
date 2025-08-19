---
title: Announcing Istio 1.13.6
linktitle: 1.13.6
subtitle: Patch Release
description: Istio 1.13.6 patch release.
publishdate: 2022-07-25
release: 1.13.6
---

{{< warning >}}
Istio 1.13.6 does not contain a fix for [CVE-2022-31045](/news/security/istio-security-2022-005/#cve-2022-31045). We recommend users to not install Istio 1.13.6
and use Istio 1.13.5 for now. Istio 1.13.7 will be released later this week.
{{< /warning >}}

This release contains bug fixes to improve robustness.
This release note describes what's different between Istio 1.13.5 and 1.13.6.

FYI, [Go 1.18.4 has been released](https://groups.google.com/g/golang-announce/c/nqrv9fbR0zE),
which includes 9 security fixes. We recommend you to upgrade to this newer Go version if you are using Go locally.

{{< relnote >}}

## Changes

- **Fixed** building router's routes orders, a `catch all` route does not short circuit other routes behind it.  ([Issue #39188](https://github.com/istio/istio/issues/39188))

- **Fixed** a bug when updating a multi-cluster secret, the previous cluster is not stopped. Even deleting the secret will not stop the previous cluster.  ([Issue #39366](https://github.com/istio/istio/issues/39366))

- **Fixed** a bug when sending access logging to injected `OTel-collector` pod throws a `http2.invalid.header.field` error.  ([Issue #39196](https://github.com/istio/istio/issues/39196))

- **Fixed** an issue causing Service merging to only take into account the first and last Service, rather than all of them.
