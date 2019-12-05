---
title: Change Notes
description: Istio 1.4 release notes.
weight: 10
---

## Traffic management

- **Added** support for [mirroring](/zh/docs/tasks/traffic-management/mirroring/) a percentage of traffic.
- **Improved** the Envoy sidecar. The Envoy sidecar now exits when it crashes. This change makes it easier to see whether or not the Envoy sidecar is healthy.
- **Improved** Pilot to skip sending redundant configuration to Envoy when no changes are required.
- **Improved** headless services to avoid conflicts with different services on the same port.
- **Disabled** default [circuit breakers](/zh/docs/tasks/traffic-management/circuit-breaking/).
- **Updated** the default regex engine to `re2`. Please see the [Upgrade Notes](/zh/news/releases/1.4.x/announcing-1.4/upgrade-notes) for details.

## Security

- **Added** the [`v1beta1` authorization policy model](/zh/blog/2019/v1beta1-authorization-policy/) for enforcing access control. This will eventually replace the [`v1alpha1` RBAC policy](/zh/docs/reference/config/security/istio.rbac.v1alpha1/).
- **Added** experimental support for [automatic mutual TLS](/zh/docs/tasks/security/authentication/auto-mtls/) to enable mutual TLS without destination rule configuration.
- **Added** experimental support for [authorization policy trust domain migration](/zh/docs/tasks/security/authorization/authz-td-migration/).
- **Added** experimental [DNS certificate management](/zh/blog/2019/dns-cert/) to securely provision and manage DNS certificates signed by the Kubernetes CA.
- **Improved** Citadel to periodically check and rotate the expired root certificate when running in self-sign CA mode.

## Telemetry

- **Added** experimental in-proxy telemetry reporting to [Stackdriver](https://github.com/istio/proxy/blob/{{< source_branch_name >}}/extensions/stackdriver/README.md).
- **Improved** support for [in-proxy](/zh/docs/ops/telemetry/in-proxy-service-telemetry/) Prometheus generation of HTTP service metrics (from experimental to alpha).
- **Improved** telemetry collection for [blocked and passthrough external service traffic](/zh/blog/2019/monitoring-external-service-traffic/).
- **Added** the option to configure [stat patterns](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) for Envoy stats.
- **Added** the `inbound` and `outbound` prefixes to the Envoy HTTP stats to specify traffic direction.
- **Improved** reporting of telemetry for traffic that goes through an egress gateway.

## Configuration management

- **Added** multiple validation checks to the [`istioctl analyze`](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) sub-command.
- **Added** the experimental option to enable validation messages for Istio [resource statuses](/zh/docs/ops/diagnostic-tools/istioctl-analyze/#enabling-validation-messages-for-resource-status).
- **Added** OpenAPI v3 schema validation of Custom Resource Definitions (CRDs). Please see the [Upgrade Notes](/zh/news/releases/1.4.x/announcing-1.4/upgrade-notes) for details.
- **Added** [client-go](https://github.com/istio/client-go) libraries to access Istio APIs.

## Installation

- **Added** the experimental [operator controller](/zh/docs/setup/install/standalone-operator/) for dynamic updates to an Istio installation.
- **Removed** the `proxy_init` Docker image. Instead, the `istio-init` container reuses the `proxyv2` image.
- **Updated** the base image to `ubunutu:bionic`.

## `istioctl`

- **Added** the [`istioctl proxy-config logs`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config-log) sub-command retrieve and update Envoy logging levels.
- **Updated** the [`istioctl authn tls-check`](/zh/docs/reference/commands/istioctl/#istioctl-authn-tls-check) sub-command to display which policy is in use.
- **Added** the experimental [`istioctl experimental wait`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-wait) sub-command to have Istio wait until it has pushed a configuration to all Envoy sidecars.
- **Added** the experimental [`istioctl experimental mulitcluster`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-multicluster) sub-command to help manage Istio across multiple clusters.
- **Added** the experimental [`istioctl experimental post-install webhook`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-post-install-webhook) sub-command to [securely manage webhook configurations](/zh/blog/2019/webhook/).
- **Added** the experimental [`istioctl experimental upgrade`](/zh/docs/setup/upgrade/istioctl-upgrade/) sub-command to perform upgrades of Istio.
- **Improved** the [`istioctl version`](/zh/docs/reference/commands/istioctl/#istioctl-version) sub-command. It now shows the Envoy proxy versions.
