---
title: Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.29.0.
weight: 20
---

When you upgrade from Istio 1.28.x to Istio 1.29.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.28.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.28.x.

## HTTP compression of Envoy metrics (`prometheus_stats`) enabled by default

The annotation `sidecar.istio.io/statsCompression` was deprecated and removed.

There is now a `statsCompression` option in `proxyConfig` to globally control compression support of the metrics endpoint (`prometheus_stats`) of Envoy.
The default value is `true`, offering `brotli`, `gzip` and `zstd` depending on the `Accept-Header` sent by the client.

Most metric scrapers allow individual configuration of compression. If you still need to override this per pod, you can set `statsCompression: false` via the `proxy.istio.io/config` annotation.

## Ambient DNS capture enabled by default

DNS proxying is enabled by default for ambient workloads in this release. Note that only new pods will have DNS enabled; existing pods will not have their DNS traffic captured.
To enable this feature for existing pods, existing pods must either be manually restarted, or alternatively the iptables reconciliation feature can be enabled when upgrading
`istio-cni` via `--set cni.ambient.reconcileIptablesOnStartup=true`, which will reconcile existing pods automatically on upgrade.

## Upgrading in ambient mode with dry-run AuthorizationPolicy

If you use dry-run AuthorizationPolicy and wish to enable this new feature, the upgrade to 1.29 includes some important considerations. Prior to Istio 1.29, ztunnel did not have any capability to handle dry-run AuthorizationPolicy. As a result, istiod would not send any dry-run policy to ztunnel. Istio 1.29 introduces experimental support for dry-run AuthorizationPolicy in ztunnel. Setting `AMBIENT_ENABLE_DRY_RUN_AUTHORIZATION_POLICY=true` will cause istiod to begin sending dry-run policies to ztunnel, using a new field in xDS. A ztunnel below version 1.29 will not support this field. As a result, older ztunnels will fully enforce these policies, which is likely to produce an unexpected result. To ensure a smooth upgrade, it is important to ensure that all ztunnel proxies connecting to an istiod with this feature enabled are new enough to correctly handle these policies.

## Debug endpoint authorization enabled by default

Tools accessing debug endpoints from non-system namespaces (such as Kiali or custom monitoring tools)
may be affected. Non-system namespaces are now restricted to `config_dump`, `ndsz`, and `edsz` endpoints
for same-namespace proxies only. To restore the previous behavior, set `ENABLE_DEBUG_ENDPOINT_AUTH=false`.

## Circuit breaker metrics tracking behavior change

The default behavior for circuit breaker remaining metrics tracking has changed. Previously, these metrics
were tracked by default. Now, tracking is disabled by default for better proxy memory usage.

To maintain the previous behavior where remaining metrics were tracked, you can:

1. Set the environment variable `DISABLE_TRACK_REMAINING_CB_METRICS=false` in your istiod deployment
1. Use the compatibility version feature to get the legacy behavior

This change affects the `TrackRemaining` field in Envoy's circuit breaker configuration.

## Base Helm chart removals

A number of configurations previously present in the `base` Helm chart were *copied* to the `istiod` chart in previous releases.

In this release, the duplicated configurations are fully removed from the `base` chart.

The table below shows a mapping of old configuration to new configuration:

| Old                                     | New                                     |
| --------------------------------------- | --------------------------------------- |
| `ClusterRole istiod`                    | `ClusterRole istiod-clusterrole`        |
| `ClusterRole istiod-reader`             | `ClusterRole istio-reader-clusterrole`  |
| `ClusterRoleBinding istiod`             | `ClusterRoleBinding istiod-clusterrole` |
| `Role istiod`                           | `Role istiod`                           |
| `RoleBinding istiod`                    | `RoleBinding istiod`                    |
| `ServiceAccount istiod-service-account` | `ServiceAccount istiod`                 |

Note: most resources have a suffix automatically added in addition.
In the old chart, this was `-{{ .Values.global.istioNamespace }}`.
In the new chart it is `{{- if not (eq .Values.revision "") }}-{{ .Values.revision }}{{- end }}` for namespace scoped resources, and `{{- if not (eq .Values.revision "")}}-{{ .Values.revision }}{{- end }}-{{ .Release.Namespace }}` for cluster scoped resources.

## Ambient iptables reconciliation enabled by default

Iptables reconciliation is enabled by default for ambient workloads in release 1.29.0. When a new `istio-cni` DaemonSet pod starts up,
it will automatically inspect pods that were previously enrolled in the ambient mesh and upgrade their in-pod iptables/nftables rules to the current state
if there are any differences. This feature can be disabled explicitly with `--set cni.ambient.reconcileIptablesOnStartup=false`.
