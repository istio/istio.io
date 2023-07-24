---
title: Announcing Istio 1.18.2
linktitle: 1.18.2
subtitle: Patch Release
description: Istio 1.18.2 patch release.
publishdate: 2023-07-25
release: 1.18.2
---

This release fixes the security vulnerabilities described in our July 25th post, [ISTIO-SECURITY-2023-003](/news/security/istio-security-2023-003).

This release note describes what’s different between Istio 1.18.1 and 1.18.2.

{{< relnote >}}

## Security update

- __CVE-2023-35941__: (CVSS Score 8.6, High): OAuth2 credentials exploit with permanent validity.
- __CVE-2023-35942__: (CVSS Score 6.5, Moderate): gRPC access log crash caused by the listener draining.
- __CVE-2023-35943__: (CVSS Score 6.3, Moderate): CORS filter segfault when origin header is removed.
- __CVE-2023-35944__: (CVSS Score 8.2, High): Incorrect handling of HTTP requests and responses with mixed case schemes in Envoy.

## Changes

- **Added** support for a flag called `USE_EXTERNAL_WORKLOAD_SDS`. When set to true, it will require an external SDS workload socket and will prevent the istio-proxy from starting if the workload SDS socket is not found. ([Issue #45534](https://github.com/istio/istio/issues/45534))
