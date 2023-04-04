---
title: Announcing Istio 1.15.7
linktitle: 1.15.7
subtitle: Patch Release
description: Istio 1.15.7 patch release.
publishdate: 2023-04-04T07:00:00-06:00
release: 1.15.7
---

This release fixes the security vulnerabilities described in our April 4th post, [ISTIO-SECURITY-2023-001](/news/security/istio-security-2023-001).
This release note describes what’s different between Istio 1.15.6 and 1.15.7.

{{< relnote >}}

## Security update

- __CVE-2023-27487__:
  (CVSS Score 8.2, High): Client may fake the header `x-envoy-original-path`.

- __CVE-2023-27488__:
  (CVSS Score 5.4, Moderate): gRPC client produces invalid protobuf when an HTTP header with non-UTF8 value is received.

- __CVE-2023-27491__:
  (CVSS Score 5.4, Moderate): Envoy forwards invalid HTTP/2 and HTTP/3 downstream headers.

- __CVE-2023-27492__:
  (CVSS Score 4.8, Moderate): Crash when a large request body is processed in Lua filter.

- __CVE-2023-27493__:
  (CVSS Score 8.1, High): Envoy doesn't escape HTTP header values.

- __CVE-2023-27496__:
  (CVSS Score 6.5, Moderate): Crash when a redirect url without a state parameter is received in the OAuth filter.

## Changes

- **Fixed** an issue where you could not change `PrivateKeyProvider` using proxy-config.
  ([Issue #41760](https://github.com/istio/istio/issues/41760))

- **Fixed** an issue where `istioctl analyze` was throwing a SIGSEGV when the optional field 'filter'
was missing under the `EnvoyFilter.ListenerMatch.FilterChainMatch` section.
  ([Issue #42831](https://github.com/istio/istio/issues/42831))

- **Fixed** an issue where `EnvoyFilter` for `Cluster.ConnectTimeout` was affecting unrelated `Clusters`.
  ([Issue #43435](https://github.com/istio/istio/issues/43435))
