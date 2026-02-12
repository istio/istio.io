---
title: Announcing Istio 1.28.4
linktitle: 1.28.4
subtitle: Patch Release
description: Istio 1.28.4 patch release.
publishdate: 2026-02-16
release: 1.28.4
aliases:
    - /news/announcing-1.28.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.28.3 and 1.28.4.

{{< relnote >}}

## Changes

- **Added** an opt-in feature when using istio-cni in ambient mode to create a Istio owned CNI config
file which contains the contents of the primary CNI config file and the Istio CNI plugin. This
opt-in feature is a solution to the issue of traffic bypassing the mesh on node restart when the
istio cni deamonset is not ready, the Istio CNI plugin is not installed, or the plugin is not
invoked to configure traffic redirection from pods their node ztunnels. This feature is enabled by
setting cni.istioOwnedCNIConfig to true in the istio-cni Helm chart values. If no value is set for
cni.istioOwnedCNIConfigFilename, the Istio owned CNI config file will be named 02-istio-cni.conflist.
The istioOwnedCNIConfigFilename must have a higher lexicographical priority than the primary CNI.
Ambient and chained CNI plugins must be enabled for this feature to work.

- **Added** safeguards to the gateway deployment controller to validate object types, names, and namespaces,
preventing creation of arbitrary Kubernetes resources through template injection.
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **Added** a retry mechanism when checking if a pod is ambient enabled in istio-cni.
This is to address potential transient failures resulting in potential mesh bypassing. This feature
is disabled by default and can be enabled by setting `ambient.enableAmbientDetectionRetry` in the
`istio-cni` chart.

- **Added** namespace-based authorization for debug endpoints on port 15014.
Non-system namespaces restricted to config_dump/ndsz/edsz endpoints and same-namespace proxies only.
Disable with ENABLE_DEBUG_ENDPOINT_AUTH=false if needed for compatibility.

- **Fixed** translation function lookup errors for MeshConfig and MeshNetworks in istioctl
  ([Issue #57967](https://github.com/istio/istio/issues/57967))

- **Fixed** an unreported bug where BackendTLSPolicy status could lose track of the Gateway ancestorRef due to internal index corruption.
  ([Issue #58731](https://github.com/istio/istio/pull/58731))

- **Fixed** an issue where the `istio-cni` daemonSet treated NodeAffinity changes as upgrades,
causing CNI config to be incorrectly left in place when a node no longer matched the DaemonSet's NodeAffinity rules.
  ([Issue #58768](https://github.com/istio/istio/issues/58768))

- **Fixed** resource annotation validation to reject newlines and control characters that could inject containers into pod specs via template rendering.
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

- **Fixed** incorrect mapping of `meshConfig.tlsDefaults.minProtocolVersion` to `tls_minimum_protocol_version` in downstream TLS context.

- **Fixed** an issue causing the ambient multicluster cluster registry to become unstable periodically, leading to incorrect configuration being pushed to proxies.

## Security update

- [CVE-2025-61732](https://github.com/advisories/GHSA-8jvr-vh7g-f8gx) (CVSS score 8.6, High): A discrepancy between how Go and C/C++ comments were parsed allowed for code smuggling into the resulting cgo binary.
- [CVE-2025-68121](https://github.com/advisories/GHSA-h355-32pf-p2xm) (CVSS score 4.8, Moderate): A flaw in crypto/tls session resumption allows resumed handshakes to succeed when they should fail if ClientCAs or RootCAs are mutated between the initial and resumed handshake. This can occur when using `Config.Clone` with mutations or `Config.GetConfigForClient`. As a result, clients may resume sessions with unintended servers, and servers may resume sessions with unintended clients.
