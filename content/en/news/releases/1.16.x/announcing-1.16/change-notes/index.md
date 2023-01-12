---
title: Istio 1.16.0 Change Notes
linktitle: 1.16.0
subtitle: Minor Release
description: Istio 1.16.0 change notes.
publishdate: 2022-11-15
release: 1.16.0
weight: 10
---

## Deprecation Notices

These notices describe functionality that will be removed in a future release according to [Istio's deprecation policy](/docs/releases/feature-stages/#feature-phase-definitions). Please consider upgrading your environment to remove the deprecated functionality.

- **Deprecated** fetching charts from URLs in `istio-operator`.

## Traffic Management

- **Improved** sidecar `Host` header matching to ignore port numbers by default. This can be controlled by the `SIDECAR_IGNORE_PORT_IN_HOST_MATCH` environment variable. ([Issue #36627](https://github.com/istio/istio/issues/36627))

- **Updated** `meshConfig.discoverySelectors` to dynamically restrict the set of namespaces where istiod creates the `istio-ca-root-cert` configmap
  if the `ENABLE_ENHANCED_RESOURCE_SCOPING` feature flag is enabled.

- **Updated** `meshConfig.discoverySelectors` to dynamically restrict the set of namespaces where istiod discovers Custom Resource configurations
  (like Gateway, VirtualService, DestinationRule, Ingress, etc.) if the `ENABLE_ENHANCED_RESOURCE_SCOPING` feature flag is enabled.
  ([Issue #36627](https://github.com/istio/istio/issues/36627))

- **Updated** the gateway-api integration to read `v1beta1` resources for `HTTPRoute`, `Gateway`, and `GatewayClass`. Users of the gateway-api must
  be on version 0.5.0+ before upgrading Istio.

- **Added** support for MAGLEV load balancing algorithm for consistent hashing.

- **Added** the creation of inbound listeners for service ports and sidecar
  and ingress listener both using environment variable
  `PILOT_ALLOW_SIDECAR_SERVICE_INBOUND_LISTENER_MERGE`.
  Using this, the traffic for a service port is not sent via passthrough TCP even
  though it is regular HTTP traffic when sidecar ingress listener is defined.
  In case the same port number is defined in both sidecar ingress and service,
  sidecar always takes precedence.
  ([Issue #40919](https://github.com/istio/istio/issues/40919))

- **Fixed** `LocalityLoadBalancerSetting.failoverPriority` not working properly if xDS cache is enabled.
  ([Issue #40198](https://github.com/istio/istio/issues/40198))

- **Fixed** some memory/CPU cost issues by temporarily disabling `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING`.

- **Fixed** an issue where Remote JWKS URI's without a host port fail to parse into their host and port components.

- **Fixed** the ordering of RBAC and metadata exchange filters while generating HTTP/network filters.
  ([Issue #41066](https://github.com/istio/istio/issues/41066))

- **Fixed** an issue causing traffic to not match (and return a `404`) when using wildcard domain names and including an unexpected port in the `Host` header.

- **Fixed** an issue causing traffic to match an unexpected route when using wildcard domain names and including an port in the `Host` header.

## Security

- **Improved** Pilot will now load its DNS serving certificate from well known locations:

    {{< text plain >}}
    /var/run/secrets/istiod/tls/tls.crt
    /var/run/secrets/istiod/tls/tls.key
    /var/run/secrets/istiod/ca/root-cert.pem
    {{< /text >}}

    The CA path will alternatively be loaded from `/var/run/secrets/tls/ca.crt`.
    It also automatically loads any secret called `istiod-tls` and the `istio-root-ca-configmap` into those paths.
    This method is preferred to use these well known paths than to set the TLS arguments.
    This will allow for an easier installation process for `istio-csr` as well as any other external issuer that needs to modify
    the Pilot DNS serving certificate. ([Issue #36916](https://github.com/istio/istio/issues/36916))

- **Updated** dependency in Envoy to properly parse JWTs with negative values for `exp`, `nbf`, or `iat` fields.

## Telemetry

- **Updated** Telemetry API to use a new native extension for Prometheus stats
  instead of the Wasm-based extension. This improves CPU overhead and memory
  usage of the feature. Custom dimensions no longer require regex and bootstrap
  annotations. If customizations use CEL expressions with Wasm attributes, they
  are likely to be affected. This change can be enabled by setting the control
  plane feature flag `TELEMETRY_USE_NATIVE_STATS` to `true`.

- **Added** support for use of the OpenTelemetry tracing provider with the Telemetry API.
  ([Issue #40027](https://github.com/istio/istio/issues/40027))

- **Fixed** an issue to allow multiple regular expressions with the same tag name.
  ([Issue #39903](https://github.com/istio/istio/issues/39903))

## Extensibility

- **Improved** when Wasm module downloading fails and `fail_open` is true, a RBAC filter allowing all the traffic is passed to Envoy instead of the original Wasm filter.
  Previously, the given Wasm filter itself was passed to Envoy in this case, but it may cause errors because some fields of Wasm configuration are optional in Istio, but not in Envoy.

- **Improved** WasmPlugin images (docker and OCI standard image) to support more than one layer as per specification changes.
  See ([https://github.com/solo-io/wasm/pull/293](https://github.com/solo-io/wasm/pull/293)) for more details.

- **Added** the `match` field in the WasmPlugin API. With this `match` clause, a WasmPlugin can be applied to more specific traffic (e.g., traffic to a specific port).
  ([Issue #39345](https://github.com/istio/istio/issues/39345))

## Installation

- **Added** `seccompProfile` fields to set the `seccompProfile` field in container
  `securityContext`s as per [https://kubernetes.io/docs/tutorials/security/seccomp/](https://kubernetes.io/docs/tutorials/security/seccomp/).
  ([Issue #39791](https://github.com/istio/istio/issues/39791))

- **Added** a new Istio Operator `remote` profile and deprecated the equivalent `external` profile. ([Issue #39797](https://github.com/istio/istio/issues/39797))

- **Added** a `--cluster-specific` flag to `istioctl manifest generate`. When this is set, the current cluster context will be used to determine dynamic default settings, mirroring `istioctl install`.

- **Added** auto-detection of [GKE specific installation steps](/docs/setup/additional-setup/cni/#hosted-kubernetes-settings) when using CNI to `istioctl install` and `helm install`.

- **Added** an `ENABLE_LEADER_ELECTION=false` feature flag for pilot-discovery to disable leader election when using a single replica of istiod.
  ([Reference](/docs/reference/commands/pilot-discovery/)) ([Issue #40427](https://github.com/istio/istio/issues/40427))

- **Added** support for configuring `MaxConcurrentReconciles` in istio-operator. ([Issue #40827](https://github.com/istio/istio/issues/40827))

- **Fixed** an issue when `auto.sidecar-injector.istio.io` `namespaceSelector` caused problems with cluster maintenance. ([Issue #40984](https://github.com/istio/istio/issues/40984))

- **Fixed** an issue when deleting a custom gateway using an Istio Operator custom resource, other gateways are restarted. ([Issue #40577](https://github.com/istio/istio/issues/40577))

- **Fixed** an issue in Istio Operator where CNI is not created properly when `cni.resourceQuotas` is enabled due to missing RBAC permissions. ([Issue #41159](https://github.com/istio/istio/issues/41159))

## istioctl

- **Added** the `--skip-confirmation` flag to `istioctl operator remove` to add a confirmation mechanism for operator removal. ([Issue #41244](https://github.com/istio/istio/issues/41244))

- **Added** precheck for revision when running `istioctl uninstall`. ([Issue #40598](https://github.com/istio/istio/issues/40598))

- **Added** `--rps-limit` flag to `istioctl bug-report` that allows increasing
  the requests per second limit to the Kubernetes API server which can greatly
  reduce the time to collect bug reports.

- **Added** `istioctl experimental check-inject` feature to describe why injection will/won't or did/didn't occur to the pod based on current running webhooks.
  ([Issue #38299](https://github.com/istio/istio/issues/38299))

- **Fixed** setting `exportTo` field and `networking.istio.io/exportTo` annotation leading to an incorrect IST0101 message.
  ([Issue #39629](https://github.com/istio/istio/issues/39629))

- **Fixed** setting `networking.istio.io/exportTo` annotation to services with multiple values lead to an incorrect IST0101 message.
  ([Issue #39629](https://github.com/istio/istio/issues/39629))

- **Fixed** `experimental un-inject` providing incorrect templates for "un-injecting".

## Documentation changes

- **Added** `build_push_update_images.sh` now supports the `--multiarch-images` argument to build multi-arch container images used in the bookinfo application.
  ([Issue #40405](https://github.com/istio/istio/issues/40405))
