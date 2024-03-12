---
title: Announcing Istio 1.20.0
linktitle: 1.20.0
subtitle: Major Release
description: Istio 1.20 Release Announcement.
publishdate: 2023-11-14
release: 1.20.0
aliases:
- /news/announcing-1.20
- /news/announcing-1.20.0
---

We are pleased to announce the release of Istio 1.20. This is the last Istio release of 2023. We would like to thank the
entire Istio community for helping get the 1.20.0 release published. We would like to thank the Release Managers for
this release, `Xiaopeng Han` from DaoCloud, `Aryan Gupta` from Google, and `Jianpeng He` from Tetrate. The release
managers would specially like to thank the Test & Release WG lead Eric Van Norman (IBM) for his help and guidance
throughout the release cycle. We would also like to thank the maintainers of the Istio work groups and the broader Istio
community for helping us throughout the release process with timely feedback, reviews, community testing and for all
your support to help ensure a timely release.

{{< relnote >}}

{{< tip >}}
Istio 1.20.0 is officially supported on Kubernetes versions `1.25` to `1.28`.
{{< /tip >}}

## What's new

### Gateway API

The Kubernetes [Gateway API](http://gateway-api.org/) is an initiative to bring a rich set of service networking APIs
(similar to those of Istio VirtualService and Gateway) to Kubernetes.

Kubernetes [Gateway API is now GA](https://kubernetes.io/blog/2023/10/31/gateway-api-ga/)
and Istio provides [full support for it](https://gateway-api.sigs.k8s.io/implementations/#istio)!
This has been a widespread community effort
across the broader Kubernetes ecosystem that has produced multiple conformant implementations
(including [Istio's fully-conformant one](https://github.com/kubernetes-sigs/gateway-api/blob/main/conformance/reports/v1.0.0/istio-istio.yaml)).

This marks a significant milestone, as Istio users can now leverage the stable set of Gateway API
features for enhanced traffic management and ingress control in production environments.
Check out the [Gateway API task](/docs/tasks/traffic-management/ingress/gateway-api/) to get started.

In this release, we have also added support for configuring Istio
CRDs `AuthorizationPolicy`, `RequestAuthentication`, `Telemetry` and `WasmPlugin` for Kubernetes Gateway API via
the `targetRef` field.

### Revamped ExternalName Service Support

Istio 1.20 introduces a new update to `ExternalName` services, aligning more closely with Kubernetes behavior.
This change simplifies `ServiceEntry` definitions and enhances Istio's ability to handle DNS entries. Users can now
opt in to the new behavior in preparation for the upcoming default switch.

### Consistent Envoy Filter Ordering

A new consistent ordering for Envoy filters across inbound, outbound, and gateway proxies has been implemented,
ensuring that filters are applied uniformly, regardless of the traffic direction or protocol.

### Expanded Support for Network WasmPlugin

The extensibility of Istio is further broadened with support for network WasmPlugin with a new type `NETWORK`.

### TCP metadata exchange enhancements

Istio 1.20 brings two key updates to help control the TCP metadata exchange:

- **Fallback Metadata Discovery** Istio can now use a backup method to collect metadata. To use this, turn on
  the `PEER_METADATA_DISCOVERY` in the proxy and `PILOT_ENABLE_AMBIENT_CONTROLLERS` in the control plane.
- **ALPN Token Control**: There's a new setting called `PILOT_DISABLE_MX_ALPN` for the control plane. This lets you stop
  using a specific token `istio-peer-exchange` that's normally needed for services to talk to each other.

### Traffic Mirroring to Multiple Destinations

Traffic mirroring in Istio 1.20 now supports multiple destinations. This feature enables the mirroring of traffic to
various endpoints, allowing for simultaneous observation across different service versions or configurations.

### Plugged Root Cert Rotation

Security within Istio is improved through the added support for pluggable root certificate rotation.

### `StartupProbe` in Sidecar Containers

To enhance pod startup times, Istio now includes a `startupProbe` in sidecar containers by default. This proactive
measure allows for aggressive polling during the initial phase without persisting throughout the pod's lifecycle,
potentially reducing startup times by an average of one second and improving overall resource efficiency.

### OpenShift Installation Enhancements

Istio's installation process on OpenShift clusters has been simplified, removing the need for granting the `anyuid`
SCC privilege to Istio and applications.

### Enhancements to the `istioctl` command

Added a number of enhancements to the istioctl command including:

- The pilot monitoring port can now be auto-detected if it's not set to `15014`.
- `istioctl dashboard proxy` command has been added to display the admin UI for different kinds of proxies, including
  Envoy, Ztunnel, Waypoint.

## Upgrading to 1.20

We would like to hear from you regarding your experience upgrading to Istio 1.20. You can provide feedback
at [Discuss Istio](https://discuss.istio.io/), or join the #release-1.20 channel in
our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of
our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
