---
title: Announcing Istio 1.6.3
linktitle: 1.6.3
subtitle: Patch Release
description: Istio 1.6.3 patch release.
publishdate: 2020-06-18
release: 1.6.3
aliases:
    - /news/announcing-1.6.3
---

This release contains bug fixes to improve robustness. This release note describes
what’s different between Istio 1.6.2 and Istio 1.6.3.

{{< relnote >}}

## Changes

- **Fixed** an issue preventing the operator from recreating watched resources if they are deleted ([Issue 23238](https://github.com/istio/istio/issues/23238)).
- **Fixed** an issue where Istio crashed with the message: `proto.Message is *client.QuotaSpecBinding, not *client.QuotaSpecBinding`([Issue 24624](https://github.com/istio/istio/issues/24264)).
- **Fixed** an issue preventing operator reconciliation due to improper labels on watched resources ([Issue 23603](https://github.com/istio/istio/issues/23603)).
- **Added** support for the `k8s.v1.cni.cncf.io/networks` annotation ([Issue 24425](https://github.com/istio/istio/issues/24425)).
- **Updated** the `SidecarInjectionSpec` CRD to read the `imagePullSecret` from `.Values.global` ([Pull 24365](https://github.com/istio/istio/pull/24365)).
- **Updated** split horizon to skip gateways that resolve hostnames.
- **Fixed** `istioctl experimental metrics` to only flag error response codes as errors ([Issue 24322](https://github.com/istio/istio/issues/24322))
- **Updated** `istioctl analyze` to sort output formats.
- **Updated** gateways to use `proxyMetadata`
- **Updated** the Prometheus sidecar to use `proxyMetadata`([Issue 24415](https://github.com/istio/istio/pull/24415)).
- **Removed** invalid configuration from `PodSecurityContext` when `gateway.runAsRoot` is enabled ([Issue 24469](https://github.com/istio/istio/issues/24469)).

## Grafana addon security fixes

We've updated the version of Grafana shipped with Istio from 6.5.2 to 6.7.4. This addresses a Grafana security issue,
rated high, that can allow access to internal cluster resources using the Grafana avatar feature.
[(CVE-2020-13379)](https://grafana.com/blog/2020/06/03/grafana-6.7.4-and-7.0.2-released-with-important-security-fix/)
