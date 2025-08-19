---
title: Announcing Istio 1.19.1
linktitle: 1.19.1
subtitle: Patch Release
description: Istio 1.19.1 patch release.
publishdate: 2023-10-02
release: 1.19.1
---

This release note describes what’s different between Istio 1.19.0 and 1.19.1.

{{< relnote >}}

## Changes

- **Added** the ability to install the Gateway Helm chart with a dual-stack service definition.

- **Added** a new configuration to `ProxyConfig` and `ProxyHeaders`. This allows customization of headers like `server`, `x-forwarded-client-cert`, etc. Most notably, these can now be disabled so that they are not modified.

- **Added** a new configuration to `ProxyHeaders` and `MetadataExchangeHeaders`. The `IN_MESH` mode ensures `x-envoy-peer-metadata` and `x-envoy-peer-metadata-id`
headers will not be added to outbound requests from sidecars to destination services considered mesh external.
  ([Issue #17635](https://github.com/istio/istio/issues/17635))

- **Fixed** an issue where the upgrade warning is given incorrectly between default and revisioned control planes.

- **Fixed** an issue where ambient pods are incorrectly processed when the ambient namespace label is changed.

- **Fixed** an issue where the Istio CNI plugin was not writing IPv6 iptables rules for dual stack clusters.  ([Issue #46625](https://github.com/istio/istio/issues/46625))

- **Fixed** an issue where `meshConfig.defaultConfig.sampling` is ignored when there's only default providers.  ([Issue #46653](https://github.com/istio/istio/issues/46653))

- **Fixed** SDS fetching timeout when we do not push back invalid certificate to Envoy.
  ([Issue #46868](https://github.com/istio/istio/issues/46868))

- **Fixed** an issue where the installation process was failing due to failed verification of the `NetworkAttachmentDefinition` resource.
  ([Issue #46859](https://github.com/istio/istio/issues/46859))

- **Fixed** metric `DNSNoEndpointClusters` not working.
  ([Issue #46960](https://github.com/istio/istio/issues/46960))

- **Fixed** the output of `istioctl proxy-config all` to include EDS configuration when the `--json` or `--yaml` flags are used.

- **Fixed** an issue in control plane metrics causing gauge types to emit zero values without labels in addition to the expected metrics.
  ([Issue #46977](https://github.com/istio/istio/issues/46977))

## Security updates

There are no security updates in this release.
