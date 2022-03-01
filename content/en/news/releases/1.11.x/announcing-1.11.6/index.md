---
title: Announcing Istio 1.11.6
linktitle: 1.11.6
subtitle: Patch Release
description: Istio 1.11.6 patch release.
publishdate: 2022-02-03
release: 1.11.6
aliases:
    - /news/announcing-1.11.6
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.11.5 and Istio 1.11.6

{{< relnote >}}

## Changes

- **Added** privileged flag to Istio-CNI Helm charts to set `securityContext` flag.
  ([Issue #34211](https://github.com/istio/istio/issues/34211))

- **Added** an option to disable a number of nonstandard kubeconfig authentication methods when using multicluster secret by configuring the
`PILOT_INSECURE_MULTICLUSTER_KUBECONFIG_OPTIONS` environment variable in Istiod. By default, this option is configured to allow all methods; future versions will restrict this by default.

- **Fixed** an issue where enabling tracing with telemetry API would cause a malformed host header being used at the trace report request.  ([Issue #35750](https://github.com/istio/istio/issues/35750)),([Issue #36166](https://github.com/istio/istio/issues/36166)),([Issue #36521](https://github.com/istio/istio/issues/36521))

- **Fixed** error format after json marshal in virtual machine config.
  ([Issue #36358](https://github.com/istio/istio/issues/36358))

- **Fixed** endpoint slice cache memory leak.

- **Fixed** an issue where `EnvoyFilter` patches on `virtualOutbound-blackhole` could cause memory leaks.

- **Fixed** an issue where using `ISTIO_MUTUAL` TLS mode in Gateways while also setting `credentialName` causes mutual TLS to not be configured.
For backwards compatibility, this only introduces a warning. To enable the new behavior, set the `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME=false`
environment variable in Istiod. This will cause invalid configurations to be rejected, and will be the default behavior in future releases.
