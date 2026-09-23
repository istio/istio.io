---
title: Istio 1.27 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.27.0.
weight: 20
---

When upgrading from Istio 1.26.x to Istio 1.27.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.26.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.27.x.

## Multiple certificate types support in Gateway

Istio now supports configuring multiple certificate types (such as RSA and ECDSA) simultaneously in in both Istio and Kubernetes Gateway resources.
This allows clients to choose the most appropriate certificate type based on their capabilities.

## Regenerate Grafana dashboards after upgrade

If you use Istio's bundled Grafana dashboards, you'll need to regenerate them after upgrading to
get the fixed dashboard linking. Dashboard UIDs are now explicitly defined to enable stable links
between dashboards.

## Deprecation of telemetry providers

The telemetry providers Lightstep and OpenCensus are now removed. Please use the OpenTelemetry provider instead.

## Native sidecar enabled by default

Native sidecars are now enabled by default for eligible pods. This changes `istio-proxy` from a container to an init container.
This can cause compatibility issues with other mutating webhooks or controllers in your cluster that expect to modify the `istio-proxy` as a regular container.
Please test your workloads and controllers to ensure they are compatible with this change.
