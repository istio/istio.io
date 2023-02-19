---
title: Announcing Istio 1.17.1
linktitle: 1.17.1
subtitle: Patch Release
description: Istio 1.17.1 patch release.
publishdate: 2023-02-21
release: 1.17.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.17.0 and Istio 1.17.1.

{{< relnote >}}

## Changes

- **Added** env variables to support modifying grpc keepalive values. [Issue #42398](https://github.com/istio/istio/pull/42398)

- **Fixed** an issue where `ALL_METRICS` does not disable metrics as expected. [Issue #43178](https://github.com/istio/istio/issues/43178)

- **Fixed** ignoring default CA certificate when `PeerCertificateVerifier` is created. [PR #43337](https://github.com/istio/istio/pull/43337)

- **Fixed** istiod not reconciling k8s gateway deployments and services when they are changed. [Issue #43332](https://github.com/istio/istio/issues/43332)
