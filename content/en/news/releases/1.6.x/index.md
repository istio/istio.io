---
title: Upgrade Notes
description: Important Changes to consider when upgrading to Istio 1.6.
weight: 20
---

This page describes changes you need to be aware of when upgrading from Istio
1.5.x to Istio 1.6.x. Here, we detail cases where we intentionally broke backwards
compatibility. We also mention cases where backwards compatibility was preserved
but new behavior was introduced that would be surprising to someone familiar with
the use and operation of Istio 1.5.

# Removal of Helm Installation
In Istio 1.6, the legacy Helm installer has been removed. Please use either the
[istioctl]() installation method or the [operator]() installation method.

# Istio configuration during installation

Historically, Istio has deployed certain configuration objects as part of the installation. This has caused problems with upgrades, confusing user experience, and makes the installation less flexible. As a result, we have minimized the configurations we ship as part of the installation.

This includes a variety of different configurations:
* The `global.mtls.enabled` previously enabled strict mTLS. This should instead be done by directly configuring a PeerAuthentication policy for [strict mTLS](https://istio.io/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode)
* The default `Gateway` object, and associated `Certificate` object, are no longer installed by default. See the [Ingress task](https://istio.io/docs/tasks/traffic-management/ingress/) for information on configuring a Gateway.
* `Ingress` objects for telemetry addons are no longer created. See [Remotely Accessing Telemetry Addons](https://preliminary.istio.io/docs/tasks/observability/gateways/) for more information on exposing these externally.
* Removed the default `Sidecar` configuration. This should have no impact.
#TODO: Looking at the 1.5 docs, there were several feature gaps between telemetry v2 and mixer. Do these still exist?
