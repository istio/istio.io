---
title: Change Notes
description: Istio 1.2 release notes.
weight: 10
aliases:
    - /zh/about/notes/1.2
---

## General

- **Added** `traffic.sidecar.istio.io/includeInboundPorts` annotation to eliminate the need for service owner to declare `containerPort` in the deployment yaml file.  This will become the default in a future release.
- **Added** IPv6 experimental support for Kubernetes clusters.

## Traffic management

- **Improved** [locality based routing](/zh/docs/ops/traffic-management/locality-load-balancing/) in multicluster environments.
- **Improved** outbound traffic policy in [`ALLOW_ANY` mode](/zh/docs/reference/config/installation-options/#global-options). Traffic for unknown HTTP/HTTPS hosts on an existing port will be [forwarded as is](/zh/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services). Unknown traffic will be logged in Envoy access logs.
- **Added** support for setting HTTP idle timeouts to upstream services.
- **Improved** Sidecar support for [NONE mode](/zh/docs/reference/config/networking/sidecar/#CaptureMode) (without iptables) .
- **Added** ability to configure the [DNS refresh rate](/zh/docs/reference/config/installation-options/#global-options) for sidecar Envoys, to reduce the load on the DNS servers.
- **Graduated** [Sidecar API](/zh/docs/reference/config/networking/sidecar/) from Alpha to Alpha API and Beta runtime.

## Security

- **Improved** extend the default lifetime of self-signed Citadel root certificates to 10 years.
- **Added** Kubernetes health check prober rewrite per deployment via `sidecar.istio.io/rewriteAppHTTPProbers: "true"` in the `PodSpec` [annotation](/zh/docs/ops/setup/app-health-check/#use-annotations-on-pod).
- **Added** support for configuring the secret paths for Istio mutual TLS certificates. Refer [here](https://github.com/istio/istio/issues/11984) for more details.
- **Added** support for [PKCS 8](https://en.wikipedia.org/wiki/PKCS_8) private keys for workloads, enabled by the flag `pkcs8-keys` on Citadel.
- **Improved** JWT public key fetching logic to be more resilient to network failure.
- **Fixed** [SAN](https://tools.ietf.org/html/rfc5280#section-4.2.1.6) field in workload certificates is set as `critical`. This fixes the issue that some custom certificate verifiers cannot verify Istio certificates.
- **Fixed** mutual TLS probe rewrite for HTTPS probes.
- **Graduated** [SNI with multiple certificates support at ingress gateway](/zh/docs/reference/config/networking/gateway/) from Alpha to Stable.
- **Graduated** [certification management on Ingress Gateway](/zh/docs/tasks/traffic-management/ingress/secure-ingress-sds/) from Alpha to Beta.

## Telemetry

- **Added** Full support for control over Envoy stats generation, based on stats prefixes, suffixes, and regular expressions through the use of annotations.
- **Changed** Prometheus generated traffic is excluded from metrics.
- **Added** support for sending traces to Datadog.
- **Graduated** [distributed tracing](/zh/docs/tasks/observability/distributed-tracing/) from Beta to Stable.

## Policy

- **Fixed** [Mixer based](https://github.com/istio/istio/issues/13868)TCP Policy enforcement.
- **Graduated** [Authorization (RBAC)](/zh/docs/reference/config/security/istio.rbac.v1alpha1/) from Alpha to Alpha API and Beta runtime.

## Configuration management

- **Improved** validation of Policy & Telemetry CRDs.
- **Graduated** basic configuration resource validation from Alpha to Beta.

## Installation and upgrade

- **Updated** default proxy memory limit size(`global.proxy.resources.limits.memory`) from `128Mi` to `1024Mi` to ensure proxy has sufficient memory.
- **Added** pod [anti-affinity](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity) and [toleration](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/) support to all of our control plane components.
- **Added** `sidecarInjectorWebhook.neverInjectSelector` and `sidecarInjectorWebhook.alwaysInjectSelector` to allow users to further refine whether workloads should have sidecar automatically injected or not, based on label selectors.
- **Added** `global.logging.level` and `global.proxy.logLevel` to allow users to easily configure logs for control plane and data plane components globally.
- **Added** support to configure the Datadog location via [`global.tracer.datadog.address`](/zh/docs/reference/config/installation-options/#global-options).
- **Removed** Previously [deprecated]( https://discuss.istio.io/t/deprecation-notice-custom-mixer-adapter-crds/2055) Adapter and Template CRDs are disabled by default. Use  `mixer.templates.useTemplateCRDs=true` and `mixer.adapters.useAdapterCRDs=true` install options to re-enable them.

Refer to the [installation option change page](/zh/news/releases/1.2.x/announcing-1.2/helm-changes/) to view the complete list of changes.

## `istioctl` and `kubectl`

- **Graduated** `istioctl verify-install` out of experimental.
- **Improved** `istioctl verify-install` to validate if a given Kubernetes environment meets Istio's prerequisites.
- **Added** auto-completion support to `istioctl`.
- **Added** `istioctl experimental dashboard` to allow users to easily open the web UI of any Istio addons.
- **Added** `istioctl x` alias to conveniently run `istioctl experimental` command.
- **Improved** `istioctl version` to report both Istio control plane and `istioctl` version info by default.
- **Improved** `istioctl validate` to validate Mixer configuration and supports deep validation with referential integrity.

## Miscellaneous

- **Added** [Istio CNI support](/zh/docs/setup/additional-setup/cni/) to setup sidecar network redirection and remove the use of `istio-init` containers requiring `NET_ADMIN` capability.
- **Added** a new experimental ['a-la-carte' Istio installer](https://github.com/istio/installer/wiki) to enable users to install and upgrade Istio with desired isolation and security.
- **Added** [environment variable and configuration file support](https://docs.google.com/document/d/1M-qqBMNbhbAxl3S_8qQfaeOLAiRqSBpSgfWebFBRuu8/edit) for configuring Galley, in addition to command-line flags.
- **Added** [ControlZ](/zh/docs/ops/diagnostic-tools/controlz/) support to visualize the state of the MCP Server in Galley.
- **Added** the [`enableServiceDiscovery` command-line flag](/zh/docs/reference/commands/galley/#galley-server) to control the service discovery module in Galley.
- **Added** `InitialWindowSize` and `InitialConnWindowSize` parameters to Galley and Pilot to allow fine-tuning of MCP (gRPC) connection settings.
- **Graduated** configuration processing with Galley from Alpha to Beta.
