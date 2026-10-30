---
title: Istio 1.32.0 Change Notes
linktitle: 1.32.0
subtitle: Minor Release
description: Istio 1.32.0 release notes.
publishdate: 2026-11-05
release: 1.32.0
weight: 10
aliases:
    - /news/announcing-1.32.0
---

## Traffic Management

- **Improved** delta xDS memory usage: wildcard WDS subscriptions no longer accumulate resource names
  from subsequent requests, and the `initial_resource_versions` map sent on reconnect is released
  before response generation for types that do not use it.

- **Improved** incremental EDS processing for DestinationRule changes to identify affected services
  through the sidecar scope, aligning it with CDS and avoiding per-cluster DestinationRule lookups.

- **Improved** performance when fetching PeerAuthentications for a given workload.

- **Improved** performance of sidecar RDS generation by checking the RDS cache before building the
  `VirtualHostWrapper`/route protos, so a cache hit no longer pays the cost of route generation.
  To make this possible, the RDS cache key is now computed from a conservative superset of the
  `DestinationRule`s that could influence the route (rather than only the exact set used by the
  final, filtered build). As a result, some unrelated `DestinationRule` changes — particularly
  those with wildcard hosts — may now trigger an RDS cache invalidation (and an extra push) that
  would previously have been avoided. This does not affect correctness, only the frequency of
  otherwise-unnecessary cache invalidations.

- **Updated** the OpenShift platform profile to default `global.nativeNftables` to `true` for both sidecar and ambient
  mode installations. This can still be overridden by explicitly setting `global.nativeNftables=false`.

