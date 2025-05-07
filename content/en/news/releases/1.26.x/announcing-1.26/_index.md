---
title: Announcing Istio 1.26.0
linktitle: 1.26.0
subtitle: Major Release
description: Istio 1.26 Release Announcement.
publishdate: 2025-05-08
release: 1.26.0
aliases:
    - /news/announcing-1.26
    - /news/announcing-1.26.0
---

We are pleased to announce the release of Istio 1.26. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.26.0 release published!
We would like to thank the Release Managers for this release, **Daniel Hawton** from Solo.io, **Faseela K** from Ericsson Software Technology, and **Gustavo Meira** from Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.26.0 is officially supported on Kubernetes versions 1.29 to 1.32. We expect 1.33 to work also, and plan to add testing and support before Istio 1.26.1.
{{< /tip >}}

## What’s new?

### Customization of resources provisioned by the Gateway API

When you create a Gateway or a waypoint using the Gateway API, a `Service` and a `Deployment` are created automatically. It has been a common request to allow customization of these objects, and that is now supported in Istio 1.26 by specifying a `ConfigMap` of parameters. If configuration for a `HorizontalPodAutoscaler` or `PodDisruptionBudget` is provided, those resources will automatically be created also. [Learn more about customizing the generated Gateway API resources.](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)

### New Gateway API support

[`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) is now available in waypoints, allowing TCP traffic shifting in ambient mode.

We also added support for the experimental [`BackendTLSPolicy`](https://gateway-api.sigs.k8s.io/api-types/backendtlspolicy/) and started the implementation of [`BackendTrafficPolicy`](https://gateway-api.sigs.k8s.io/api-types/backendtrafficpolicy/) in Gateway API 1.3, which will eventually set retry constraints.

### Support for the new Kubernetes `ClusterTrustBundle`

We've added experimental support for [the experimental `ClusterTrustBundle` resource in Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#cluster-trust-bundles), allowing support for the new method of bundling a certificate and its root of trust into a single object.

### Plus much, much more

* `istioctl analyze` can now run specific checks!
* The CNI node agent no longer runs in the `hostNetwork` namespace by default, reducing the chance of port conflicts with other services running on a host!
* Required `ResourceQuota` resources and `cniBinDir` values are set automatically when installing on GKE!
* An `EnvoyFilter` can now match a `VirtualHost` on a domain name!

Read about these and more in the full [release notes](change-notes/).

## Catch up with the Istio project

If you only check in with us when we have a new release, you might have missed that [we published a security audit on ztunnel](/blog/2025/ztunnel-security-assessment/), [we compared performance of ambient mode throughput vs. running in-kernel](/blog/2025/ambient-performance/), or that [we had a major presence at KubeCon EU](/blog/2025/istio-at-kubecon-eu/). Check those posts out!

## Upgrading to 1.26

We would like to hear from you regarding your experience upgrading to Istio 1.26. You can provide feedback in the `#release-1.26` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
