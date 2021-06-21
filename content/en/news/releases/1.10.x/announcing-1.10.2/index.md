---
title: Announcing Istio 1.10.2
linktitle: 1.10.2
subtitle: Patch Release
description: Istio 1.10.2 patch release.
publishdate: 2021-06-24
release: 1.10.2
aliases:
    - /news/announcing-1.10.2
---

This release note describes what’s different between Istio 1.10.1 and Istio 1.10.2

{{< relnote >}}

# Changes

- **Improved** the `meshConfig.defaultConfig.proxyMetadata` field to do a deep merge when overriden rather than replacing all values.
  
- **Fixed** an issue where IPv6 iptables rules were incorrect when `includeOutboundPorts` annotations were used. ([Issue #30868](https://github.com/istio/istio/issues/30868))

- **Fixed** a bug where secret files were not watched after being removed and then added back. ([Issue #33293](https://github.com/istio/istio/issues/33293))

- **Fixed** an issue causing Envoy Filters that merged the `transport_socket` field and had a custom transport socket names to be ignored.
  
