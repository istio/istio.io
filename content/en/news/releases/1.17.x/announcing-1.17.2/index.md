---
title: Announcing Istio 1.17.2
linktitle: 1.17.2
subtitle: Patch Release
description: Istio 1.17.2 patch release.
publishdate: 2023-03-14
release: 1.17.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.17.1 and Istio 1.17.2.

{{< relnote >}}

## Changes

- **Added** support for pushing additional federated trust domains from `caCertificates` to the peer SAN validator. [Issue #41666](https://github.com/istio/istio/issues/41666)

- **Fixed** an issue where `EnvoyFilter` for `Cluster.ConnectTimeout` was affecting unrelated `Clusters`. [Issue # 43435](https://github.com/istio/istio/issues/43435)

- **Fixed** a bug that would cause unexpected behavior when applying access logging configuration based on the direction of traffic. With this fix, access logging configuration for `CLIENT` or `SERVER` will not affect each other. [Issue # 43371](https://github.com/istio/istio/issues/43371)

- **Fixed** a bug in `istioctl analyze` where some messages are missed when there are services with no selector in the analyzed namespace. [PR #43678](https://github.com/istio/istio/pull/43678)

- **Fixed** resource namespace resolution for `istioctl` commands. [Issue #43691](https://github.com/istio/istio/issues/43691)

- **Fixed** an issue where RBAC updates were not sent to older proxies after upgrading istiod to 1.17. [Issue #43785](https://github.com/istio/istio/issues/43785)

- **Fixed** an issue where auto allocated service entry IPs change on host reuse. [Issue #43858](https://github.com/istio/istio/issues/43858)

