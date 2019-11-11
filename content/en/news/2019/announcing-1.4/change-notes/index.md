---
title: Change Notes
description: Istio 1.4 release notes.
weight: 10
---

## Traffic management

- **Added** support for [mirroring](/docs/tasks/traffic-management/mirroring/) a percentage of traffic.
- **Improved** the Envoy sidecar. The Envoy sidecar now exits when it crashes. This change makes it easier to see whether or not the Envoy sidecar is healthy.
- **Improved** Pilot to skip sending redundant configuration to Envoy when no changes are required.
- **Improved** headless services to avoid conflicts with different services on the same port.
- **Disabled** default [circuit breakers](/docs/tasks/traffic-management/circuit-breaking/).
- **Updated** the default regex engine to `re2`. Please see the [Upgrade Notes](/news/2019/announcing-1.4/upgrade-notes) for details.

## Security

- **Improved** Citadel to periodically check and rotate the expired root certificate when running in self-sign CA mode.

## Telemetry

- **Added** the option to configure [stat patterns](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) for Envoy stats.
- **Added** the `inbound` and `outbound` prefixes to the Envoy HTTP stats to specify traffic direction.

## Configuration management

- **Added** multiple validation checks to the [`istioctl analyze`](/docs/ops/diagnostic-tools/istioctl-analyze/) sub-command.
- **Added** the experimental option to enable validation messages for Istio [resource statuses](/docs/ops/diagnostic-tools/istioctl-analyze/#enabling-validation-messages-for-resource-status).
- **Added** OpenAPI v3 schema validation of Custom Resource Definitions (CRDs). Please see the [Upgrade Notes](/news/2019/announcing-1.4/upgrade-notes) for details.
- **Added** [client-go](https://github.com/istio/client-go) libraries to access Istio APIs.

## Installation

- **Added** Added the [operator controller](/docs/setup/install/standalone-operator/) for dynamic updates to an Istio installation.
- **Removed** the `proxy_init` Docker image. Instead, the `istio-init` container reuses the `proxyv2` image.
- **Updated** the base image to `ubunutu:bionic`.

## `istioctl`

- **Added** the experimental [`istioctl experimental wait`](/docs/reference/commands/istioctl/#istioctl-experimental-wait) sub-command to have Istio wait until it has pushed a configuration to all Envoy sidecars.
- **Added** the experimental [`istioctl experimental mulitcluster`](/docs/reference/commands/istioctl/#istioctl-experimental-multicluster) sub-command to help manage Istio across multiple clusters.
- **Added** the experimental [`istioctl experimental post-install webhook`](/docs/reference/commands/istioctl/#istioctl-experimental-post-install-webhook) sub-command to manage webhook configuration.
- **Added** the experimental [`istioctl experimental upgrade`](/docs/setup/upgrade/istioctl-upgrade/) sub-command to perform upgrades of Istio.
- **Improved** the [`istioctl version`](/docs/reference/commands/istioctl/#istioctl-version) sub-command. It now shows the Envoy proxy versions.
