---
title: Announcing Istio 1.12.2
linktitle: 1.12.2
subtitle: Patch Release
description: Istio 1.12.2 patch release.
publishdate: 2022-01-18
release: 1.12.2
aliases:
    - /news/announcing-1.12.2
---

This release fixes security vulnerabilities described on January 18th ([ISTIO-SECURITY-2022-001](/news/security/istio-security-2022-001) and [ISTIO-SECURITY-2022-002](/news/security/istio-security-2022-002)) and includes minor bug fixes to improve robustness. This release note describes what’s different between Istio 1.12.1 and Istio 1.12.2.

{{< relnote >}}

## Security Update

- __[CVE-2022-21679](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2CVE-2022-21679i])__:
  Istio versions 1.12.0 and 1.12.1 contain a vulnerability where configuration for proxies at version 1.11 is generated incorrectly, affecting the `hosts` and `notHosts` field in the authorization policy.

- __[CVE-2022-21701](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2CVE-2022-21679i])__:
  Istio versions 1.12.0 and 1.12.1 are vulnerable to a privilege escalation attack. Users who have `CREATE` permission for `gateways.gateway.networking.k8s.io` objects can escalate this privilege to create other resources that they may not have access to, such as `Pod`.

## Changes

- **Added** privileged flag to Istio-CNI Helm charts to set `securityContext` flag.
  ([Issue #34211](https://github.com/istio/istio/issues/34211))

- **Fixed** an issue where enabling tracing with telemetry API would cause a malformed host header being used at the trace report request.
  ([Issue #35750](https://github.com/istio/istio/issues/35750))

- **Fixed** `istioctl pc log` command label selector not selecting the default pod.
  ([Issue #36182](https://github.com/istio/istio/issues/36182))

- **Fixed** an issue where `istioctl analyze` falsely warned of a VirtualService prefix match overlap.
  ([Issue #36245](https://github.com/istio/istio/issues/36245))

- **Fixed** omitted setting `.Values.sidecarInjectiorWebhook.enableNamespacesByDefault` in the default revision
mutating webhook and added --auto-inject-namespaces flag to `istioctl tag` controlling this setting.
  ([Issue #36258](https://github.com/istio/istio/issues/36258))

- **Fixed** values in the Istio Gateway Helm charts for configuring annotations on the Service. Can be used to configure load balancer in public clouds.
  ([Pull Request #36384](https://github.com/istio/istio/pull/36384))

- **Fixed** the incorrect format of version and revision in the build info.
  ([Pull Request #36409](https://github.com/istio/istio/pull/36409))

- **Fixed** an issue where stale endpoints can be configured when a service gets deleted and created again.
  ([Issue #36510](https://github.com/istio/istio/issues/36510))

- **Fixed** an issue that sidecar iptables will cause intermittent connection reset due to the out of window packet.
Introduced a flag `meshConfig.defaultConfig.proxyMetadata.INVALID_DROP` to control this setting.
  ([Issue #36489](https://github.com/istio/istio/issues/36489))

- **Fixed** `operator init --dry-run` creates unexpected namespaces.
  ([Pull Request #36570](https://github.com/istio/istio/pull/36570))

- **Fixed** an issue where setting `includeInboundPorts` with helm values does not take effect.
  ([Issue #36644](https://github.com/istio/istio/issues/36644))

- **Fixed** endpoint slice cache memory leak.
  ([Pull Request #36518](https://github.com/istio/istio/pull/36518))

- **Fixed** changes in delegate virtual service not taking effect when RDS cache enabled.
  ([Issue #36525](https://github.com/istio/istio/issues/36525))

- **Fixed** an issue when using Envoy [`v3alpha`](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.20.0#incompatible-behavior-changes) APIs in `EnvoyFilter`s.
  ([Issue #36537](https://github.com/istio/istio/issues/36537))
