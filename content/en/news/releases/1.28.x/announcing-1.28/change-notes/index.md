---
title: Change Notes
linktitle: 1.28.0
subtitle: Minor Release
description: Istio 1.28.0 release notes.
publishdate: 2025-11-05
release: 1.28.0
weight: 10
aliases:
    - /news/announcing-1.28.0
---

## Traffic Management

- **Promoted** Istio dual-stack support to beta.
  ([Issue #54127](https://github.com/istio/istio/issues/54127))

- **Updated** the default value for maximum accepted connections per socket event. The
  default value now is 1 for inbound and outbound listeners explicitly binding to ports
  in sidecars. Listeners with no iptables interception will benefit from better performance
  under high connection churn scenarios. To get the old behavior, you can set `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP`
  to zero.

- **Added** support for cookie attributes in consistent hash load-balancing. You can now specify additional attributes, such as `SameSite`, `Secure` and `HttpOnly`. This allows for more secure and compliant cookie handling in load-balancing scenarios.
  ([Issue #56468](https://github.com/istio/istio/issues/56468)), ([Issue #49870](https://github.com/istio/istio/issues/49870))

- **Added** `DISABLE_SHADOW_HOST_SUFFIX` environment variable to control shadow host suffix behavior in mirroring policies. When set to `true` (default), shadow host suffixes are added to hostnames of mirrored requests. When set to `false`, shadow host suffixes are not added. This provides backward compatibility for users upgrading from older Istio versions where shadow host suffixes were added by default via compatibility profiles.
  ([Issue #57530](https://github.com/istio/istio/issues/57530))

- **Added** support for `sectionName` in Gateway API `BackendTLSPolicy` to enable port-specific TLS configuration. This allows targeting specific ports of a Service by name, enabling different TLS settings per port. For example, you can now configure TLS settings for only the `https` port of a `Service` while leaving other ports unaffected.

- **Added** support for `ServiceEntry` as a `targetRef` in `BackendTLSPolicy`. This allows users to apply TLS settings to external services defined by `ServiceEntry` resources.
  ([Issue #57521](https://github.com/istio/istio/issues/57521))

- **Added** support for native nftables when using Istio ambient mode. This update makes it possible to use nftables
  instead of iptables to manage network rules. To enable the nftables mode, use `--set values.global.nativeNftables=true` when installing Istio.  ([Issue #57324](https://github.com/istio/istio/issues/57324))

- **Added** support for wildcard hosts in `ServiceEntry` resources with `DYNAMIC_DNS` resolution.
  This is only supported for HTTP traffic for now. It requires ambient mode and a waypoint configured as
  an egress gateway.  ([Issue #54540](https://github.com/istio/istio/issues/54540))

- **Added** support for `X-Forwarded` headers in `ProxyConfig.ProxyHeaders`.

- **Enabled** waypoints to route traffic to remote networks in ambient multi-cluster.
  ([Issue #57537](https://github.com/istio/istio/issues/57537))

- **Fixed** a bug where ztunnel wouldn't correctly use the `WorkloadEntry` port map when referencing a `Service` port name.
  ([Issue #56251](https://github.com/istio/istio/issues/56251))

- **Fixed** an issue where the tag watcher didn't consider the default revision to be the same as the default tag. This would cause issues where Kubernetes gateways wouldn't be programmed.
  ([Issue #56767](https://github.com/istio/istio/issues/56767))

- **Fixed** a bug where a shadow `Service` port number for an `InferencePool` would start with 543210 instead of 54321. ([Issue #57472](https://github.com/istio/istio/issues/57472))

- **Fixed** an issue where the ambient dataplane did not correctly handle `ServiceEntries` with resolution set to `NONE`. Previously, the configuration would have a VIP but no endpoints, which would result in a "no healthy upstream" error. This scenario is now configured as a `PASSTHROUGH` service, meaning the addresses called by the client will be used as the backend.
  ([Issue #57656](https://github.com/istio/istio/issues/57656))

- **Fixed** an issue where HTTP/2 connection pool settings were not applied when enabling HTTP/2 upgrades. ([Issue #57583](https://github.com/istio/istio/issues/57583))

- **Fixed** waypoint deployments to use the default Kubernetes `terminationGracePeriodSeconds` (30 seconds) instead of a hard-coded 2 seconds value.

- **Added** support for `InferencePool` v1.
  ([Issue #57219](https://github.com/istio/istio/issues/57219))

- **Removed** support for `InferencePool` alpha and release candidate versions.

## Security

- **Improved** root certificate parsing when some certificates were invalid. Istio now filters out malformed certificates instead of rejecting the entire bundle.

- **Added** `caCertCredentialName` field in `ServerTLSSettings` to reference a `Secret`/`ConfigMap` that holds CA certificates for mTLS.
  See [usage](/docs/tasks/traffic-management/ingress/secure-ingress/#key-formats) or [reference](/docs/reference/config/networking/gateway/#ServerTLSSettings-ca_cert_credential_name) for more information.
  ([Issue #43966](https://github.com/istio/istio/issues/43966))

- **Added** optional `NetworkPolicy` deployment for istiod. You can set `global.networkPolicy.enabled=true` to deploy a default `NetworkPolicy` for istiod and gateways. We're planning to extend this to later also include `NetworkPolicy` for istio-cni and ztunnel.
  ([Issue #56877](https://github.com/istio/api/issues/56877))

- **Added** support for configuring `seccompProfile` in the `istio-validation` and `istio-proxy` containers within the sidecar injection template. Users can now set the `seccompProfile.type` to `RuntimeDefault` for enhanced security compliance.
  ([Issue #57004](https://github.com/istio/istio/issues/57004))

- **Added** support for `FrontendTLSValidation` (GEP-91) in Gateway API.
  See [usage](/docs/tasks/traffic-management/ingress/secure-ingress/#configure-a-mutual-tls-ingress-gateway) and [reference](https://gateway-api.sigs.k8s.io/reference/spec/#frontendtlsvalidation) for more information.
  ([Issue #43966](https://github.com/istio/istio/issues/43966))

- **Fixed** JWT filter configuration to support custom space-delimited claims. The JWT filter configuration now correctly includes user-specified custom space-delimited claims in addition to the default claims ("scope" and "permission"). This ensures that the Envoy JWT filter treats these claims as space-delimited strings, allowing for proper validation of JWT tokens that include these claims. To set custom space-delimited claims, use the `spaceDelimitedClaims` field in the JWT rule configuration inside the `RequestAuthentication` resource.
  ([Issue #56873](https://github.com/istio/istio/issues/56873))

- **Removed** use of MD5 to optimize comparisons. Istio does not and has not used MD5 for cryptographic purposes. The change is merely to make the code easier to audit and to run in [FIPS 140-3 mode](https://go.dev/doc/security/fips140).

## Telemetry

- **Updated** environment variable `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` default value to `true`, enabling the spawning of upstream spans for gateway requests by default.

- **Added** support for annotations `sidecar.istio.io/statsFlushInterval` and `sidecar.istio.io/statsEvictionInterval`.

- **Added** support for Zipkin's `TraceContextOption` configuration to enable dual B3/W3C header propagation.
  Configure with `trace_context_option: USE_B3_WITH_W3C_PROPAGATION` in MeshConfig `extensionProviders` to
  extract B3 headers preferentially, fall back to W3C `traceparent` headers, and inject both header types
  upstream for better tracing interoperability. See [Envoy docs](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/v3/zipkin.proto#envoy-v3-api-enum-config-trace-v3-zipkinconfig-tracecontextoption) and [`MeshConfig` reference](/docs/reference/config/istio.mesh.v1alpha1/) and [usage](/docs/tasks/observability/distributed-tracing/) for more information.

- **Removed** metric expiry support. Use `StatsEviction` in bootstrap configuration instead.

## Extensibility

- **Fixed** an issue where `EnvoyFilter` using `targetRef` with kind `GatewayClass` and group `gateway.networking.k8s.io` in the root namespace was not correctly propagated.

## Installation

- **Updated** the istiod helm chart to create `EndpointSlice` resources instead of `Endpoints` for remote istiod installs due to `Endpoints`' deprecation as of Kubernetes 1.33.
  ([Issue #57037](https://github.com/istio/istio/issues/57037))

- **Updated** Kiali addon to version v2.17.0.

- **Added** ability to completely null out resource limits or requests in the gateway chart.

- **Added** support for "persona-based" installations to our Helm charts based on the scope of generated/applied resources.
    - If no `resourceScope` is set, all resources will be installed. This is the same behavior a user would expect from 1.27 charts.
    - If `resourceScope` is set to `namespace`, only namespace-scoped resources will be installed.
    - If `resourceScope` is set to `cluster`, only cluster-scoped resources will be installed. This can enable a Kubernetes administrator to manage the resources in the cluster and the mesh administrator to manage the resources in the mesh.
  For the ztunnel chart, `resourceScope` is a top-level field. For all other charts, it is a field under `global`.
  ([Issue #57530](https://github.com/istio/istio/issues/57530))

- **Added** support for the environment variable `FORCE_IPTABLES_BINARY` to override iptables backend detection and use a specific binary.  ([Issue #57827](https://github.com/istio/istio/issues/57827))

- **Added** `.Values.podLabels` and `.Values.daemonSetLabels` to istio-cni Helm chart.

- **Added** `service.clusterIP` configuration to Gateway chart to support overriding the `spec.clusterIP` of the `Service` resource. This could be useful in cases where the user wants to set a specific cluster IP for the Gateway service instead of relying on automatic assignment.

- **Added** a new representation of revision tags using cluster IP services, meant to stop using mutating webhooks in ambient mode.
  `istioctl tag set <tag> --revision <rev>` and the `revisionTags` Helm value will both create a `MutatingWebhook` using the current
  specifications and a `Service` similar to the istiod `Service` but including the `istio.io/tag` label to store the mapping.

- **Added** `internalTrafficPolicy` option for gateway service (needed, for example when installing ArgoCD with gateway which is an internal application).

- **Fixed** an issue where the PDB created by a default installation was blocking the draining of Kubernetes nodes.
  ([Issue #12602](https://github.com/istio/istio/issues/12602))

- **Upgraded** Gateway API support to v1.4. This introduces support for `BackendTLSPolicy` v1.

## istioctl

- **Added** automatic detection of the default revision in `istioctl` commands. When `--revision` is not explicitly specified, the default revision (as configured by `istioctl tag set default`) will be used automatically.
  ([Issue #54518](https://github.com/istio/istio/issues/54518))

- **Added** support for specifying both `--level` and `--stack-trace-level` for `istioctl admin log`.
  ([Issue #57007](https://github.com/istio/istio/issues/57007))

- **Added** support specifying the proxy admin port for `istioctl experimental authz`, `istioctl proxystatus`, `istioctl bug-report` and `istioctl experimental describe` with the flag `--proxy-admin-port`.

- **Added** flags to support list debug types for `istioctl experimental internal-debug`.
  ([Issue #57372](https://github.com/istio/istio/issues/57372))

- **Added** support for displaying connection information for `istioctl ztunnel-config all`

- **Fixed** IST0173 analyzer (`DestinationRuleSubsetNotSelectPods`) incorrectly flagging `DestinationRule` subsets as not selecting any pods when the subsets used topology labels.
