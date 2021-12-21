---
title: Istio 1.11 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.11.0.
publishdate: 2021-08-12
weight: 20
---

When you upgrade from Istio 1.10.0 to Istio 1.11.0, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.10.0.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.10.0.

## The `istiodRemote` installation component now includes config cluster resources

Installing Istio on a remote cluster that is using an external control plane was previously done by disabling the `base` and `pilot`
components and enabling the `istiodRemote` component in the IOP:

{{< text yaml >}}
components:
  base:
    enabled: false
  pilot:
    enabled: false
  istiodRemote:
    enabled: true
values:
  global:
    externalIstiod: true
{{< /text >}}

If the remote cluster also serves as the config cluster for the external control plane,
the `base` component would also be enabled:

{{< text yaml >}}
components:
  base:
    enabled: true
  pilot:
    enabled: false
  istiodRemote:
    enabled: true
values:
  global:
    externalIstiod: true
{{< /text >}}

To simplify the implementation and to completely separate the remote installation from the `base` component,
the `istiodRemote` component now includes all of the charts needed for any remote cluster, whether it serves as a config
cluster or not. A new variable `values.global.configCluster` is used to enable/disable the resources needed
in a config cluster:

{{< text yaml >}}
components:
  base:
    enabled: false
  pilot:
    enabled: false
  istiodRemote:
    enabled: true
values:
  global:
    externalIstiod: true
    configCluster: true
{{< /text >}}

## Host header fallback disabled by default for Prometheus metrics for *all* inbound traffic

Host header fallback for determining values for Prometheus `destination_service` labels has been disabled for all incoming traffic.
Previously, this was disabled *only* for traffic arriving at Gateways. If you are relying on host header fallback behavior to properly
label the `destination_service` in Prometheus metrics for traffic originating from out-of-mesh workloads, then you will need to update the telemetry
configuration to enable host header fallback.

## `EnvoyFilter` `match.routeConfiguration.vhost.name` semantics change

`EnvoyFilter` matches rely on internal implementation details to match generated xDS segments, which is subject to change at any time.

In this release, the [virtual host name match](/docs/reference/config/networking/envoy-filter/#EnvoyFilter-RouteConfigurationMatch-VirtualHostMatch) may have different results.

Previously, each domain name had its own virtual host. As an optimization, multiple domains may use a single virtual host.
This means that an Envoy Filter previously matching a specific virtual host may now apply to more domains than in previous releases.

This optimization may be temporarily disabled by setting `PILOT_ENABLE_ROUTE_COLLAPSE_OPTIMIZATION=false` on the Istiod deployment.

## New `hostPath` added to CNI DaemonSet

A new `hostPath` volume `/var/run/istio-cni` is added to the CNI DaemonSet, which is used to collect CNI network plugin logs at CNI DaemonSet pod.
If you have `PodSecurityPolicy` defined to [allowlist `hostPaths`](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#volumes-and-file-systems) for your CNI DaemonSet,
`/var/run/istio-cni` also needs to be added to the list. CNI will not start in absence of this change.
