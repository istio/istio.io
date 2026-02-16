---
title: Istio 1.29.0 Change Notes
linktitle: 1.29.0
subtitle: Minor Release
description: Istio 1.29.0 release notes.
publishdate: 2026-02-16
release: 1.29.0
weight: 10
aliases:
    - /news/announcing-1.29.0
---

## Traffic Management

- **Promoted** the `cni.ambient.dnsCapture` value to default to `true`.
  This enables DNS proxying for workloads in ambient mesh by default, improving security and performance while enabling a number of features. This can be disabled explicitly or with `compatibilityVersion=1.24`.
  Note: only new pods will have DNS enabled. To enable DNS for existing pods, pods must be manually restarted, or the iptables reconciliation feature must be enabled with `--set cni.ambient.reconcileIptablesOnStartup=true`.

- **Promoted** `cni.ambient.reconcileIptablesOnStartup` to default to `true`.
  This enables automatic reconciliation of iptables/nftables rules for existing ambient pods when the `istio-cni` DaemonSet is upgraded,
  eliminating the need to manually restart pods to receive updated networking configuration.
  This can be disabled explicitly or by using `compatibilityVersion=1.28`.

- **Promoted** support to beta for [Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/).
This feature currently remains off by default and can be turned on with the `ENABLE_GATEWAY_API_INFERENCE_EXTENSION` environment variable.
([usage](/docs/tasks/traffic-management/ingress/gateway-api-inference-extension/)) ([Issue #58533](https://github.com/istio/istio/issues/58533))

- **Added** support for Istio locality label `topology.istio.io/locality`, which takes precedence over `istio-locality`.

- **Added** an option, `gateway.istio.io/tls-cipher-suites`, to specify the custom cipher suites on a Gateway. The value is a comma separated list of cipher suites.
  ([Issue #58366](https://github.com/istio/istio/issues/58366))

- **Added** alpha support for a baggage-based telemetry system for ambient mesh. Users of multinetwork
  ambient will want to enable this feature via the `AMBIENT_ENABLE_BAGGAGE` pilot environment variable so that
  metrics for cross-network traffic are properly attributed with source and destination labels. Note that
  ztunnel already sends baggage in requests; this feature augments that functionality with waypoint-generated
  baggage as well. As such, this feature is off by default for waypoints and on by default
  in ztunnels (configurable via the `ENABLE_RESPONSE_BAGGAGE` environment variable in ztunnel).

- **Added** logic to designate a Workload Discovery (WDS) Service as canonical.
  A canonical WDS Service is used by ztunnel during name resolution unless another WDS Service
  in the same namespace as the client exists to override it. A canonical service will be configured
  from either (1) a Kubernetes `Service` resource or (2) the oldest Istio `ServiceEntry` resource that
  specifies that hostname.
  ([Issue #58576](https://github.com/istio/istio/pull/58576))

- **Added** a new feature flag `DISABLE_TRACK_REMAINING_CB_METRICS` to control circuit breaker remaining metrics tracking.
  When set to `false` (default), circuit breaker remaining metrics will not be tracked, improving performance.
  When set to `true`, circuit breaker remaining metrics will be tracked (legacy behavior).
  This feature flag will be removed in a future release.

- **Added** support for `LEAST_REQUEST` load balancing policy in gRPC proxyless clients.

- **Added** support for circuit breaking (`http2MaxRequests`) in gRPC proxyless clients.

- **Added** support for wildcard hosts in `ServiceEntry` resources with `DYNAMIC_DNS` resolution
  for TLS hosts. The TLS protocol implies that connections will be routed based on the
  request's SNI (from the TLS handshake) without terminating the TLS connection to
  inspect the Host header for routing. The implementation relies on an alpha API
  and has significant security implications (i.e., SNI spoofing). Therefore, this
  feature is disabled by default and can be enabled by setting the feature flag
  `ENABLE_WILDCARD_HOST_SERVICE_ENTRIES_FOR_TLS` to `true`. Please consider using
  this feature carefully and only with trusted clients.
  ([Issue #54540](https://github.com/istio/istio/issues/54540))

- **Fixed** an issue where sidecars tried to route requests to ambient east/west gateways incorrectly.
  ([Issue #57878](https://github.com/istio/istio/issues/57878))

- **Fixed** Istio CNI node agent startup failure in MicroK8s environments when using ambient mode with nftables backend.
  ([Issue #58185](https://github.com/istio/istio/issues/58185))

- **Fixed** an issue where `InferencePool` configurations were lost during `VirtualService` merging when multiple `HTTPRoute` referencing different `InferencePool`s were attached to the same Gateway.
  ([Issue #58392](https://github.com/istio/istio/issues/58392))

- **Fixed** an issue where setting `ambient.istio.io/bypass-inbound-capture: "true"` caused inbound HBONE traffic to timeout because the iptables rule for tracking the ztunnel mark on connections was not applied. This change allows inbound HBONE connections to function normally while preserving the expected bypass behavior for inbound "passthrough" connections.
  ([Issue #58546](https://github.com/istio/istio/issues/58546))

- **Fixed** an unreported bug where the `BackendTLSPolicy` status could lose track of the Gateway `ancestorRef` due to internal index corruption.
  ([Issue #58731](https://github.com/istio/istio/pull/58731))

- **Fixed** an issue where warmup aggression is not aligned with Envoy configuration.
  ([Issue #3395](https://github.com/istio/api/issues/3395))

- **Fixed** an issue where ingress gateways in ambient multi-cluster did not route requests to exposed remote backends. Also, a new feature flag `AMBIENT_ENABLE_MULTI_NETWORK_INGRESS` has been added and it's `true` by default. If the user wants to keep the old behavior, it can be set to `false`.

- **Fixed** an issue causing the ambient multicluster cluster registry to become unstable periodically, leading to incorrect configuration being pushed to proxies.

- **Fixed** an issue where the overload manager resource monitor for global downstream max connections
  was set to the maximum integer value and could not be configured via Runtime Flags.
  Users can now configure the global downstream max connections limit via proxy metadata `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS`.
  The runtime flag `overload.global_downstream_max_connections` is still honored if specified for backwards compatibility but is deprecated in favor
  of this new approach using proxy metadata.

  If `overload.global_downstream_max_connections` is specified, Envoy deprecated warnings will appear.

  If both `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS` and `overload.global_downstream_max_connections` are specified,
  proxy metadata will take precedence over the runtime flag.
  ([Issue #58594](https://github.com/istio/istio/issues/58594))

- **Fixed** warning about `CONSISTENT_HASH` load balancing policy in gRPC proxyless clients.

- **Fixed** gRPC xDS Listener to send both current and deprecated TLS certificate provider fields,
  enabling compatibility across old and new gRPC clients (`pre-1.66` and `1.66+`).

- **Fixed** an issue where CNI initialization could fail when creating host iptables/nftables rules for health check probes. The initialization now retries up to 10 times with a 2-second delay between attempts to handle transient failures.

## Security

- **Improved** remote cluster trust domain handling by implementing watching of remote `meshConfig`.
  Istiod now automatically watches and updates trust domain information from remote clusters,
  ensuring accurate SAN matching for services that belong to more than one trust domain.

- **Added** an opt-in feature when using istio-cni in ambient mode to create an Istio-owned CNI config
  file that contains the contents of the primary CNI config file and the Istio CNI plugin. This
  opt-in feature is a solution to the issue of traffic bypassing the mesh on node restart when the
  istio-cni `DaemonSet` is not ready, the Istio CNI plugin is not installed, or the plugin is not
  invoked to configure traffic redirection from pods to their node ztunnels. This feature is enabled by
  setting `cni.istioOwnedCNIConfig` to `true` in the istio-cni Helm chart values. If no value is set for
  `cni.istioOwnedCNIConfigFilename`, the Istio-owned CNI config file will be named `02-istio-cni.conflist`.
  The `istioOwnedCNIConfigFilename` must have a higher lexicographical priority than the primary CNI.
  Ambient and chained CNI plugins must be enabled for this feature to work.

- **Added** optional `NetworkPolicy` deployment for istiod and istio-cni

  You can set `global.networkPolicy.enabled=true` to deploy a default `NetworkPolicy` for istiod,
  istio-cni and gateways.
  ([Issue #56877](https://github.com/istio/api/issues/56877))

- **Added** support for watching symlink secrets in the Istio node agent.

- **Added** Certificate Revocation List (CRL) support in ztunnel. When a `ca-crl.pem` file is provided via plugged-in CA, istiod automatically
  distributes CRLs to all participating namespaces in the cluster.
  ([Issue #58733](https://github.com/istio/istio/issues/58733))

- **Added** an experimental feature to allow dry-run of `AuthorizationPolicy` resources in ztunnel. This feature will be disabled by default. See the Upgrade Note for details.
 ([usage](https://istio.io/latest/docs/tasks/security/authorization/authz-dry-run/)) ([Issue #1933](https://github.com/istio/api/pull/1933))

- **Added** support to block CIDRs in JWKS URIs when fetching public keys for JWT validation.
  If any resolved IP from a JWKS URI matches a blocked CIDR, Istio will skip fetching the public key
  and use a fake JWKS instead to reject requests with JWT tokens.

- **Added** a retry mechanism when checking if a pod is ambient enabled in istio-cni.
  This is to address potential transient failures resulting in potential mesh bypassing. This feature
  is disabled by default and can be enabled by setting `ambient.enableAmbientDetectionRetry` in the
  `istio-cni` chart.

- **Added** namespace-based authorization for debug endpoints on port 15014.
  Non-system namespaces restricted to `config_dump`/`ndsz`/`edsz` endpoints and same-namespace proxies only.
  Disable with `ENABLE_DEBUG_ENDPOINT_AUTH=false` if needed for compatibility.

- **Added** optional `NetworkPolicy` deployment for ztunnel.

  You can set `global.networkPolicy.enabled=true` to deploy a default `NetworkPolicy` for ztunnel.
  ([Issue #56877](https://github.com/istio/api/issues/56877))

- **Fixed** resource annotation validation to reject newlines and control characters that could inject containers into pod specs via template rendering.
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

## Telemetry

- **Deprecated** the `sidecar.istio.io/statsCompression` annotation, which is replaced by the `statsCompression` `proxyConfig` option. Per-pod overrides are still possible via `proxy.istio.io/config` annotation.
  ([Issue #48051](https://github.com/istio/istio/issues/48051))

- **Added** `statsCompression` option in `proxyConfig` to allow global configuration of HTTP compression for the Envoy stats endpoint exposing its metrics. This is enabled by default, offering `brotli`, `gzip` and `zstd` depending on the `Accept-Header` sent by the client.
  ([Issue #48051](https://github.com/istio/istio/issues/48051))

- **Added** source and destination workload identification to waypoint proxy traces.
  Waypoint proxies now include `istio.source_workload`, `istio.source_namespace`, `istio.destination_workload`, `istio.destination_namespace` and
  other source peer tags in trace spans, matching the observability capabilities of sidecar proxies.
  ([Issue #58348](https://github.com/istio/istio/issues/58348))

- **Added** support for `Formatter` type custom tag in Telemetry API.

- **Added** `istiod_remote_cluster_sync_status` gauge metric to Pilot to track the synchronization status of remote clusters.

- **Added** waypoint span tags `istio.downstream.workload`, `istio.downstream.namespace`, `istio.upstream.workload`, `istio.upstream.namespace`,
with the upstream and downstream workload and namespace.

- **Added** `timeout` and `headers` fields to `ZipkinTracingProvider` in MeshConfig extensionProviders.
The `timeout` field configures the HTTP request timeout when sending spans to the Zipkin collector,
providing better control over trace export reliability. The `headers` field allows including custom
HTTP headers for authentication, authorization, and custom metadata use cases. Headers support both
direct values and environment variable references for secure credential management.
 ([envoy]( https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/v3/zipkin.proto))([reference]( https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-ZipkinTracingProvider))([usage]( https://istio.io/latest/docs/tasks/observability/distributed-tracing/))

- **Fixed** an issue causing metrics to be reported with unknown labels in ambient multi-network deployments even
when baggage-based peer metadata discovery is enabled by setting `AMBIENT_ENABLE_BAGGAGE` environment variable
to true for pilot.
  ([Issue #58794](https://github.com/istio/istio/issues/58794)),([Issue #58476](https://github.com/istio/istio/issues/58476))

## Installation

- **Updated** `istiod` to set `GOMEMLIMIT` to 90% of the memory limit (previously 100%) to reduce the risk of OOM kills.
This is now handled automatically via the `automemlimit` library. Users can override this by setting the `GOMEMLIMIT`
environment variable directly, or adjust the ratio using the `AUTOMEMLIMIT` environment variable (e.g., `AUTOMEMLIMIT=0.85` for 85%).

- **Updated** Kiali addon to version `v2.21.0`.

- **Added** support for filtering resources that Pilot will watch, based on the environment variable `PILOT_IGNORE_RESOURCES`.
This variable is a comma-separated list of resources and prefixes that should be ignored by the Istio CRD Watcher.
If there is a need to explicitly include a resource, even when it is on the ignore list, this can be done
using the variable `PILOT_INCLUDE_RESOURCES`.
This feature enables administrators to deploy Istio as a Gateway API-only controller, ignoring mesh resources,
or to deploy Istio with support only for Gateway API HTTPRoute (e.g., GAMMA support).
  ([Issue #58425](https://github.com/istio/istio/issues/58425))

- **Added** support for customize envoy file flush interval and buffer in `ProxyConfig`.
  ([Issue #58545](https://github.com/istio/istio/issues/58545))

- **Added** safeguards to the gateway deployment controller to validate object types, names, and namespaces,
preventing creation of arbitrary Kubernetes resources through template injection.
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **Added** a setting `values.pilot.crlConfigMapName` that allows configuring the name of the ConfigMap that istiod uses to propagate its Certificate Revocation List (CRL) in the cluster. This allows running multiple control planes with overlapping namespaces in the same cluster.

- **Added** support for configuring terminationGracePeriodSeconds on the istio-cni pod, and updated the default value from 5 secs to 30 secs.
  ([Issue #58572](https://github.com/istio/istio/issues/58572))

- **Fixed** an issue where `iptables` command was not waiting to acquire a lock on
`/run/xtables.lock`, causing some misleading errors in the logs.  ([Issue #58507](https://github.com/istio/istio/issues/58507))

- **Fixed** an issue where the `istio-cni` DaemonSet treated nodeAffinity changes as upgrades,
causing CNI config to be incorrectly left in place when a node no longer matched the DaemonSet's nodeAffinity rules.
  ([Issue #58768](https://github.com/istio/istio/issues/58768))

- **Fixed** `istio-gateway` helm chart values schema to allow top-level `enabled` field.
  ([Issue #58277](https://github.com/istio/istio/issues/58277))

- **Removed** obsolete manifests from the `base` Helm chart. See Upgrade Notes for more information.

## istioctl

- **Added** `--wait` flag to `istioctl waypoint status` to specify whether to wait for the waypoint to become ready (default is `true`).

Specifying this flag with `--wait=false` will not wait for the waypoint to be ready, and will directly display the status of the waypoint.
  ([Issue #57075](https://github.com/istio/istio/issues/57075))

- **Added** support for `istioctl ztunnel-config all` and `istioctl pc all` to print headers.

- **Added** `--all-namespaces` flag for `istioctl waypoint status` to display the status of waypoints in all namespaces.

- **Added** support for specifying the proxy admin port in `istioctl ztunnel-config`.

- **Fixed** translation function lookup errors for MeshConfig and MeshNetworks in istioctl
  ([Issue #57967](https://github.com/istio/istio/issues/57967))
