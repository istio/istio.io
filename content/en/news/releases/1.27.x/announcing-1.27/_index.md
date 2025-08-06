---
title: Announcing Istio 1.27.0
linktitle: 1.27.0
subtitle: Major Release
description: Istio 1.27 Release Announcement.
publishdate: 2025-08-08
release: 1.27.0
aliases:
    - /news/announcing-1.27
    - /news/announcing-1.27.0
---

We are pleased to announce the release of Istio 1.27. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.27.0 release published!
We would like to thank the Release Managers for this release, **Jianpeng He** from Tetrate.io, **Faseela K** from Ericsson Software Technology, and **Gustavo Meira** from Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.27.0 is officially supported on Kubernetes versions 1.29 to 1.33.
{{< /tip >}}

## What’s new?

### Inference Extension Support

[Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/) is an official Kubernetes project that optimizes self-hosting Generative Models on Kubernetes.
Istio provides a fully compliant [implementation](https://gateway-api-inference-extension.sigs.k8s.io/implementations/gateways/#istio) of the Kubernetes Gateway API for cluster ingress traffic control.

### Ambient Multicluster

TODO

### Lightstep Support Removal

In 2022, Istio deprecated its built-in Lightstep integration as part of a broader move toward OpenTelemetry (OTel) and the OTLP protocol. By 1.27, Istio completely removed Lightstep support, making OTel/OTLP the standard for tracing.

### CRL Support for Plugged-in CAs?

Certificate Revocation Lists (CRLs) is now available for plugged-in CA, allowing operators to revoke trust in root or intermediate certificates.

### ListenerSets Support

[ListenerSets](https://gateway-api.sigs.k8s.io/geps/gep-1713) is now available, allowing a shared list of listeners to be attached to a single `Gateway`.

###

## Upgrading to 1.27

We would like to hear from you regarding your experience upgrading to Istio 1.27. You can provide feedback in the `#release-1.27` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
