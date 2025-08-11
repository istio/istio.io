---
title: Announcing Istio 1.27.0
linktitle: 1.27.0
subtitle: Major Release
description: Istio 1.27 Release Announcement.
publishdate: 2025-08-11
release: 1.27.0
aliases:
    - /news/announcing-1.27
    - /news/announcing-1.27.0
---

We are pleased to announce the release of Istio 1.27. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.27.0 release published!
We would like to thank the Release Managers for this release, **Jianpeng He** from Tetrate, **Faseela K** from Ericsson Software Technology, and **Gustavo Meira** from Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.27.0 is officially supported on Kubernetes versions 1.29 to 1.33.
{{< /tip >}}

## What’s new?

### Inference Extension Support

[Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/) is an official Kubernetes project designed to optimize the self-hosting of Generative AI models on Kubernetes. It provides a standardized, vendor-neutral approach to intelligent AI traffic management.

Istio 1.27 includes a [fully-compliant implementation](https://gateway-api-inference-extension.sigs.k8s.io/implementations/gateways/#istio) of the extension when using the Gateway API for cluster ingress traffic control.

[Learn more about the extension and Istio's implementation](/blog/2025/inference-extension-support/).

### Ambient Multicluster

Support for multi-cluster deployments in ambient mode is now available in Alpha. This enables multiple ambient mode clusters to be connected into the same mesh, expanding the scope of no-sidecar networking to larger and more distributed environments.

In this initial release, testing has been focused on multi-network, multi-primary topologies, where each cluster runs its own control plane. Support for more complex topologies will follow as the baseline feature matures.

### CRL Support for Plugged-in CAs

Certificate Revocation List (CRL) support is now available for users who have "plugged in" their own certificate authority, rather than using the default provided by Istio.  This allows proxies to validate and reject revoked certificates, strengthening the security posture of mesh deployments using plugged-in CAs.

### ListenerSets Support

The new [ListenerSets](https://gateway-api.sigs.k8s.io/geps/gep-1713) API allows you to define a reusable set of listeners that can be attached to a `Gateway` resource. This promotes consistency and reduces duplication when managing multiple Gateways that share common listener configurations.

### Native nftables Support in Sidecar Mode

Istio now supports the [native nftables](https://github.com/istio/istio/issues/47821) backend in Sidecar mode. nftables is the modern successor to iptables, providing better performance, improved maintainability, and more flexible rule management for transparent traffic redirection to and from the Envoy sidecar proxy.

Many major Linux distributions are adopting nftables as the default packet filtering framework, and Istio’s native support ensures compatibility with this shift.

Support for nftables in ambient mode is actively being developed and will arrive in a future release.

## Upgrading to 1.27

We would like to hear from you regarding your experience upgrading to Istio 1.27. You can provide feedback in the `#release-1.27` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
