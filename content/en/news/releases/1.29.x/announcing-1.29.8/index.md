---
title: Announcing Istio 1.29.8
linktitle: 1.29.8
subtitle: Patch Release
description: Istio 1.29.8 patch release.
publishdate: 2026-09-21
release: 1.29.8
aliases:
    - /news/announcing-1.29.8
---

This release contains bug fixes to improve robustness. This release note describes what's different between Istio 1.29.7 and 1.29.8.

{{< relnote >}}

## Changes

- **Fixed** an issue in ambient mode where the CNI node agent's auto-detected iptables backend
  (`legacy` vs `nft`) could flip between agent restarts, causing duplicate
  redirect rules to be written into already-enrolled pods.
  ([Issue #61020](https://github.com/istio/istio/issues/61020))

- **Fixed** the JWKS resolver forcing all public-key fetches to HTTP/1.1. The custom
  `TLSClientConfig` and `DialContext` used for TLS pinning and CIDR blocking caused Go's
  `net/http` to disable automatic HTTP/2, so ALPN never negotiated h2. HTTP/2 is now
  re-enabled (matching `http.DefaultTransport`), fixing JWKS fetches that fail over HTTP/1.1
  through some HTTP CONNECT proxies.
  ([Issue #61250](https://github.com/istio/istio/issues/61250))

- **Fixed** an issue where istiod repeatedly serialized the same workload when
  pushing workload metadata to Envoy proxies.
  ([Issue #61502](https://github.com/istio/istio/issues/61502))

- **Fixed** an issue where the network gateway selected for a workload was picked in a random
  order when a network had more than one gateway entry, which caused unnecessary workload
  (WDS) pushes on every recompute and could cause a workload's gateway address to alternate.

- **Fixed** `istioctl analyze` building Kubernetes clients directly from `istio-system`
  multicluster secrets without sanitizing the kubeconfig, which could allow a crafted
  secret to run an `exec` credential plugin (or read local files via other unsafe auth
  fields) on the machine running `istioctl`. The kubeconfig is now sanitized the same
  way istiod already sanitizes these secrets.

  **Credit**: This vulnerability was discovered and reported by Adam Korczynski.
