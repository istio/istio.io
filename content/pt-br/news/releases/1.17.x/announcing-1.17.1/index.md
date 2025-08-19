---
title: Announcing Istio 1.17.1
linktitle: 1.17.1
subtitle: Patch Release
description: Istio 1.17.1 patch release.
publishdate: 2023-02-23T09:00:00-06:00
release: 1.17.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.17.0 and Istio 1.17.1.

This release includes security fixes included in Go 1.20.1 (released 2023-02-14) for the `crypto/tls`, `mime/multipart`, `net/http`, and `path/filepath` packages.

{{< relnote >}}

## Changes

- **Added** environment variables to support modifying gRPC keepalive values. [Issue #42398](https://github.com/istio/istio/pull/42398)

- **Fixed** an issue where `ALL_METRICS` does not disable metrics as expected. [Issue #43178](https://github.com/istio/istio/issues/43178)

- **Fixed** ignoring default CA certificate when `PeerCertificateVerifier` is created. [PR #43337](https://github.com/istio/istio/pull/43337)

- **Fixed** istiod not reconciling Kubernetes Gateway deployments and services when they are changed. [Issue #43332](https://github.com/istio/istio/issues/43332)

- **Fixed** reporting `Programmed` condition on Gateway API Gateway resources. [Issue #43498](https://github.com/istio/istio/issues/43498)

- **Fixed** an issue where updating service `ExternalName` does not take effect. [Issue #43440](https://github.com/istio/istio/issues/43440)
