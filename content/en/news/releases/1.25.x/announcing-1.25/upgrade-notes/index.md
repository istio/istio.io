---
title: Istio 1.25 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.25.0.
weight: 20
publishdate: 2025-03-03
---

When upgrading from Istio 1.24.x to Istio 1.25.x, please consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.24.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.24.x.

## Ambient mode pod upgrade reconciliation

When a new `istio-cni` `DaemonSet` pod starts up, it will inspect pods that were previously enrolled in the ambient mesh, and upgrade their in-pod iptables rules to the current state if there is a diff or delta. This is off by default as of 1.25.0, but will eventually be enabled by default. This feature can be enabled by `helm install cni --set ambient.reconcileIptablesOnStartup=true` (Helm) or `istioctl install --set values.cni.ambient.reconcileIptablesOnStartup=true` (istioctl).

## DNS traffic (TCP and UDP) now respects traffic exclusion annotations

DNS traffic (UDP and TCP) now respects pod-level traffic annotations like `traffic.sidecar.istio.io/excludeOutboundIPRanges` and `traffic.sidecar.istio.io/excludeOutboundPorts`. Before, UDP/DNS traffic would uniquely ignore these traffic annotations, even if a DNS port was specified, because of the rule structure. This behavior change actually happened in the 1.23 release series, but was left out of the release notes for 1.23.

## Ambient mode DNS capture on by default

DNS proxying is enabled by default for ambient mode workloads in this release. Note that only new pods will have DNS enabled: existing pods will not have their DNS traffic captured. To enable this feature for existing pods, they must either be manually restarted, or alternatively the iptables reconciliation feature can be enabled when upgrading `istio-cni` via `--set cni.ambient.reconcileIptablesOnStartup=true`. This will reconcile existing pods automatically on upgrade.

Individual pods may opt-out of global ambient mode DNS capture by applying the`ambient.istio.io/dns-capture=false` annotation.

## Grafana dashboard changes

The dashboards shipped with Istio 1.25 require version 7.2 or later of Grafana.

## OpenCensus support has been removed

Because Envoy has [removed the OpenCensus tracing extension](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.33/v1.33.0.html#incompatible-behavior-changes), we have
removed OpenCensus support from Istio. If you are using OpenCensus, you should migrate to OpenTelemetry.  [Learn more about the deprecation of OpenCensus](https://opentelemetry.io/blog/2023/sunsetting-opencensus/).

## ztunnel Helm chart changes

In previous releases, resources in the ztunnel Helm chart were always named `ztunnel`.
In this release, they are now named `.Resource.Name`.

If you are installing the chart with a release name other than `ztunnel`, the resource names will change, triggering downtime.
In this scenario, it is recommended to set `--set resourceName=ztunnel` to override back to the previous default.
