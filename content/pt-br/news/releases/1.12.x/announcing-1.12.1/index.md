---
title: Announcing Istio 1.12.1
linktitle: 1.12.1
subtitle: Patch Release
description: Istio 1.12.1 patch release.
publishdate: 2021-12-07
release: 1.12.1
aliases:
    - /news/announcing-1.12.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.12.0 and Istio 1.12.1

{{< relnote >}}

## Changes

- **Added** istiod deployment respect `values.pilot.nodeSelector`.
  ([Issue #36110](https://github.com/istio/istio/issues/36110))

- **Added** an option to disable a number of nonstandard kubeconfig authentication methods when using multicluster secret by configuring the `PILOT_INSECURE_MULTICLUSTER_KUBECONFIG_OPTIONS` environment variable in Istiod. By default, this option is configured to allow all methods; future versions will restrict this by default.

- **Fixed** the `--duration` flag never gets used in the `istioctl bug-report` command.

- **Fixed** using flags in `istioctl bug-report` results in errors.
  ([Issue #36103](https://github.com/istio/istio/issues/36103))

- **Fixed** `DeploymentConfig`/`ReplicationController` workload name doesn't work correctly.

- **Fixed** some control plane messages may be omitted in the bug-report.

- **Fixed** webhook analyzer throwing nil pointer error when the `NamespaceSelector` field is empty.

- **Fixed** workload name metric labels are not correctly populated for `CronJob` at k8s 1.21+.
  ([Issue #35563](https://github.com/istio/istio/issues/35563))

- **Fixed** an issue where `EnvoyFilter` with ANY patch context will skip adding new clusters and listeners at gateway.

- **Fixed** an issue where `EnvoyFilter` patches on `virtualOutbound-blackhole` could cause memory leaks.
