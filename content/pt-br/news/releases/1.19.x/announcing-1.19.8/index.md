---
title: Announcing Istio 1.19.8
linktitle: 1.19.8
subtitle: Patch Release
description: Istio 1.19.8 patch release.
publishdate: 2024-03-14
release: 1.19.8
---

This release note describes what’s different between Istio 1.19.7 and 1.19.8.

{{< relnote >}}

## Changes

- **Added** an environment variable `COMPLIANCE_POLICY` to Istio components for
  enforcing TLS restriction for compliance with FIPS. When set to `fips-140-2`
  on the Istiod container, the Istio Proxy container, and all other Istio
  components, the TLS version is restricted to v1.2. The cipher suites are limited to a subset
  of `ECDHE-ECDSA-AES128-GCM-SHA256`, `ECDHE-RSA-AES128-GCM-SHA256`,
  `ECDHE-ECDSA-AES256-GCM-SHA384`, `ECDHE-RSA-AES256-GCM-SHA384`, and ECDH
  curves to `P-256`.

    These restrictions apply on the following data paths:
    * mTLS communication between Envoy proxies;
    * regular TLS on the downstream and the upstream of Envoy proxies (e.g. gateway);
    * Google gRPC side requests from Envoy proxies (e.g. Stackdriver extensions);
    * Istiod xDS server;
    * Istiod injection and validation webhook servers.

    The restrictions are not applied on the following data paths:
    * Istiod to Kubernetes API server;
    * JWK fetch from Istiod;
    * Wasm image and URL fetch from Istio Proxy containers;
    * ztunnel.

  Note that Istio injector will propagate the value of `COMPLIANCE_POLICY` to the
  injected proxy container, when set.
  ([Issue #49081](https://github.com/istio/istio/issues/49081))

- **Fixed** an issue where the local client contained incorrect entries in the local DNS name
  table. ([Issue #47340](https://github.com/istio/istio/issues/47340))

- **Fixed** a bug where `VirtualService` containing wildcard hosts that aren't present in the service registry are
  ignored.
  ([Issue #49364](https://github.com/istio/istio/issues/49364))

- **Fixed** an issue where `istioctl precheck` inaccurately reports the IST0141 message related to resource permissions.
  ([Issue #49379](https://github.com/istio/istio/issues/49379))

- **Fixed** an issue that when using a delegate in a `VirtualService`, the effective `VirtualService` may not be
  consistent with expectations due to a sorting error.
  ([Issue #49539](https://github.com/istio/istio/issues/49539))

- **Fixed** a bug where specifying a URI regex `.*` match within a `VirtualService` HTTP route did not short-circuit the
  subsequent HTTP routes.
