---
title: Announcing Istio 1.28.0
linktitle: 1.28.0
subtitle: Major Release
description: Istio 1.28 Release Announcement.
publishdate: 2025-11-05
release: 1.28.0
aliases:
    - /news/announcing-1.28
    - /news/announcing-1.28.0
---

We are pleased to announce the release of Istio 1.28. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.28.0 release published!
We would like to thank the Release Managers for this release, **Gustavo Meira** from Microsoft, **Francisco Herrera** from Red Hat, and **Darrin Cecil** from Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.28.0 is officially supported on Kubernetes versions 1.29 to 1.34.
{{< /tip >}}

## What’s new?

### Inference Extension Support

Istio 1.28 continues to build on the Gateway API Inference Extension support with the introduction of `InferencePool` v1. This enhancement provides better management and routing of AI inference workloads, making it easier to deploy and scale Generative AI models on Kubernetes with intelligent traffic management.

The `InferencePool` v1 API offers improved stability and functionality for managing pools of inference endpoints, enabling more sophisticated load balancing and failover strategies for AI workloads.

### Ambient Multicluster

Istio 1.28 brings significant improvements to ambient multicluster deployments. Waypoints can now route traffic to remote networks in ambient multicluster configurations, expanding ambient capabilities. This enhancement enables outlier detection and other L7 policies for requests crossing networks, making it easier to manage multi-network service mesh deployments.

Ambient multicluster remains an alpha feature and there are several known issues that will be addressed in future releases. If the recent changes negatively impacted your ambient multicluster deployment, it's possible to disable the recent waypoint behavior change by setting `AMBIENT_ENABLE_MULTI_NETWORK_WAYPOINT` pilot environment variable to `false`.

We welcome feedback and bug reports from early adopters of ambient multicluster.

### Native nftables Support in Ambient Mode

Istio 1.28 introduces support for native nftables when using ambient mode. This significant enhancement allows you to use nftables instead of iptables to manage network rules, providing a more flexible rule management. To enable nftables mode, use `--set values.global.nativeNftables=true` when installing Istio.

This addition complements the existing nftables support in sidecar mode, ensuring Istio stays current with modern Linux networking frameworks.

### Dual-stack Support Promoted to Beta

Istio's dual-stack networking support has been promoted to beta in this release. This advancement provides robust IPv4/IPv6 networking capabilities, enabling organizations to deploy Istio in modern network environments that require both IP protocol versions.

### Enhanced Security Features

This release includes several important security improvements:

- **Enhanced JWT Authentication**: Improved JWT filter configuration now supports custom space-delimited claims in addition to default claims like "scope" and "permission". This enhancement ensures proper validation of JWT tokens with custom claims using the `spaceDelimitedClaims` field in `RequestAuthentication` resources
- **`NetworkPolicy` Support**: Optional `NetworkPolicy` deployment for istiod with `global.networkPolicy.enabled=true`
- **Enhanced Container Security**: Support for configuring `seccompProfile` in istio-validation and istio-proxy containers for better security compliance
- **Gateway API Security**: Support for `FrontendTLSValidation` (GEP-91) enabling mutual TLS ingress gateway configurations
- **Improved Certificate Handling**: Better root certificate parsing that filters out malformed certificates instead of rejecting the entire bundle

### Gateway API and Traffic Management Enhancements

- **`BackendTLSPolicy` v1**: Full Gateway API v1.4 support with enhanced TLS configuration options
- **`ServiceEntry` Integration**: Support for `ServiceEntry` as a `targetRef` in `BackendTLSPolicy` for external service TLS configuration
- **Wildcard Host Support**: `ServiceEntry` resources now support wildcard hosts with `DYNAMIC_DNS` resolution (HTTP traffic only, requires ambient mode and waypoint)

### Plus Much More

- **Persona-based Installations**: New `resourceScope` option in Helm charts for namespace or cluster-scoped resource management
- **Improved Load Balancing**: Cookie attributes support in consistent hash load-balancing with security options like `SameSite`, `Secure`, and `HttpOnly`
- **Enhanced Telemetry**: Dual B3/W3C header propagation support for better tracing interoperability
- **istioctl Improvements**: Automatic default revision detection and enhanced debugging capabilities

Read about these and more in the full [release notes](change-notes/).

## Upgrading to 1.28

We would like to hear from you regarding your experience upgrading to Istio 1.28. You can provide feedback in the `#release-1.28` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
