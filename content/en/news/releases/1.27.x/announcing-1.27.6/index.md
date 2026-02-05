---
title: Announcing Istio 1.27.6
linktitle: 1.27.6
subtitle: Patch Release
description: Istio 1.27.6 patch release.
publishdate: 2026-02-09
release: 1.27.6
aliases:
    - /news/announcing-1.27.6
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.27.5 and 1.27.6.

{{< relnote >}}

## Changes

- **Added** safeguards to the gateway deployment controller to validate object types, names, and namespaces,
  preventing creation of arbitrary Kubernetes resources through template injection.
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **Added** namespace-based authorization for debug endpoints on port 15014.
  Non-system namespaces are now restricted to `config_dump/ndsz/edsz` endpoints and same-namespace proxies only.
  If needed for compatibility, this behavior can be disabled with `ENABLE_DEBUG_ENDPOINT_AUTH=false`.

- **Added** `service.selectorLabels` field to the gateway Helm chart for custom service selector labels during revision-based migrations.

- **Fixed** resource annotation validation to reject newline and control characters that could inject containers into pod specs via template rendering.
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

- **Fixed** incorrect mapping of `meshConfig.tlsDefaults.minProtocolVersion` to `tls_minimum_protocol_version` in downstream TLS context.
