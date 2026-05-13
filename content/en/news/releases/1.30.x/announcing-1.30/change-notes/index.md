---
title: Istio 1.30.0 Change Notes
linktitle: 1.30.0
subtitle: Minor Release
description: Istio 1.30.0 release notes.
publishdate: 2026-05-14
release: 1.30.0
weight: 10
aliases:
    - /news/announcing-1.30.0
---

## Traffic Management

- **Improved** endpoint selection for multi-network environments to use the gateway for network-specific endpoints when the local proxy network is unset.

- **Improved** sidecar proxy service namespace selection. When configuring sidecar proxies, if a hostname exists
  in multiple namespaces, Istio now prefers Kubernetes services and falls back to the oldest non-Kubernetes
  service (e.g. `ServiceEntry`) by creation time. Previously, the first visible namespace alphabetically was
  chosen.

- **Added** opt-in synthesis of `x-forwarded-client-cert` at ambient waypoints. Setting the
  annotation `ambient.istio.io/xfcc-include-client-identity: "true"` on a waypoint `Gateway`
  (or its `GatewayClass`) causes the waypoint to overwrite XFCC on forwarded requests with an
  entry populated from the ztunnel-provided source workload SPIFFE identity, so upstream apps
  can see the originating client. Any inbound XFCC value is replaced. Waypoints without the
  annotation are unaffected.
  ([Issue #54995](https://github.com/istio/istio/issues/54995))

- **Added** support for `TLSRoute` termination and mixed mode.
  ([Issue #55728](https://github.com/istio/istio/issues/55728))

- **Added** `PILOT_GATEWAY_TRANSPORT_SOCKET_CONNECT_TIMEOUT` environment variable to configure the
  transport socket connect timeout on gateway listeners. The default remains 15 seconds. Set to `0s`
  to disable the timeout for workloads that require longer TLS handshake times.
  ([Issue #56320](https://github.com/istio/istio/issues/56320))

- **Added** HTTP compression capability (`gzip`, `zstd`) to the HTTP server of pilot-agent.
  ([Issue #58697](https://github.com/istio/istio/issues/58697))

- **Added** input validation for `traffic.sidecar.istio.io/excludeInterfaces` annotation
  to ensure only valid Linux interface names are accepted, preventing `iptables` parameter injection.
  ([Issue #58781](https://github.com/istio/istio/issues/58781))

- **Added** support for loading multicluster remote secrets from a local filesystem path specified by
  `PILOT_MULTICLUSTER_KUBECONFIG_PATH`. When set, Istiod watches the mounted directory (for
  `.yaml` or `.yml` keys) and dynamically updates remote cluster registrations. If both
  `PILOT_MULTICLUSTER_KUBECONFIG_PATH` and `LOCAL_CLUSTER_SECRET_WATCHER` are set,
  `PILOT_MULTICLUSTER_KUBECONFIG_PATH` takes precedence.
  ([Issue #58927](https://github.com/istio/istio/issues/58927))

- **Added** experimental support for agentgateway in Istio. Agentgateway
  configuration can be enabled through the `PILOT_ENABLE_AGENTGATEWAY` feature flag.
  Istio supports agentgateway configuration via the Gateway API resources.
  ([Issue #59209](https://github.com/istio/istio/issues/59209))

- **Added** CIDR address support for `ServiceEntry` in ambient mode. `ServiceEntries` with CIDR
  addresses (e.g., `10.0.0.0/24`) are now propagated to ztunnel, enabling longest-prefix-match
  routing for traffic destined to IP ranges.
  ([Issue #59797](https://github.com/istio/istio/issues/59797))

- **Added** the ability to configure initial HTTP/2 stream and connection window sizes for HBONE CONNECT upstream clusters
  (generated for waypoints and east-west gateways) via feature flags
  `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` and `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`. These may be used to
  reduce unwanted buffering.
  ([Issue #59961](https://github.com/istio/istio/issues/59961))

- **Added** an `istio.io/connect-strategy` annotation to `ServiceEntries` to allow different DNS connection semantics. Users can set this to `RACE_FIRST_TCP_CONNECT` when DNS servers return multiple A records and the client should test each endpoint and pick the first one that results in a successful TCP connection.
  ([Issue #59083](https://github.com/istio/istio/issues/59083))

- **Added** failover priority support for DNS clusters.
  ([Issue #58674](https://github.com/istio/istio/issues/58674))

- **Added** configurable DNS upstream timeout via `DNS_FORWARD_TIMEOUT` environment variable. The default timeout remains 5 seconds. Users can increase the timeout for high-latency DNS servers or decrease it to reduce user-impacting latency when DNS servers are unresponsive (fail faster to try next server sooner). Set via `DNS_FORWARD_TIMEOUT=10s` in the `istio-proxy` container or mesh-wide via `proxyMetadata`.
  ([Issue #59813](https://github.com/istio/istio/issues/59813))

- **Added** support for TLS passthrough listeners on east-west gateways, allowing
  non-HBONE ports to be exposed via the Gateway API (e.g., to route traffic to
  the Kubernetes API server across network boundaries). This requires
  `AMBIENT_ENABLE_MULTI_NETWORK` to be enabled.
  ([Issue #59223](https://github.com/istio/istio/issues/59223))

- **Added** namespace-level traffic distribution annotation. Services inherit traffic distribution from the namespace annotation when not explicitly set on the service.
  ([Issue #58701](https://github.com/istio/istio/issues/58701))

- **Added** `DYNAMIC_DNS` wildcard `ServiceEntry` support for sidecar proxies for both `MESH_INTERNAL` and `MESH_EXTERNAL` locations.
  Enables L7 HTTP routing (via Host header) and L4 TLS routing (via SNI) with observability for wildcard hosts (e.g., `*.example.com`)
  in traditional sidecar mode. Note that it is possible to spoof SNI for TLS connections that match the wildcard host.
  E.g. a client connecting to `foo.example.com` could connect via `ServiceEntry` `*.example.com` while having SNI set to `bar.example.com`.
  ([Issue #58244](https://github.com/istio/istio/issues/58244))

- **Added** `TrafficExtension` API to the extensions package, enabling first-class support for Lua extensibility.

- **Enabled** `protocol: TLS` Gateway listeners by default. Gateway listeners with `protocol:
  TLS` (used for TLS passthrough via `TLSRoute`) are now accepted without requiring
  `PILOT_ENABLE_ALPHA_GATEWAY_API=true`, since `TLSRoute` graduated to GA in Gateway API `v1.5.0`.

- **Fixed** an issue preventing the usage of Kubernetes User Namespaces (`hostUsers: false`) pods together with istio-cni. Support is limited to operating systems with the `nsenter` binary. ([Issue #58750](https://github.com/istio/istio/issues/58750))

- **Fixed** Gateway API CORS handling: properly parse the `Origin` header when wildcard origins are used, ignore unmatched preflights, and apply stricter `Origin` header parsing overall.
  ([Issue #59018](https://github.com/istio/istio/issues/59018), [Issue #59026](https://github.com/istio/istio/issues/59026))

- **Fixed** an issue where waypoints failed to add the TLS inspector
  listener filter when only TLS ports existed, causing SNI-based routing
  to fail for wildcard `ServiceEntry` resources with `resolution: DYNAMIC_DNS`.
  ([Issue #59024](https://github.com/istio/istio/issues/59024))

- **Fixed** error wrapping in file-based config store to use `%w` verb, enabling proper error chain
  propagation with `errors.Is()` and `errors.As()`.
  ([Issue #59078](https://github.com/istio/istio/issues/59078))

- **Fixed** Gateway API `tls.Options[gateway.istio.io/tls-terminate-mode]` to properly override TLS mode after `CACertificateRefs` processing.
  ([Issue #59098](https://github.com/istio/istio/issues/59098))

- **Fixed** a nil pointer dereference in `ServiceEntry` validation for `DYNAMIC_DNS` resolution that could crash istiod.
  ([Issue #59171](https://github.com/istio/istio/issues/59171))

- **Fixed** `cni` agent behavior to respect `excludeNamespaces` config so that behavior is consistent between the plugin and agent.
  ([Issue #59295](https://github.com/istio/istio/issues/59295))

- **Fixed** istiod crashing when `PILOT_ENABLE_AMBIENT=true` but
  `AMBIENT_ENABLE_MULTI_NETWORK` is not set and a `WorkloadEntry` resource exists
  with a different network than the local cluster.
  ([Issue #59321](https://github.com/istio/istio/issues/59321))

- **Fixed** an issue preventing multi-cluster waypoint routing with single network (no east-west gateway). ([Issue #58133](https://github.com/istio/istio/issues/58133))

- **Fixed** an issue where an `HTTPRoute` with no `backendRefs` returned an HTTP 500 status code
  instead of the expected 404. Per the Gateway API specification, routes without any backend
  references should return 404, while routes with backend references that all have zero weight
  should return 500.
  ([Issue #59356](https://github.com/istio/istio/issues/59356))

- **Fixed** multi-cluster installations trying to validate the wrong trust domain when the
  control plane does not have an updated `istio-reader` `ClusterRole`, failing to read the
  trust domain from the remote `ConfigMap`. Now, istiod will fall back to using the
  trust domain specified in the local mesh config until it can read the remote one.
  ([Issue #59474](https://github.com/istio/istio/issues/59474))

- **Fixed** applying multiple `VirtualService` resources for the same hostname to waypoints.
  ([Issue #59483](https://github.com/istio/istio/issues/59483))

- **Fixed** a bug where E/W gateway occasionally routed HBONE connections to a wrong service due to
  incorrect connection pooling in Envoy.
  ([Issue #58630](https://github.com/istio/istio/issues/58630))

- **Fixed** gateway deployment controller rejecting `DaemonSet` kind during reconciliation.
  ([Issue #59498](https://github.com/istio/istio/issues/59498))

- **Fixed** an issue where all `Gateways` were restarted after istiod was restarted.
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **Fixed** kubelet health probe failures for ambient mesh pods on AWS EKS when using
  Security Groups for Pods (branch ENI). istio-cni now detects branch ENI pods and
  adds IP rules to route probe traffic via the veth pair instead of VPC fabric.
  Gated behind `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (enabled by default).

- **Fixed** istiod pushing unreachable IPv6 gateway endpoints to IPv4-only proxies (and vice
  versa) in multi-network meshes with dualstack east-west gateway load balancers.

- **Fixed** a race condition that caused a panic when `HTTPRoutes` were added then immediately removed. This could occur when a user applied an `HTTPRoute`, then deleted it before the controller had a chance to process it.

- **Fixed** an issue preventing `HTTPRoute` and `GRPCRoute` from coexisting on the same gateway hostname without conflicts.
  ([Issue #59222](https://github.com/istio/istio/issues/59222))

- **Fixed** `GetAllAddressesForProxy` returning unreachable service addresses to proxies when the
  `DefaultAddress` IP family does not match the proxy's supported IP family.

- **Fixed** `ReferenceGrant` `to` field to handle multiple entries; previously only the last entry was effective, causing incorrect `RefNotPermitted` for references that matched an earlier entry.

- **Fixed** status reporting for `Gateway` and `ListenerSet` resources to comply with the Gateway API specification `v1.5.0`.
  It changes `Gateway` status reporting to include the number of `ListenerSets` in the `AttachedListenerSets` field
  of the `Gateway` resource, instead of the number of Listeners. It also changes status reporting for `ListenerSets` to
  report the number of routes attached to each listener in the `ListenerSet`.

- **Fixed** a bug where the default `percent` for `retryBudget` in `DestinationRule` was
  incorrectly set to 0.2% instead of the intended 20%. ([Issue #59504](https://github.com/istio/istio/issues/59504))

- **Fixed** a bug where `retryBudget` set in a `DestinationRule`'s top-level `trafficPolicy`
  was silently dropped when the destination also had a subset with its own `trafficPolicy`.
  Additionally, the `retryBudget` defined at the subset level was also ignored.
  ([Issue #59667](https://github.com/istio/istio/issues/59667))

- **Fixed** stale `status.addresses` not being cleared when a `ServiceEntry` is updated
  such that it no longer qualifies for IP auto-allocation.
  ([Issue #58974](https://github.com/istio/istio/issues/58974))

- **Fixed** a race condition that caused intermittent "proxy::h2 ping error: broken pipe" error logs.
  ([Issue #59192](https://github.com/istio/istio/issues/59192)),([Issue #1346](https://github.com/istio/ztunnel/issues/1346))

## Security

- **Added** support for multiple CUSTOM authorization providers per workload, enabling different authentication schemes (OAuth, LDAP, API keys) for different API paths.
  ([Issue #57933](https://github.com/istio/istio/issues/57933)),([Issue #55142](https://github.com/istio/istio/issues/55142)),([Issue #34041](https://github.com/istio/istio/issues/34041))

- **Added** the ability to specify authorized namespaces for debug endpoints when `ENABLE_DEBUG_ENDPOINT_AUTH=true`. Enable by
  setting `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` to a comma-separated list of authorized namespaces. The system namespace
  (typically `istio-system`) is always authorized.

- **Fixed** incorrect mapping of `meshConfig.tlsDefaults.minProtocolVersion` to `tls_minimum_protocol_version` in the downstream TLS context.
  ([Issue #58912](https://github.com/istio/istio/issues/58912))

- **Fixed** `serviceAccount` matcher regex in `AuthorizationPolicy` to properly quote the service account name, allowing for correct matching of service accounts with special characters in their names. ([CVE-2026-39350](https://nvd.nist.gov/vuln/detail/CVE-2026-39350))
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

  **Credit**: This vulnerability was discovered and reported by Wernerina (<https://github.com/Wernerina>).

- **Fixed** an issue where Istiod could issue leaf certificates with a `NotAfter` time beyond
  the signing certificate's expiration.
  ([Issue #59768](https://github.com/istio/istio/issues/59768))

- **Fixed** an authorization bypass in `AuthorizationPolicy` matching for SPIFFE identities and namespaces. Regex metacharacters in fields like `source.principals` (suffix matching) and `source.namespaces` were not properly escaped in the generated Envoy configuration, potentially allowing unintended identities to match policy rules.
  ([Issue #59992](https://github.com/istio/istio/issues/59992))

  **Credit**: This vulnerability was discovered and reported by Alex (<https://github.com/Alex0Young>).

- **Fixed** a bug where CA bundle rotation would not occur when certificates appeared in different orders.
  Only standard `CERTIFICATE` PEM blocks are considered during comparison; other block types
  (e.g., `TRUSTED CERTIFICATE`) are ignored, consistent with existing CA bundle handling in Istio.
  ([Issue #59909](https://github.com/istio/istio/issues/59909))

- **Fixed** a critical security vulnerability where Istio's JWKS fallback mechanism leaked an RSA private key, allowing attackers to forge JWT tokens and bypass authentication when JWKS fetch fails. See [CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837) for details.
  ([Advisory GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c))

  **Credit**: This vulnerability was discovered and reported by 1seal (<https://github.com/1seal>).

- **Fixed** JWKS URI CIDR blocking by using a custom control function in a custom `DialContext`.
  The control function filters connections after DNS resolution but before dialing, allowing
  the block to follow redirects and the issuer discovery path. This also preserves features
  in the default `DialContext` like happy eyeballs and `dialSerial` (trying each resolved IP in order). ([CVE-2026-41413](https://nvd.nist.gov/vuln/detail/CVE-2026-41413))

  **Credit**: This vulnerability was discovered and reported by KoreaSecurity (<https://github.com/KoreaSecurity>), 1seal (<https://github.com/1seal>), and AKiileX (<https://github.com/AKiileX>).

- **Fixed** XDS debug endpoints (`syncz`, `config_dump`) to require authentication.
  Previously accessible without authentication on plaintext XDS port 15010.
  Controlled by `ENABLE_DEBUG_ENDPOINT_AUTH` (same flag as HTTP debug endpoints). ([CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838))

  **Credit**: This vulnerability was discovered and reported by 1seal (<https://github.com/1seal>).

- **Fixed** XDS debug endpoints (`istio.io/debug/syncz`, `istio.io/debug/config_dump`) served by `StatusGen` to enforce
  same-namespace authorization for non-system callers. Previously an authenticated workload from any namespace could
  enumerate proxies and retrieve config dumps for workloads in other namespaces.

  **Credit**: This vulnerability was discovered and reported by 1seal (<https://github.com/1seal>).

- **Fixed** potential SSRF in `WasmPlugin` image fetching by validating bearer token realm URLs.

  **Credit**: This vulnerability was discovered and reported by Sergey Kanibor at Luntry (<https://github.com/r0binak>).

- **Fixed** missing `ReadHeaderTimeout` and `IdleTimeout` on the istiod webhook HTTPS server (port 15017),
  aligning it with the existing timeouts on the HTTP server (port 8080).

- **Fixed** XDS debug endpoint to pass caller namespace for proper authorization checks.

## Telemetry

- **Added** support for `app.kubernetes.io/name` and `service.istio.io/canonical-name` labels
  when populating `source_app` and `destination_app` metric labels. The priority order is:
  `app` (for backward compatibility), then `app.kubernetes.io/name`, then `service.istio.io/canonical-name`.
  This allows users who only have `app.kubernetes.io/name` labels to have their metrics properly populated.
  ([Issue #58436](https://github.com/istio/istio/issues/58436))

- **Added** `disableContextPropagation` field to the Telemetry Tracing API, allowing users to disable
  trace context header propagation (e.g., `X-B3-*`, `traceparent`) independently from span reporting.
  This is useful for preventing trace context leakage at egress gateways while maintaining internal observability.
  ([Issue #58871](https://github.com/istio/istio/issues/58871))

- **Added** support for OpenTelemetry semantic convention-aligned service attribute enrichment
  for trace spans. When `serviceAttributeEnrichment: OTEL_SEMANTIC_CONVENTIONS` is set on the
  `OpenTelemetryTracingProvider` in `MeshConfig`, `service.name` is computed following the
  OTel K8s service attributes specification fallback chain. Additionally, `service.namespace`,
  `service.version`, and `service.instance.id` are injected as `OTEL_RESOURCE_ATTRIBUTES` on
  the sidecar at injection time, and the Environment resource detector is auto-enabled so
  Envoy picks up these attributes at startup.
  ([Issue #55026](https://github.com/istio/istio/issues/55026))

- **Added** a Resource Usage panel to the Ztunnel Grafana dashboard overlaying active TCP connections, open file descriptors, and open sockets per instance.

- **Fixed** an issue where baggage-based peer metadata discovery interfered with TLS or
  PROXY traffic policies. As a short-term fix we disable baggage-based metadata discovery
  for routes with TLS or PROXY traffic policies configured, which may result in incomplete
  telemetry in multicluster deployments. We are working on addressing this limitation in
  future releases.
  ([Issue #59117](https://github.com/istio/istio/issues/59117))

## Extensibility

- **Added** support for configuring the Wasm binary size limit via the
  `ISTIO_WASM_MAX_BINARY_SIZE_BYTES` environment variable.
  ([Issue #59322](https://github.com/istio/istio/issues/59322))

- **Fixed** missing size limit on gzip-decompressed WASM binaries fetched over HTTP, consistent with
  the limits already applied to other fetch paths.

## Installation

- **Added** value `useAppArmorAnnotation` to istio-cni Helm chart. Defaults to `true`.
  When it is `true`, appArmor profile is set with `container.apparmor.security.beta.kubernetes.io` annotation (deprecated in Kubernetes 1.30).
  Otherwise, `appArmorProfile` field in `securityContext` is used.
  ([Issue #54721](https://github.com/istio/istio/issues/54721))

- **Added** `values.global.enableReaderRBAC` (default: `true`) to control installation of
  `istio-reader-service-account` and its related `istio-reader` `ClusterRole`/`ClusterRoleBinding`
  for multicluster remote-secret workflows. Set it to `false` to disable installing these
  resources. When installing with Helm, set `global.enableReaderRBAC=false` on both the base and
  istiod charts, since the `ServiceAccount` is rendered by the base chart while the related
  `ClusterRole`/`ClusterRoleBinding` are rendered by the `istiod` chart.
  ([Issue #56326](https://github.com/istio/istio/issues/56326))

- **Added** Helm v4 (server-side apply) support. Fixed a webhook `failurePolicy` field ownership
  conflict that caused `helm upgrade` with SSA to fail.
  ([Issue #58302](https://github.com/istio/istio/issues/58302)),([Issue #59367](https://github.com/istio/istio/issues/59367))

- **Added** configurable port overrides for the network gateway service via `networkGatewayPorts` values.
  ([Issue #59072](https://github.com/istio/istio/issues/59072))

- **Added** template validation to fail early when `service.ports` is empty and `networkGateway` is not set.
  ([Issue #59072](https://github.com/istio/istio/issues/59072))

- **Added** logging of configuration analysis warnings and errors in istiod logs
  for all Istio resource types (`DestinationRule`, `EnvoyFilter`, `Sidecar`, etc.),
  so operators no longer need to inspect individual resource status fields to
  discover misconfigurations.
  ([Issue #59105](https://github.com/istio/istio/issues/59105))

- **Added** `WaypointBound` status condition to `WorkloadEntry` resources, reporting whether the workload is
  successfully attached to its waypoint proxy or if there was an error binding.
  ([Issue #59993](https://github.com/istio/istio/issues/59993))

- **Added** `--tls-min-version` flag to `pilot-discovery` to configure the minimum TLS version
  for the istiod server and webhook. Supported values are `1.2` (default) and `1.3`.
  ([Issue #58789](https://github.com/istio/istio/issues/58789))

- **Added** `registry.istio.io` as the default registry for Istio images.

- **Added** `dnsPolicy` and `dnsConfig` fields to the ztunnel Helm chart for custom DNS configuration in environments with non-standard DNS requirements.

- **Fixed** CNI config file permissions to default to 0600 instead of 0644 for CIS Kubernetes benchmark `v1.12`
  compliance. Group read access can be enabled by
  setting `values.cni.env.CNI_CONF_GROUP_READ=true` environment variable on the
  istio-cni-node `DaemonSet`, which sets permissions to 0640.
  ([Issue #59071](https://github.com/istio/istio/issues/59071))

- **Fixed** a nil pointer dereference that occurred during the upgrade process in a multi-primary deployment.
  ([Issue #59153](https://github.com/istio/istio/issues/59153))

- **Fixed** an issue where setting resource limits or requests to `null` would cause validation errors (`cpu request must be less than or equal to cpu limit of 0`). This affected proxy injection, gateway generation, and Helm chart deployments.
  ([Issue #58805](https://github.com/istio/istio/issues/58805))

- **Fixed** missing `PILOT_ENABLE_NODE_UNTAINT_CONTROLLERS` environment variable in `istiod` deployment when enabling the untaint controller.
  ([Issue #52050](https://github.com/istio/istio/issues/52050))

- **Fixed** unnecessary Helm reconciliations caused by `from: []` in `NetworkPolicy` ingress rules.

- **Fixed** a field manager conflict on `ValidatingWebhookConfiguration` during `helm upgrade` with
  server-side apply in tools that respect `.Release.IsUpgrade` (Helm 4, Flux). The `failurePolicy`
  field is now omitted from the webhook template on upgrade, preserving the value set at runtime
  by the webhook controller. For tools that use `helm template` with SSA, set
  `base.validationFailurePolicy: Fail` to avoid the conflict.

## istioctl

- **Improved** the `istioctl bug-report` command's performance.

- **Added** `--skip-cluster-dump`, `--skip-analyze`, `--skip-proxy-debug`, `--skip-netstat`, and `--skip-coredumps` flags to the `istioctl bug-report` command to allow skipping expensive sections of the report.

- **Fixed** log fetching with support for include and exclude filtering for pod selection.

- **Added** `--tail` flag to set the maximum number of log lines to fetch per container. The default is still unlimited.

- **Updated** minimum supported Kubernetes version to `1.32.x`.

- **Added** port validation to `istioctl` commands to prevent invalid values outside the 1-65535 range.
  ([Issue #58584](https://github.com/istio/istio/issues/58584))

- **Added** support for `istioctl proxy-status -oyaml/json` to list proxy
  status of a single namespace.
  ([Issue #59377](https://github.com/istio/istio/issues/59377))

- **Added** an `istioctl analyze` warning (IST0175) when `RequestAuthentication` resources exist
  but `BLOCKED_CIDRS_IN_JWKS_URIS` is not configured on istiod.
  ([Issue #59523](https://github.com/istio/istio/issues/59523))

- **Added** JSON and YAML output options to the `istioctl proxy-status` subcommand.
  ([Issue #56880](https://github.com/istio/istio/issues/56880))

- **Added** support for filtering `istioctl ztunnel-config workload` and `istioctl ztunnel-config connections` output by workload pod name.

- **Fixed** an issue where `istioctl` falsely reported an error on `EnvoyFilter` with `REPLACE` operation on `VIRTUAL_HOST`.
  ([Issue #59495](https://github.com/istio/istio/issues/59495))

- **Fixed** a sorting bug in `istioctl ztunnel-config connections` which caused the output sorting to be non-deterministic.
  ([Issue #59775](https://github.com/istio/istio/pull/59775))

- **Fixed** an issue where `istioctl ztunnel-config service` JSON and YAML output did not include the `canonical` field from the ztunnel config dump.
  ([Issue #59962](https://github.com/istio/istio/issues/59962))

- **Fixed** an issue where `istioctl ztunnel-config service` JSON and YAML output did not include `cidrVips` from the ztunnel config dump.
  ([Issue #59962](https://github.com/istio/istio/issues/59962))

- **Fixed** an issue where the distroless `istioctl` containers were being built with the wrong base
  image.

## Documentation changes

- **Updated** the location of the Gateway API Inference Extension documentation; it is now in the architecture section.
  ([Issue #56948](https://github.com/istio/istio/issues/56948))
