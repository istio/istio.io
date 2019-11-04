---
title: Change Notes
description: Istio 1.4 release notes.
weight: 10
---

## Traffic management

- **Added** support for fractional [request mirroring](/docs/tasks/traffic-management/mirroring/).
- **Improved** the Envoy sidecar. The Envoy sidecar now exits when it crashes. This change makes it easier to see whether or not the Envoy sidecar is healthy.
- **Improved** Pilot to skip sending redundant configuration to Envoy when no changes are required.

## Security

- **Added** support for Citadel to periodically check and rotate expiry root certificate when Citadel is running in self-sign CA mode.

## Telemetry

- **Added** support for configuring [stat patterns](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) for Envoy stats.
- **Added** prefix to Envoy HTTP stats to specify traffic direction (`inbound` or `outbound`).

## Configuration management

- **Added** many additional validation checks to [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/).
- **Added** experimental support for validation message in Istio [resource statuses](/docs/ops/diagnostic-tools/istioctl-analyze/#enabling-validation-messages-for-resource-status).
- **Added** OpenAPI v3 schema validation to CRDs. Please see the [Upgrade Notes](/news/2019/announcing-1.4/upgrade-notes) for details.

## Installation

- **Remove** the `proxy_init` docker image. Instead, the `istio-init` container will reuse the `proxyv2` image
- **Update** the base image to `ubunutu:bionic`.

## `istioctl`

- **Added** [`istioctl experimental wait`](/docs/reference/commands/istioctl/#istioctl-experimental-wait) to wait until an Istio configuration has been pushed to all Envoy sidecars.
- **Added** [`istioctl experimental mulitcluster`](/docs/reference/commands/istioctl/#istioctl-experimental-multicluster) to help manage Istio across multiple clusters.
- **Added** [`istioctl experimental post-install webhook`](/docs/reference/commands/istioctl/#istioctl-experimental-post-install-webhook) to manage webhook configuration.
- **Improved** [`istioctl version`](/docs/reference/commands/istioctl/#istioctl-version) to show Envoy proxy versions.

## Miscellaneous

- **Replaced** daily builds of Istio with builds for [each commit](https://github.com/istio/istio/wiki/Dev%20Builds).