- **Added** an opt-in optimization for headless TCP service listener generation: instead of creating one
  listener per pod IP, Istio can generate a single wildcard `0.0.0.0:Port` listener with per-pod `/32` CIDR
  filter chains. This reduces xDS listener count and payload size for large headless services (e.g.
  StatefulSets). This is disabled by default; enable it by setting the
  `PILOT_ENABLE_HEADLESS_FILTER_CHAIN_LISTENER` environment variable to `true` on istiod.
  ([Issue #60552](https://github.com/istio/istio/issues/60552))

- **Added** `outlierDetectionHttpErrorCodes` field to `DestinationRule.OutlierDetection`,
  allowing users to specify which HTTP status codes are treated as errors for outlier
  detection. If specified, only responses with one of these codes are counted as errors
  toward the `consecutive5xxErrors` and `consecutiveGatewayErrors` ejection thresholds.
  If not specified, only 5xx responses are counted as errors.
  ([Issue #60828](https://github.com/istio/istio/issues/60828))

- **Added** experimental support for the Gateway API `XBackend` resource, used
  to describe the behavior clients must use when connecting to specific destinations.
  Support for the `ClientAndServer` Backend TLS mode is currently disabled.
  ([Issue #60747](https://github.com/istio/istio/issues/60747))

- **Added** a validation warning for `ServiceEntry` addresses that are catch-all (`0.0.0.0`, `::`), have an unspecified network (`0.0.0.0/N`, `::/N`),
  or are a CIDR with a prefix shorter than `/8`. A `ServiceEntry` like this with `resolution: NONE` and the default `exportTo` can make every sidecar
  in the mesh pass through traffic on its ports, bypassing `outboundTrafficPolicy` `REGISTRY_ONLY`. Use a narrower CIDR and `exportTo: ["."]`.
  For egress enforcement, use an egress gateway with a NetworkPolicy.

- **Added** a per-type watch summary (resource name count and wildcard flag) to the `/debug/adsz`
  endpoint, and a `?brief` parameter that omits the watched resource name lists, which can be very
  large in big meshes.

- **Added** support for Gateway API client certificate TLS configuration when using `agentgateway`. Gateways now honor
  frontend client certificate validation (`spec.tls.frontend`, including `AllowInsecureFallback` mode) and backend client
  certificates (`spec.tls.backend.clientCertificateRef`), and report the corresponding `ResolvedRefs` and
  `InsecureFrontendValidationMode` conditions in status.

- **Added** a new `backendUtilization` load balancer policy to `DestinationRule`. It uses the
  utilization that backends report through ORCA load reports to dynamically weight endpoints, so
  that endpoints reporting higher utilization receive proportionally fewer requests. This is
  implemented with Envoy's `client_side_weighted_round_robin` load balancing policy.
  ([Issue #60814](https://github.com/istio/istio/issues/60814))

- **Added** support for cluster-level connection buffer limits (`clusterPerConnectionBufferLimitBytes`)
  via `connectionSettings` in `ProxyConfig`, including `EDGE` profile defaults for gateway proxies.

- **Added** a `defaultInboundHttpRetryPolicy` mesh config field to configure the default retry policy
  applied to inbound routes on sidecars. Previously this policy was hardcoded to 2 attempts on
  `reset-before-request` and could not be tuned or turned off. Only `attempts`, `retryOn` and
  `backoff` apply; setting `defaultInboundHttpRetryPolicy: {}` disables inbound retries mesh-wide.

- **Added** a new `MERGE_AND_REPLACE_LIST` patch operation to `EnvoyFilter`. It behaves like
  `MERGE`, except that repeated (list) fields present in the patch fully replace the
  corresponding list in the generated configuration instead of being appended to it. This
  applies to the `CLUSTER`, `LISTENER`, `FILTER_CHAIN`, `ROUTE_CONFIGURATION`, `VIRTUAL_HOST`,
  `HTTP_ROUTE`, `NETWORK_FILTER`, `HTTP_FILTER`, and `LISTENER_FILTER` patch targets, including
  lists nested inside `Any`-typed configurations such as filter `typed_config`.

- **Added** support for the `transportSocket` field in the `EnvoyFilter` filter chain match, allowing patches to
  select filter chains by the transport socket they are configured with, such as
  `envoy.transport_sockets.tls` for filter chains that terminate TLS. Unlike `transportProtocol`, which matches
  the traffic a filter chain accepts, this matches the extension that processes the connection bytes.

- **Added** `failurePercentageThreshold` field to `DestinationRule.OutlierDetection`, allowing
  hosts to be ejected based on their failure rate over the analysis `interval` instead of
  requiring consecutive failures. Unlike `consecutive5xxErrors` and `consecutiveGatewayErrors`,
  a host's errors do not need to occur back-to-back, so a host with a high failure rate is
  still ejected even if its failures are interspersed with successful requests.

- **Added** support for overriding the ALPN protocols advertised by TLS-terminating gateways with the Gateway
  resource's `alpnProtocols` field.

- **Added** support for `globalDownstreamConnectionLimit` in `ProxyConfig.connectionSettings`,
  providing a first-class API field for configuring the global downstream connection limit.
  This takes precedence over the existing `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS` metadata
  and the deprecated `overload.global_downstream_max_connections` runtime flag.
  ([Issue #57973](https://github.com/istio/istio/issues/57973))

- **Added** support for applying `ProxyConfig` resources with workload selectors in the mesh root namespace
  to matching workloads across all namespaces. A matching workload-scoped `ProxyConfig` in the workload's
  own namespace takes precedence over the root namespace configuration.

- **Added** synthesis of `x-forwarded-client-cert` on sidecars when coming over hbone.

- **Fixed** the ambient node-untaint controller removing the `cni.istio.io/not-ready` taint when
  only istio-cni was ready. It now also waits for ztunnel to be ready on the node, so pods are not
  scheduled onto a node whose ztunnel is still wedged. This can be disabled with
  `PILOT_NODE_UNTAINT_CHECK_ZTUNNEL=false`, and only applies when ambient is enabled.
  ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **Fixed** an issue where enabling ambient multi-network for ingress gateways
  broke ingress gateway routing to sidecar pods; the issue prevented sidecar
  and ambient co-existing in the same Istio multi-network deployment.
  ([Issue #60609](https://github.com/istio/istio/issues/60609))

- **Fixed** a bug where Gateway API listeners using the OPTIONAL_MUTUAL TLS
  termination mode failed to authorize the client CA secret for SDS, leaving the
  validation context stuck in a WARMING state. The CA certificate reference is now
  authorized for OPTIONAL_MUTUAL the same way it already was for MUTUAL.
  ([Issue #60618](https://github.com/istio/istio/issues/60618))

- **Fixed** a bug where a ServiceEntry whose address is a CIDR generated an outbound
  listener on the 0.0.0.0 wildcard for a reserved proxy port (for example the
  outbound capture port 15001). The wildcard listener collided with the
  virtualOutbound listener, the whole listener update was rejected, and the sidecar
  failed to start. Such ports are now skipped, matching the behavior for services
  with a concrete address.
  ([Issue #60666](https://github.com/istio/istio/issues/60666))

- **Fixed** an issue in ambient mode where the CNI node agent auto-detected iptables backend
  (`legacy` vs `nft`) could flip between agent restarts, causing duplicate
  redirect rules to be written into already-enrolled pods.
  ([Issue #61020](https://github.com/istio/istio/issues/61020))

- **Fixed** NDS name table generation for headless services to include endpoints from all service ports,
  not just the first port. Previously, when Kubernetes split EndpointSlices by port subset (e.g., heterogeneous
  `targetPort` names across pod pools), only pods present in the first-port slice were included in the DNS
  name table, causing `NXDOMAIN` for other pods' per-pod hostnames on remote clusters.
  ([Issue #61038](https://github.com/istio/istio/issues/61038))

- **Fixed** an issue where istiod CPU usage increased as the number of AuthorizationPolicies increased.
  ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **Fixed** `ALLOW_ANY_DYNAMIC_DNS` traffic failing in IPv6-only clusters because Envoy used the
  IPv4 loopback address to reach the DNS proxy.
  ([Issue #61330](https://github.com/istio/istio/issues/61330))

- **Fixed** a panic when `outlierDetection` is applied to a DNS-proxying (DFP) wildcard cluster.
  `CommonLbConfig` was nil on the clusters built by `buildDFPCluster`, so setting
  `HealthyPanicThreshold` dereferenced a nil pointer. It is now initialized for both the DFP and
  allow-any DFP clusters, with a nil guard before the assignment.
  ([Issue #61450](https://github.com/istio/istio/issues/61450))

- **Fixed** an issue where istiod repeatedly serialized the same workload when
  pushing workload metadata to Envoy proxies.
  ([Issue #61502](https://github.com/istio/istio/issues/61502))

- **Fixed** an `HTTPRoute` rule with several `InferencePool` backendRefs configuring only one
  endpoint picker. The picker of the last backendRef listed scored every request on the rule,
  so the other pools' pickers were never invoked, and a pool with no ready endpoints failed
  the whole rule rather than its own weighted share. Each pool now gets its own picker,
  attached to its own weighted cluster.
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Fixed** two `HTTPRoute`s sharing a `rules[].name` on the same gateway overwriting each
  other's endpoint picker. Rule names only have to be unique within one `HTTPRoute`, but the
  pickers were keyed by name across all of them, so a route could be served by another
  route's picker. Pickers are now resolved per backendRef, so a shared name no longer moves
  one route's picker onto another.
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Fixed** a route rule losing its `InferencePool` endpoint picker when it also carried a
  CORS filter. Both are written into the same per-filter configuration, and the CORS path
  replaced the map rather than adding to it.
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Fixed** the Istio CNI agent panicking when a pod's status contained an invalid IP address.
  Invalid addresses are now logged and skipped.

- **Fixed** a Gateway resource with HBONE listener being sent to sidecars as an
  mTLS gateway.
  ([Issue #61618](https://github.com/istio/istio/issues/61618))

- **Fixed** an issue where Envoy proxies subscribed to Workload metadata discovery (MDS) did not
  receive incremental workload updates for Address-only changes when
  `AMBIENT_SCOPED_ADDRESS_PUSHES` was enabled (the default).

- **Fixed** a `panic` in istiod when generating a `STRICT_DNS`/`LOGICAL_DNS` cluster for a
  `ServiceEntry` with `resolution: DNS` whose `endpoints` span more than one `locality`, combined
  with a `DestinationRule` that sets `trafficPolicy.loadBalancer.localityLbSetting.failoverPriority`.
  Previously, istiod would crash and enter a crash loop as soon as an affected proxy connected,
  preventing any configuration from being pushed.
  ([Issue #61857](https://github.com/istio/istio/issues/61857))

- **Fixed** an issue where the istio-cni helm chart did not respect the value set for istioOwnedCNIConfigFileName.
  **Fixed** an issue where updates to the istio-cni config via the helm chart did not restart the istio-cni to pick
  up the new values.
  **Fixed** an issue when uninstalling the istio-cni helm chart, the owned istio cni config was not removed or the
  primary cni config did not have the istio-cni plugin removed.
  **Fixed** an issue when enabling the owned istio cni config, the primary cni config was not cleaned up.
  **Fixed** an issue when changing the owned istio cni config filename, the previous filename was not removed.
  ([Issue #61890](https://github.com/istio/istio/issues/61890))

- **Fixed** concurrent push context initialization when EDS debouncing is disabled.
  ([Issue #61924](https://github.com/istio/istio/issues/61924))

- **Fixed** an issue where, with `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` enabled, incremental CDS pushes removed gateway clusters
  for Services listed in the `envoyfilter.istio.io/referenced-services` annotation of an `EnvoyFilter`. These clusters were
  only restored on the next full push.
  ([Issue #62067](https://github.com/istio/istio/issues/62067))

- **Fixed** a situation where fetching the JWKS could block xDS generation.
  ([Issue #62486](https://github.com/istio/istio/pull/62486))

- **Fixed** an issue where an agentgateway waypoint that a service referenced only as its canary,
  via the `istio.io/use-waypoint-canary` label, was not programmed with the routes and policies
  attached to that service. Connections shifted to the canary waypoint were rejected, because the
  waypoint had no configuration for the service it was fronting.
  ([Issue #61036](https://github.com/istio/istio/issues/61036))

- **Fixed**: when multiple `TCPRoute`s or `TLSRoute`s attach to the same `agentgateway` Gateway
  listener, the oldest route (by creation timestamp, then namespace/name) is now consistently
  selected, following the Gateway API conflict-resolution rules. Previously the route bound to the
  listener was not deterministic, so traffic could reach the wrong backend.

- **Fixed** an issue where the pre-marshaled workload used for change detection and versioning
  in ambient was not stable when a workload had more than one service, which made unchanged
  workloads look modified on every recompute and prevented unchanged workloads from being
  skipped when a client reconnected.

- **Fixed** an issue where the cni does not remove ipset entries for a pod that had failures during creation. All ipset entries associated with the pod are now removed.

- **Fixed** an issue in ambient multi-network mode where the `kubernetes.default` service could be
  marked as globally scoped by `serviceScopeConfigs`, causing the API server service to be shared
  across clusters. The `kubernetes.default` service is now always treated as cluster-local.

- **Fixed** an issue where the network gateway selected for a workload was picked in a random
  order when a network had more than one gateway entry, which caused unnecessary workload
  (WDS) pushes on every recompute and could alternate the gateway address a workload uses.

- **Fixed** a memory leak affecting Istiod ambient multi-cluster mode where rotating a remote cluster's
  credentials leaked that cluster's entire cached state.  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** the `istio.io/use-waypoint-canary` label bypassing the `serviceEntryVisibility`
  NAMESPACE isolation: a NAMESPACE-visibility `ServiceEntry` could route its canary share of
  traffic through a waypoint in another namespace. The canary waypoint is now subject to the
  same cross-namespace refusal as the primary.

**Credit**: This issue was reported by Raphael Zanarelli.

- **Fixed** an issue where istio-cni skipped cleanup for an ambient pod deleted together with its namespace, leaving its ztunnel proxy and host probe ipset entry behind.

- **Fixed** an issue where istiod permanently retained a copy of every workload resource name for each
  envoy MDS (WDS, used for telemetry metadata lookups) connection that sent `initial_resource_versions`.

- **Fixed** an `EnvoyFilter` `LISTENER_FILTER` `MERGE` patch corrupting the listener filters
  shared by all proxies and being applied to listener filters that did not match
  `match.listener.listenerFilter`.

- **Fixed** configuration dependency filtering for gateways to exclude unrelated configuration updates.
  Gateway scope construction also skips collecting mesh VirtualServices used only for waypoint routing.

- **Fixed** a Gateway API issue where a cross-namespace TLS `certificateRef` or
  `caCertificateRef` was resolved before the `ReferenceGrant` authorization
  check, so a listener's `ResolvedRefs` status could distinguish whether the
  referenced Secret or ConfigMap existed even when no grant permitted the
  reference. Authorization now runs first, returning `RefNotPermitted` for any
  ungranted cross-namespace reference.

**Credit**: This issue was reported by Darryl Jaskolski.

- **Fixed** an HBONE stream leak in ambient mode where `connect_originate` streams
  could stay open forever after a peer fully closed the connection, via the Envoy
  update included in this release.

**Credit**: This issue was reported by Torben Strüver.
  ([Issue #60074](https://github.com/istio/istio/issues/60074))

- **Fixed** removing a single event handler from a CRD-backed informer removing every handler on
  that informer. In ambient multi-cluster mode this fired on every remote cluster credential
  rotation, leaving istiod waiting forever for the new cluster's collections to sync, so remote
  network gateways went missing and the workload index could stop updating until restart.
  ([Issue #61827](https://github.com/istio/istio/issues/61827))

- **Fixed** a memory leak in ambient multi-cluster mode where collections were registered with the
  krt debugger but never unregistered when a remote cluster was removed or its configuration changed,
  causing debugger registrations to accumulate over time.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** ambient multi-cluster dropping configuration from a remote cluster while its per-cluster
  collections were being swapped, for example when its credentials were rotated. The swap was seen as
  the removal of one cluster and the addition of an unrelated one, so services, waypoints and workloads
  from that cluster could briefly disappear from the config served to proxies, and events happening
  during the swap could be missed entirely.
  ([Issue #61348](https://github.com/istio/istio/issues/61348))

- **Fixed** Istio components hanging indefinitely when a Kubernetes API request gets no
  response, for example when a load balancer or proxy silently drops the return path.
  Previously such a request could stay open forever, stalling the controller that issued
  it until the process restarted. Requests now time out on the client side, so a stuck
  request is canceled and the component recovers on its own. Each timeout is logged as a
  warning and counted by the `kube_client_deadline_fired_total` metric.

- **Fixed** listener conflict tracking treating a `Gateway` and a `ListenerSet` with the same
  namespace and name as the same object, which caused a conflict recorded for one to mark the
  other's winning listener as `Conflicted` and stop it from being programmed.

- **Fixed** ListenerSet conflict resolution for hostname and protocol conflicts.
  Conflicting listeners are now correctly rejected and ListenerSet status conditions
  report in compliance with Gateway API 1.5.
  ([Issue #60775](https://github.com/istio/istio/pull/60775))

- **Fixed** an issue where EDS-irrelevant configuration updates coalesced with an endpoint update
  caused full EDS generation instead of updating only the affected endpoint assignments.

- **Fixed** ServiceEntries with a present but empty workload selector incorrectly matching all workloads in their namespace.

- **Fixed** a pod in a remote cluster, selected by a `ServiceEntry` may not have been recomputed
  when it became an endpoint of that service. The recompute was addressed to the cluster istiod
  runs in rather than the cluster the pod belongs to.

- **Fixed** a WorkloadEntry selected by a `Service` not having its corresponding proxy recomputed
  when it became an endpoint of that service.

- **Fixed** `observedGeneration` getting stuck on a stale value when a resource is modified again
  while an earlier status write is still queued.

- **Fixed** a crash in istiod when the address of an IP-addressed waypoint was also claimed by another service
  (for example, a `ServiceEntry` in a different namespace). Colliding addresses are now skipped with a warning
  instead of panicking, which previously allowed a low-privileged tenant to crash the control plane. 
  See [GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6).
  Reported by [@yshch](https://github.com/yshch).

- **Fixed** unhealthy endpoint propagation when `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` or
  `PILOT_SEND_UNHEALTHY_ENDPOINTS` is enabled. Unready pods selected by `ServiceEntry` resources
  and unhealthy health-checked `WorkloadEntry` resources selected by Kubernetes Services or
  `ServiceEntry` resources are now retained with their health status instead of being omitted.

- **Fixed** `VirtualService` validation skipping the remaining gateway names after an entry without a namespace
  in `gateways` and in HTTP/TLS/TCP match `gateways`. Invalid gateway names listed after
  such an entry are now rejected.

- **Fixed** `VirtualService` validation accepting HTTP status `600` in `fault.abort.httpStatus` and `directResponse.status`.
  Envoy only allows status codes in the range 200-599 for these fields, so such values are now rejected by validation.

- **Fixed** a regression that prevented WDS pushes from skipping debouncing by adding
  the `PILOT_ENABLE_WDS_DEBOUNCE` environment variable, enabled by default.
  Set it to `false` to allow WDS pushes to skip debouncing independently of EDS pushes.
  ([Issue #62125](https://github.com/istio/istio/issues/62125))

- **Optimized** `EnvoyFilter` merge patch processing by caching decoded typed configurations,
  avoiding repeated unmarshalling during xDS configuration generation.

- **Optimized** configuration pushes to gateways. Istiod now tracks the `VirtualService` resources
  bound to the `Gateway` resources that each ingress gateway or ambient east-west gateway serves, and
  only pushes a `VirtualService` change to the gateways it is bound to, instead of to every gateway in
  the mesh. This also optimizes CDS and RDS generation for gateways.

- **Optimized** proxyless gRPC route generation by skipping rebuilds for updates that do not affect
  routes, such as endpoint-only changes.


## Security

- **Improved** the evaluation of `ALLOW` policies on routes targeted by an `AuthorizationPolicy`.
  A route-scoped `ALLOW` policy is evaluated together with the gateway's own `ALLOW` policies, so
  a request is permitted if it matches either. A route-scoped `ALLOW` policy therefore widens
  access on that route rather than restricting it, consistent with how `ALLOW` policies in the
  root and workload namespaces already combine. Route-scoped `DENY` policies are additive and
  cannot override a `DENY` policy defined for the gateway or in the root namespace.
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **Updated** the `distroless` images to a `cgr.dev/chainguard/static` base with the latest CA bundle, which removes `emSign ECC Root CA - G3` following the compromise of eMudhra intermediate CA keys.

- **Added** experimental support for targeting Gateway API `HTTPRoute` resources from an
  `AuthorizationPolicy` via `targetRefs`, allowing `ALLOW` and `DENY` rules to be scoped to an
  individual route rather than the entire gateway. This is disabled by default and is enabled by
  setting `ENABLE_GATEWAY_API_HTTPROUTE_AUTH=true` on `istiod`. The policy must live in the same
  namespace as the `HTTPRoute` it targets, and only ingress gateways are supported; waypoints and
  sidecars ignore these policies. `CUSTOM` and `AUDIT` actions cannot be targeted at an
  `HTTPRoute`, and an `HTTPRoute` target reference cannot be combined with target references of
  other kinds in the same policy.
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **Added** analyzer message `IST0178`, which warns when an `EnvoyFilter` inserts an HTTP filter
  while an `AuthorizationPolicy` targeting an `HTTPRoute` is present. EnvoyFilters that clear the
  routing cache after a route-dependent filter has run can cause a request to be routed
  differently than it was when the filter was evaluated.
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **Added** a `WORKLOAD_IDENTITY_SOCKET_TIMEOUT` environment variable to
  `pilot-agent`, which configures how long to wait at startup for an external
  SDS provider, such as SPIRE, to create and start serving on the workload
  identity socket. Without configuring the timeout, the socket is checked
  only once at startup, so a provider that binds its socket after
  `pilot-agent` starts could cause the proxy to request the system root CA
  from the external SDS provider, failing upstream TLS validation. Defaults
  to `0s`, which preserves the existing single-check behavior.
  ([Issue #61343](https://github.com/istio/istio/issues/61343))

- **Added** `PILOT_DISABLE_SELF_SIGNED_CA` environment variable to istiod. When set to `true`, istiod fails to start its CA
  instead of generating or reusing a self-signed root CA (`istio-ca-secret`) when no plugged-in `cacerts` bundle is present.
  This allows deployments that must only use a plugged-in CA to fail closed rather than falling back to
  an unintended self-signed root. The default is `false`.

- **Added** support for configuring ECDH curves for TLS-terminating gateways with the Gateway resource's `ecdhCurves` field.

- **Added** a `presence` field to `JWTRule` in `RequestAuthentication`. When set to `REQUIRED`, the JWT token for that rule must be present and valid; requests without it are rejected with `401 Unauthorized`.
  Previously, configuring multiple `jwtRules` validated each token independently but allowed requests with only one valid token to pass. Setting `presence: REQUIRED` on each rule enforces that all configured tokens must be present and cryptographically valid.
  This is useful when workloads must receive tokens from multiple issuers on distinct headers, for example an identity token in `Authorization` and a scope token in a custom header.
  The field defaults to `OPTIONAL`, preserving existing behavior for current `RequestAuthentication` resources.
  When multiple `REQUIRED` rules are configured, claims from all validated tokens are accessible in `AuthorizationPolicy` via `request.auth.claims`. Each provider's payload is stored under its own metadata key, so authorization rules can reference claims from any of the required tokens.
  ([Issue #60823](https://github.com/istio/istio/issues/60823))

- **Fixed** the ability to clear the Certificate Revocation List (CRL) by either specifying the empty string as the ca-crl.pem or removing it.
  ([Issue #61073](https://github.com/istio/istio/issues/61073))

- **Fixed** an incorrect status message for DENY AuthorizationPolicies with
  only HTTP attributes in ambient mode. These policies are not enforced by
  ztunnel (empty matches are skipped), so the status now reports that they
  have no effect and recommends deploying a waypoint proxy with a targetRef.
  ([Issue #61126](https://github.com/istio/istio/issues/61126))

- **Fixed** the JWKS resolver forcing all public-key fetches to HTTP/1.1. The custom
  `TLSClientConfig` and `DialContext` used for TLS pinning and CIDR blocking caused Go's
  `net/http` to disable automatic HTTP/2, so ALPN never negotiated h2. HTTP/2 is now
  re-enabled (matching `http.DefaultTransport`), fixing JWKS fetches that fail over HTTP/1.1
  through some HTTP CONNECT proxies.
  ([Issue #61250](https://github.com/istio/istio/issues/61250))

- **Fixed** `AuthorizationPolicy` method rules being bypassed over HTTP/2 by changing
  the case of the method (e.g. `post` for `POST`). Method matching is now case-insensitive.
  See [GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5).
  Reported by [@izzy0101010101](https://github.com/izzy0101010101).

- **Fixed** a fail-open in `BackendTLSPolicy` where sidecar proxies sent upstream traffic in plaintext instead of failing closed when a policy's `caCertificateRefs` could not be resolved.

- **Fixed** the JWKS resolver's periodic background refresh caching a fetched response without
  validating that it looks like a JWKS. The synchronous fetch path already rejected a response
  that isn't shaped like a JWKS (`{"keys": [...]}`), closing off a `RequestAuthentication`
  `jwksUri` pointed at an unintended internal endpoint from having its response cached and
  served back as if it were a JWKS; the background refresh path now applies the same check.

**Credit**: This vulnerability was discovered and reported by Anthropic and Ada Logics.

- **Fixed** an SSRF gap in istiod's `RequestAuthentication` `jwksUri` fetching. istiod now
  blocks link-local and known cloud metadata addresses (such as `169.254.169.254`) at the dial
  level by default and rejects fetched responses that are not a valid JWKS. Private and loopback
  ranges remain reachable and can be blocked with `BLOCKED_CIDRS_IN_JWKS_URIS`.

- **Fixed** a panic in istiod when the OIDC/JWT authenticator received a token with a malformed
  `sub` claim. The subject is now validated to have exactly the
  `system:serviceaccount:<namespace>:<serviceaccount>` form before use.

**Credit**: This issue was reported by Kaizhe Huang.

- **Fixed** `CreateCertificate` returning raw Kubernetes API error text to callers on the
  experimental Kubernetes CSR RA path (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`), which leaked
  CSR names, signer names, and istiod's identity. The full error is now logged server-side only.
  Reported by Juno Im.

- **Fixed** the Kubernetes CSR watch loop using an abandoned `time.After` timer that could
  leave a goroutine running past request completion on the experimental Kubernetes CSR RA path
  (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). The loop is now bounded by a properly scoped
  `context.WithTimeout` and is reliably torn down on timeout or cancellation.
  Reported by Juno Im.

- **Fixed** client-requested `ValidityDuration` being accepted up to `MAX_WORKLOAD_CERT_TTL`
  (default 90d) on the experimental Kubernetes CSR RA path (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`).
  A new `MAX_RA_WORKLOAD_CERT_TTL` environment variable (default `48h`) now caps the TTL,
  limiting the blast radius of a stolen istio-token. Deployments that legitimately requested
  certificates with TTL > 48h via this path should raise `MAX_RA_WORKLOAD_CERT_TTL` after upgrade.
  Reported by Juno Im.

- **Fixed** istiod failing to start when the self-signed CA certificate in `istio-ca-secret` has expired,
  which can happen when the deployment is scaled to zero for longer than the certificate TTL.
  The expired certificate is now automatically renewed using the existing private key.

- **Fixed** a bug where the authorization check for gateway secret access did not include the
  service account's Kubernetes groups. As a result, `RoleBinding` and `ClusterRoleBinding` rules
  granting secret access to groups such as `system:serviceaccounts:<namespace>` were ignored,
  and gateways were denied access to credentials they had been granted.
  ([Issue #58120](https://github.com/istio/istio/issues/58120))

- **Fixed** several `sidecar.istio.io/*` annotations (`proxyImage`, `bootstrapOverride`,
  `logLevel`, `componentLogLevel`, `agentLogLevel`) being interpolated into the sidecar/gateway
  injection templates without output escaping, which could allow a crafted annotation value to
  inject additional fields into the generated pod or deployment spec. These annotations are now
  escaped consistently at every template sink.

**Credit**: This vulnerability was discovered and reported by localhost-detect.

- **Fixed** SSRF protection gaps in Wasm module fetching (`pkg/wasm`). The HTTP fetcher
  previously had no restriction on destination IP at all, and the OCI image fetcher's SSRF
  protection only inspected `401` bearer-realm responses, not `3xx` redirects on the actual
  manifest/blob fetch. Both fetchers now block connections to link-local addresses (which
  includes cloud instance metadata endpoints such as `169.254.169.254`) at the dial level,
  so the block applies to the original request and to every redirect hop, regardless of
  whether the redirect target is an IP literal or a hostname that resolves to one. A new
  `BLOCKED_CIDRS_IN_WASM_FETCH` environment variable lets operators additionally block
  private ranges or specific in-cluster addresses if desired.

**Credit**: The image fetcher redirect bypass was reported by 박현범 and independently by Svpernova. The unrestricted HTTP fetcher was reported by Aser Ahmed.

- **Fixed** waypoint proxies failing to receive remote JWKS clusters when a `RequestAuthentication` policy uses a service `targetRef`.

- **Fixed** istiod debug endpoints (`/debug/config_dump`, `/debug/edsz`, and the XDS `istio.io/debug/config_dump` type) matching `proxyID` as a substring, which let a caller read the config of other proxies in its own namespace by passing a partial ID. `proxyID` must now be the exact `<pod>.<namespace>` (or full connection ID); short forms such as `proxyID=istio-ingressgateway` no longer match.

**Credit**: This issue was reported by 박현범.

## Telemetry

- **Improved** mesh configuration load failures with source-specific error and fallback logging and the `istiod_mesh_config_load_errors_total` counter.
  ([Issue #61563](https://github.com/istio/istio/issues/61563))

- **Added** native Prometheus protobuf passthrough through pilot-agent's metrics merger. When a Prometheus scraper sends `Accept: application/vnd.google.protobuf; proto=io.prometheus.client.MetricFamily; encoding=delimited`, Envoy's native (sparse) histograms now reach the scraper unchanged instead of being silently degraded by text-format re-encoding. The pre-existing text/OpenMetrics scrape path is byte-for-byte unchanged.
  ([Issue #49950](https://github.com/istio/istio/issues/49950))

- **Added** a new `istio_agent_scrape_format_total{format,downgrade}` counter to pilot-agent that reports the format negotiation outcome per scrape (text / openmetrics / protobuf, with a downgrade indicator when upstreams disagree).
  ([Issue #49950](https://github.com/istio/istio/issues/49950))

- **Added** support for waypoints to record HTTP metrics for cross-cluster traffic using protocols such as TLS or PROXY when
  `AMBIENT_ENABLE_MULTI_NETWORK` and `AMBIENT_ENABLE_TLS_PROXY_HTTP_METRICS` are enabled.

- **Fixed** the `source_app` and `destination_app` metric labels to use the `app` pod label when a pod
  also has `app.kubernetes.io/name`. Since 1.29.1 they had used `app.kubernetes.io/name`, which is a
  regression from the intended behavior.
  ([Issue #62280](https://github.com/istio/istio/issues/62280))

- **Fixed** the `sidecar.istio.io/statsFlushInterval` annotation producing an invalid Envoy
  bootstrap for values of one minute or more, and for sub-second values, which prevented the
  proxy from starting.

- **Fixed** the `sidecar.istio.io/statsEvictionInterval` annotation silently truncating
  sub-second precision.

- **Fixed** a regression where a `Telemetry` resource in a waypoint's own namespace, selected by
  `targetRefs` or `selector`, was not applied when the waypoint served a Service in a different
  namespace. Access logging, metrics and tracing configured this way were silently dropped for
  every cross-namespace Service the waypoint handled.
  ([Issue #61538](https://github.com/istio/istio/issues/61538))

## Extensibility

- **Fixed** the Wasm OCI image fetcher deciding to retry a failed HTTPS fetch over
  plaintext HTTP based on the error returned by the registry. Since the registry is
  untrusted input, a MITM or malicious registry could trigger this fallback on demand
  to force plaintext transport and, without an optional module digest pinned, serve an
  arbitrary Wasm binary. The plaintext retry is now only attempted for registries the
  operator has explicitly allowlisted via `WASM_INSECURE_REGISTRIES`.

**Credit**: This vulnerability was discovered and reported by Adam Korczynski.

## Installation

- **Updated** Kiali addon to version v2.31.0.

- **Added** a `terminationGracePeriodSeconds` field to the istiod (Pilot) Helm
  values, allowing the istiod Deployment's pod termination grace period to be
  configured. Defaults to 30 seconds, matching the previous behavior.

- **Added** a `daemonSetAnnotations` value to the `istio-cni` chart, to set annotations on
  the CNI DaemonSet object itself. The chart already supported `daemonSetLabels` for labels
  and `podAnnotations` for the pods, but the DaemonSet's own annotations could not be set.

- **Added** support for specifying a custom `nodePort` for each port in the network gateway configuration.
  ([Issue #61569](https://github.com/istio/istio/issues/61569))

- **Added** `values.sidecarInjectorWebhook.revisionLabelPrecedence` to configure revision-label precedence
  for sidecar injection.

The default value is `namespace`, which preserves existing behavior. Setting this to `pod` allows a pod
`istio.io/rev` label to override a namespace `istio.io/rev` label.
  ([Issue #48316](https://github.com/istio/istio/issues/48316)),([Issue #48317](https://github.com/istio/istio/issues/48317))

- **Fixed** istiod preferring the CA cert from the separately-mounted, always-present
  `istio-ca-root-cert` ConfigMap (`/var/run/secrets/istiod/ca/root-cert.pem`) over the CA cert
  co-located with the DNS serving cert (`/var/run/secrets/istiod/tls/ca.crt`) when both exist.
  This could cause the `MutatingWebhookConfiguration`/`ValidatingWebhookConfiguration` `caBundle`
  to not match the CA after the DNS serving cert is provisioned externally (e.g. by cert-manager
  istio-csr or a manually created Secret), even though istiod itself correctly served TLS with
  the new certificate.
  ([Issue #60774](https://github.com/istio/istio/issues/60774))

- **Fixed** the gateway Helm chart's `NetworkPolicy` resource name including the revision, which caused
  the `NetworkPolicy` to be deleted and recreated when the gateway's revision changed instead of being
  updated in place.
  ([Issue #61016](https://github.com/istio/istio/issues/61016))

- **Fixed** sidecar proxy UID/GID resolution on OpenShift for workloads bound to a custom
  `SecurityContextConstraint` with a narrow or explicitly-configured UID range, which the
  namespace's preallocated UID range annotation does not advertise.
  ([Issue #61791](https://github.com/istio/istio/issues/61791))

- **Fixed** `istioctl install` and `istioctl manifest generate` rejecting the `cni.ambient.enablementSelectors`,
  `cni.ambient.shareHostNetworkNamespace` and `cni.ambient.enableAmbientDetectionRetry` values. The `istio-cni` chart
  supports them, but they were missing from the `IstioOperator` values schema, so they could only be set by installing
  the chart directly with Helm.
  ([Issue #61180](https://github.com/istio/istio/issues/61180))

- **Fixed** the `default` chart's `ValidatingWebhookConfiguration` still hardcoding `failurePolicy: Ignore`,
  which caused the same field manager conflict on `helm upgrade` with server-side apply that was
  previously fixed for the `base` and `istiod` charts.
  ([Issue #61613](https://github.com/istio/istio/issues/61613))

- **Fixed** the sidecar injector not validating the
  `traffic.sidecar.istio.io/includeOutboundPorts` annotation. A malformed
  value is now rejected at admission, consistent with the sibling traffic
  port annotations and the CNI redirect path.

- **Removed** `GOMAXPROCS` environment variable from all Istio charts.
  Go 1.25 automatically sets `GOMAXPROCS` to match CPU limits.
  ([Issue #60235](https://github.com/istio/istio/issues/60235))

## istioctl

- **Improved** `istioctl analyze` error reporting when an explicitly specified `--meshConfigFile` cannot be read or parsed.

- **Updated** minimum supported Kubernetes version to 1.33.x.

- **Fixed** `istioctl` skipping verification of the istiod certificate when connecting to XDS with a service account token (`istioctl proxy-status`, `istioctl x internal-debug`, and `--xds-address` in general). istioctl now verifies the server against the Istio root certificate from the `istio-ca-root-cert` configmap and the expected server name: `--authority` if set, the host of `--xds-address` if it is a DNS name, or `istiod.<istio-namespace>.svc` when connecting to an IP address or localhost. Pass `--insecure` (or set `ISTIOCTL_INSECURE=true`) to explicitly skip verification.

**Credit**: This issue was reported by [Leon Zlobecki](https://leonz.is).
  ([Issue #41937](https://github.com/istio/istio/issues/41937))

- **Fixed** `istioctl analyze` building Kubernetes clients directly from `istio-system`
  multicluster secrets without sanitizing the kubeconfig, which could allow a crafted
  secret to run an `exec` credential plugin (or read local files via other unsafe auth
  fields) on the machine running `istioctl`. The kubeconfig is now sanitized the same
  way istiod already sanitizes these secrets.

**Credit**: This vulnerability was discovered and reported by Adam Korczynski.

- **Fixed** `istioctl install --set values.base.validationFailurePolicy` being rejected as an
  unknown field. The value was already supported by the `base` and `istiod` charts, but was
  missing from the operator's `values_types.proto` schema.

- **Fixed** `istioctl bug-report` crashing when an include or exclude filter has too many fields.

- **Fixed** `istioctl bug-report --duration` not filtering logs when used without `--end-time`.

- **Fixed** `istioctl install --set` not supporting several Helm chart values that were
  missing from the operator's `values_types.proto` schema. The following values can now
  be set: `cni.terminationGracePeriodSeconds`, `cni.updateStrategy`,
  `cni.seLinuxOptions`, `cni.tolerations`, `pilot.initContainers`, `pilot.pdb`,
  `pilot.deploymentAnnotations`, `pilot.sidecarInjectorWebhookAnnotations`,
  `pilot.trustedZtunnelName`, `global.proxy_init.forceApplyIptables` and
  `global.waypoint.tolerations`.

- **Fixed** `istioctl manifest translate` writing unquoted values from IstioOperator
  input (such as namespace and release name) into generated install shell scripts.
  Crafted values could inject additional shell commands when those scripts were run.
  Arguments are now escaped with `shellescape.Quote`.

**Credit**: This vulnerability was discovered and reported by OpenSec Intelligence.

- **Fixed** `istioctl analyze` so `VirtualService` references to Kubernetes Gateway API `Gateway` resources no longer produce false `ReferencedResourceNotFound` errors.
  ([Issue #60708](https://github.com/istio/istio/issues/60708))

