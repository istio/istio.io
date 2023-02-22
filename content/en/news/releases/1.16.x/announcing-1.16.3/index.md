---
title: Announcing Istio 1.16.3
linktitle: 1.16.3
subtitle: Patch Release
description: Istio 1.16.3 patch release.
publishdate: 2023-02-21T08:00:00-06:00
release: 1.16.3
aliases:
    - /news/announcing-1.16.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.16.2 and Istio 1.16.3.

This release includes security fixes in Go 1.19.6 (released 2/14/2023) for the `path/filepath`, `net/http`, `mime/multipart`, and `crypto/tls` packages.

{{< relnote >}}

## Changes

- **Fixed** initialization of secure gRPC server of Pilot when serving certificates are provided in default location.  ([Issue #42249](https://github.com/istio/istio/issues/42249))

- **Fixed** the default behavior of generating manifests using the Helm chart library when using `istioctl` without `--cluster-specific` option to instead use the minimum Kubernetes version defined by `istioctl`.  [Issue #42441](https://github.com/istio/istio/issues/42441)

- **Fixed** admission webhook failing with custom header value format.
  ([Issue #42749](https://github.com/istio/istio/issues/42749))

- **Fixed** `istioctl proxy-config` failure when a user specifies a custom proxy admin port with `--proxy-admin-port`.  ([Issue #43063](https://github.com/istio/istio/issues/43063))

- **Fixed** an issue where `ALL_METRICS` does not disable metrics as expected.

- **Fixed** ignoring default CA certificate when `PeerCertificateVerifier` is created.

- **Fixed** istiod not reconciling Kubernetes Gateway deployments and services when they are changed.
  ([Issue #43332](https://github.com/istio/istio/issues/43332))

- **Fixed** an issue where Pilot status was logging too many errors when `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` was not enabled.
  ([Issue #42612](https://github.com/istio/istio/issues/42612))
