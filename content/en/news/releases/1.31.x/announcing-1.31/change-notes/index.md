---
title: Istio 1.31.0 Change Notes
linktitle: 1.31.0
subtitle: Minor Release
description: Istio 1.31.0 release notes.
publishdate: 2026-08-20
release: 1.31.0
weight: 10
aliases:
    - /news/announcing-1.31.0
---

## Traffic Management

- **Improved** logging when a Gateway API CRD installed in the cluster is below the minimum version
required by this Istio version. The message is now logged at `warn` level and explains that
resources of that kind will not be processed until the CRDs are upgraded. Previously, this was
logged at `info` level and easy to miss, which made TLS passthrough breakage after upgrading to
1.30 with stale CRDs hard to diagnose.

- **Improved** istiod scalability in ambient mode by scoping XDS pushes from workload/service
`Address` changes to only the affected waypoints, instead of pushing to all waypoints and proxies.
Can be disabled with `AMBIENT_SCOPED_ADDRESS_PUSHES=false`.

- **Added** support for a custom taint name for the pilot node untaint controller via
PILOT_NODE_UNTAINT_CONTROLLERS_TAINT_NAME environment variable. Defaults to cni.istio.io/not-ready
  ([Issue #57844](https://github.com/istio/istio/issues/57844))

- **Added** support for excluding policy configuration from Istio when the
`istio.io/ignore-policy-attachment` annotation is set to "true" on a
BackendTLSPolicy, or XBackendTrafficPolicy object. This allows users to
prevent specific policies from being translated into Istio configuration,
when policy is intended for a different gateway controller than Istio.

Example usage:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: BackendTLSPolicy
metadata:
  annotations:
    istio.io/ignore-policy-attachment: "true"
{{< /text >}}

  ([Issue #60122](https://github.com/istio/istio/issues/60122))

- **Added** support for excluding namespaces and hosts from a `Sidecar` egress listener's `hosts`
using a `~` prefix on the namespace. Entries without a prefix are imported as before, and
`~`-prefixed entries subtract from them: `~ns1/*` excludes all hosts in `ns1`, and `~/foo.com`
excludes `foo.com` from every namespace. This lets large meshes import everything except a few
namespaces (e.g. `*/*` plus `~ns1/*`) without enumerating a long allowlist.
  ([Issue #60139](https://github.com/istio/istio/issues/60139))

- **Added** an initialization check that verifies the bundled `nft` binary
supports JSON output. The native nftables backend requires JSON to read
configuration during pod removal. On hosts whose `nft` binary doesn't
support JSON, those calls fail with `Error: JSON support not compiled-in` on
every removal, and the CNI agent retries indefinitely. The new check detects
this error at startup and falls back to the iptables backend.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Added** `prefix_rewrite` field to `HTTPRedirect`, enabling prefix-aware path rewriting
in redirect rules. This allows stripping or replacing the matched path prefix while
redirecting, e.g. redirecting `example.com/foo/bar` to `foo.example.com/bar`.
  ([Issue #47500](https://github.com/istio/istio/issues/47500)),([Issue #47777](https://github.com/istio/istio/issues/47777)),([Issue #52521](https://github.com/istio/istio/issues/52521))

- **Added** `budget_interval` field to the RetryBudget TrafficPolicy API to
configure the interval with which requests are considered when calculating
the retry budget. The default value, 0ms, retains the existing behavior of
considering only in-flight requests.
  ([Issue #60389](https://github.com/istio/istio/issues/60389))

- **Added** support for weighted waypoint canaries in ambient mode.
A service (or namespace) can now reference a primary and a canary waypoint
via the `istio.io/use-waypoint-canary` and `istio.io/use-waypoint-canary-namespace`
labels, with the `istio.io/use-waypoint-canary-weight` annotation directing a
configurable share of the service's in-mesh connections (and,
with `istio.io/ingress-use-waypoint`, ingress requests) to the canary waypoint
without any client changes.
  ([Issue #60801](https://github.com/istio/istio/issues/60801))

- **Added** `meshConfig.serviceEntryVisibility`, letting a mesh administrator control the visibility of
`ServiceEntry` resources. Ambient (ztunnel and waypoints) enforces visibility by default;
classic sidecars additionally honor it when `applyToSidecars` is set. The feature is
inert unless configured, so existing meshes are unaffected by default.
  ([Issue #60870](https://github.com/istio/istio/issues/60870))

- **Added** `istio-agentgateway-waypoint` GatewayClass for deploying agentgateway as a waypoint.

- **Added** `ALLOW_ANY_DYNAMIC_DNS` outbound traffic policy mode. When set in
`meshConfig.outboundTrafficPolicy.mode`, plaintext HTTP requests to unknown destinations are
forwarded via Envoy's Dynamic Forward Proxy, resolving hostnames from the Host header at
request time. Non-HTTP traffic (TLS, raw TCP) continues to use PassthroughCluster.
Scoped to sidecar proxies only. Not supported in the Sidecar CRD. Optional upstream TLS
origination can be configured via `meshConfig.outboundTrafficPolicy.tls`.

- **Added** support for `connectionSettings` in `ProxyConfig`, allowing configuration of
listener buffer limits, HTTP timeouts, HTTP/2 settings, and path/header normalization.
The new `EDGE` profile applies opinionated Envoy edge-proxy defaults to gateway proxies.

- **Added** a new `MERGE_AND_REPLACE_LIST` patch operation to `EnvoyFilter`. It behaves like
`MERGE`, except that repeated (list) fields present in the patch fully replace the
corresponding list in the generated configuration instead of being appended to it. This
applies to the `CLUSTER`, `LISTENER`, `FILTER_CHAIN`, `ROUTE_CONFIGURATION`, `VIRTUAL_HOST`,
and `HTTP_ROUTE` patch targets. Lists nested inside `Any`-typed filter configurations (HTTP,
network, and listener filters, and transport sockets) are not affected and continue to follow
`MERGE` semantics.

- **Added** implementation of the Gateway API AllowInsecureFallback feature in the client certificate validation logic.
This feature allows gateway to request client certificate and try to validate it, but if the client does not present
a certificate or certificate is not valid, gateway will still allow the connection. By default, Istio will populate
`x-forward-client-cert` HTTP header, so when AllowInsecureFallback is enabled, the backend can verify certificate
instead of the gateway, if AllowInsecureFallback is enabled.
  ([Issue #60018](https://github.com/istio/istio/issues/60018))

- **Added** support for configuring HTTP/2 keepalive PING settings on upstream connections through `DestinationRule`.
  ([Issue #55640](https://github.com/istio/istio/issues/55640))

- **Added** `defaultTrafficPolicy` to `MeshConfig`, a mesh-wide baseline `connectionPool` and
`outlierDetection` that outbound clusters inherit. A `DestinationRule` that sets one of these
blocks overrides the baseline for that block; a block the `DestinationRule` leaves unset now
inherits the mesh baseline instead of Istio's built-in defaults. When no baseline is configured,
behavior is unchanged. The baseline `connectionPool` is also applied to inbound clusters and the
passthrough cluster.

- **Added** support for Envoy's zone-aware load balancing via a new `zoneAwareLbSetting` field
on `DestinationRule.TrafficPolicy.LoadBalancerSettings` and `MeshConfig`. When enabled, Envoy
automatically routes traffic to endpoints in the same availability zone as the downstream proxy,
spilling over to other zones only when local capacity is insufficient. This differs from the
existing `localityLbSetting` in that zone-level routing is handled automatically
by Envoy using the proxy's zone distribution, rather than through static percentages.
Cross-region failover ordering can be configured via the `failover` field, and label-based
priority tiers can be layered on top via `failoverPriority`. Zone-aware load balancing requires
`ISTIO_META_ENABLE_SELF_DISCOVERY: "true"` in `meshConfig.defaultConfig.proxyMetadata` to
inject the self-discovery `local_cluster` into sidecar bootstraps. It is not supported in Ambient,
only Sidecar mode.
  ([reference](/docs/reference/config/networking/destination-rule/#ZoneAwareLoadBalancerSetting))([reference](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig))

- **Enabled** Sending unhealthy endpoints by default unless `OutlierDetection.minHealthPercent` is being configured,
can be disabled by setting `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` to `false`.

- **Fixed** on Gateway API, implement BackendTLSPolicyConflictResolution.
  ([Issue #57817](https://github.com/istio/istio/issues/57817))

- **Fixed** a bug where inbound clusters were missing for proxies that reconnected to a new istiod
instance (e.g. during rolling restarts) when the pod was not yet present in the kube informer cache.
Workload labels are now populated before service targets are computed, so the metadata fallback path
in `GetProxyServiceTargets` correctly matches services instead of returning an empty list.
  ([Issue #58125](https://github.com/istio/istio/issues/58125))

- **Fixed** When PILOT_ENABLE_QUIC_LISTENERS is enabled, generated Gateway API
Services will listen on the corresponding UDP port for each HTTPS listener.
  ([Issue #58247](https://github.com/istio/istio/issues/58247))

- **Fixed** an issue where HTTPS listeners defined via `ListenerSet` failed to deliver TLS certificates when the parent Gateway used manual deployment.
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **Fixed** an issue where HTTPRoute and GRPCRoute filters with invalid header values were silently dropped from the Envoy config instead of reporting an InvalidFilter status.
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **Fixed** a brief traffic outage when changing the `istio.io/rev` label on a Kubernetes
Gateway (or `ListenerSet`). The previously-owning control plane no longer drops the
resource and pushes empty xDS config to gateway pods that are still running on the old
revision. Status writes for non-owning revisions are still suppressed, so revisions do
not flap on each other's status.
  ([Issue #59959](https://github.com/istio/istio/issues/59959))

- **Fixed** multi-network ambient now routes to the waypoint when the ingress
on one network calls a service on a different network, and only if the
Service is configured with `istio.io/ingress-use-waypoint`.

- **Fixed** an issue where the waypoint listener config on IPv6 clusters
contained an `IPMatcher.RangeMatcher` with an empty `ranges` field when a
headless Service (`spec.clusterIP: None`) was present in the waypoint's
scope. This was produced because the IPv4-encoded `constants.UnspecifiedIP`
placeholder used for headless services' `DefaultAddress` is filtered out
for IPv6-only proxies by `FilterAddressesByIPFamily`. Envoy 1.38
strict-validates the proto's `repeated.min_items=1` rule on
`IPMatcher.RangeMatcher.ranges` and rejects the LDS push. The waypoint
listener builder now elides the `IPRangeMatcher` entry when there are no
addresses to put into it, matching the existing behaviour of the
surrounding code that already removes the hostname half from
`svcHostnameMap` for the same case. IPv4 clusters are unaffected
behaviourally — the placeholder matcher that was previously emitted
matched nothing.
  ([Issue #60310](https://github.com/istio/istio/issues/60310))

- **Fixed** an issue where `consistentHash` load balancing in `DestinationRule` would not send traffic
to new endpoints after scaling, due to an Envoy regression (`envoyproxy/envoy#45212`) where the
RING_HASH ring was not rebuilt on endpoint changes during batched updates.
  ([Issue #60312](https://github.com/istio/istio/issues/60312))

- **Fixed** a fatal `concurrent map writes` panic in the istio-cni agent when
two pods were added to the ambient mesh on the same node at the same time.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Fixed** a `DestinationRule` and a Gateway API backend policy (`BackendTLSPolicy` or `XBackendTrafficPolicy`)
targeting the same host so that the `DestinationRule` fields now take precedence and the backend policy only
fills in fields the `DestinationRule` leaves unset, regardless of which was created first.
  ([Issue #60358](https://github.com/istio/istio/issues/60358))

- **Fixed** an ambient mode bug where a single Service combining `publishNotReadyAddresses: true` with a `PreferSameZone` or `PreferSameNode` traffic distribution caused ztunnel to receive `healthPolicy: AllowAll` for every other Service using the same traffic-distribution preset, leading to traffic being routed to not-ready endpoints cluster-wide.
  ([Issue #60422](https://github.com/istio/istio/issues/60422))

- **Fixed** an issue where proxy draining could panic instead of returning an error when the Envoy admin endpoint was unavailable.

- **Fixed** an issue where additional namespaces in
meshConfig.defaultServiceExportTo and
meshConfig.defaultVirtualServiceExportTo were not being honored when the
default included the current namespace as ".".
  ([Issue #60560](https://github.com/istio/istio/issues/60560))

- **Fixed** a bug where removing a listener from a `ListenerSet` left an orphaned entry
in the resource's `status.listeners` indefinitely. The stale entry made
`status.listeners` longer than `spec.listeners` and, after repeated listener add/remove
cycles, wedged the `ListenerSet`'s `observedGeneration` so later spec changes were no
longer reflected in its status. `reportListenerSetStatus` now prunes status entries for
listeners that are no longer present in the spec, matching the existing behavior for
`Gateway` resources.
  ([Issue #60578](https://github.com/istio/istio/issues/60578))

- **Fixed** DestinationRule validation incorrectly rejecting warmup aggression values between 0 and 1.
  ([Issue #3395](https://github.com/istio/api/issues/3395)),([Issue #55153](https://github.com/istio/istio/issues/55153))

- **Fixed** a bug where istiod did not pick up updated remote cluster secrets (e.g. during
credential/token rotation) until restarted. The new cluster registry could deadlock waiting
to sync, leaving the service registry stale for the affected remote cluster.
  ([Issue #60612](https://github.com/istio/istio/issues/60612))

- **Fixed** an issue introduced in Istio 1.30 where metadata-only changes to VirtualService objects
(e.g. Helm annotations, Argo CD labels, or `kubectl.kubernetes.io/last-applied-configuration`)
triggered unnecessary XDS pushes to all proxies. This could cause a significant increase in
control plane CPU usage and push latency in clusters with many VirtualServices managed by GitOps
tooling. The fix restores the pre-1.30 behavior where only spec changes or `istio.io`
label/annotation changes trigger a push.
  ([Issue #60629](https://github.com/istio/istio/issues/60629))

- **Fixed** Duplicate and excessive pushes when using WasmPlugins due to TrafficExtension conversions.

- **Fixed** a deadlock where the istio-cni node agent pod could fail to start (for
example after a node reboot) because the CNI plugin only skipped the kube client
creation for its own agent pod when ambient mode was enabled. The preemptive
check now runs in sidecar mode as well, so the agent pod no longer blocks on a
kubeconfig it has not written yet.
  ([Issue #60668](https://github.com/istio/istio/issues/60668))

- **Fixed** default http retries for inbound routes of waypoints. The mesh config's defaultHttpRetryPolicy will apply to
local services attached to waypoints.
  ([Issue #60682](https://github.com/istio/istio/issues/60682))

- **Fixed** an issue where `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` never fired on ambient ingress gateways and waypoints because pilot-agent's drain loop counted in-process connections on Envoy's HBONE internal listeners (`connect_originate`, `connect_terminate`, `main_internal`, etc.), preventing the active-connection count from reaching zero and forcing the proxy to wait until `terminationGracePeriodSeconds`.
  ([Issue #60728](https://github.com/istio/istio/issues/60728))

- **Fixed** an issue where service.istio.io/canonical-name label can end up
ending in an invalid "." or "_" when truncated to 63 chars in the injection
template.

- **Fixed** an issue where an `HTTPRoute` with empty or omitted `backendRefs`
returned an HTTP 404 status code instead of 500. This matches the behavior
enforced by the `HTTPRouteNoBackendRefs` Gateway API conformance test,
introduced in v1.6.0.

- **Fixed** an issue where the advertised HBONE capability was not
propagated onto auto-registered WorkloadEntries for non-Kubernetes workloads.

- **Fixed** an issue where the Accepted condition on a Gateway was not set to
False when referencing an invalid or non-existent parametersRef. This
matches the behavior enforced by the `GatewayInvalidParametersRef` Gateway
API conformance test, introduced in v1.6.0.

- **Fixed** cross-network traffic through the east-west gateway being blocked by a spurious
deny-all RBAC filter when the destination service has L7 AuthorizationPolicies.
  ([Issue #60806](https://github.com/istio/istio/issues/60806))

- **Fixed** a bug where a remote cluster's network gateway could disappear from
cross-network routing after credential rotation and not recover until istiod restarted.
The in-place registry swap now re-wires the new registry to the aggregate controller's
handlers so its future gateway and service events propagate, and reloads gateways once
to pick up those discovered during the pre-swap sync.
  ([Issue #60920](https://github.com/istio/istio/issues/60920))

- **Fixed** an issue in multicluster deployments where rotating a remote cluster's
`istio-remote-secret` could permanently wipe endpoint shards for services with
stable endpoints in that cluster, making them unreachable across clusters until
istiod was restarted.
  ([Issue #61043](https://github.com/istio/istio/issues/61043))

- **Fixed** an issue where `consistentHash` load balancing in a `DestinationRule` did not work
for services routed through a waypoint proxy in ambient mode when no `VirtualService` was
present. The Envoy cluster correctly received `lb_policy: RING_HASH` but the inbound route
was missing `hash_policy`, causing Envoy to fall back to random backend selection and
breaking sticky sessions. A no-op passthrough `VirtualService` was previously required as
a workaround.
  ([Issue #61045](https://github.com/istio/istio/issues/61045))

- **Fixed** a race condition on istiod startup where the readiness probe could
report ready before the dedicated injection and validation webhook server
(`--httpsAddr`, default `:15017`) was accepting connections, causing
intermittent `failed calling webhook` timeouts when creating resources
immediately after istiod became ready. This does not affect deployments
where webhooks share the main HTTP server (empty `--httpsAddr`).
  ([Issue #61049](https://github.com/istio/istio/issues/61049))

- **Fixed** an issue where ingress gateways bypassed waypoint proxies for multi-cluster services
when remote workloads were on a different network, causing authorization policies to not be enforced.
  ([Issue #61092](https://github.com/istio/istio/issues/61092))

- **Fixed** an issue where gateway proxy Deployments could permanently fail to be created during istiod startup.
  ([Issue #61095](https://github.com/istio/istio/issues/61095))

- **Fixed** an issue where a pod selected by a `ServiceEntry` `workloadSelector` could start up
missing that service from its sidecar's inbound configuration. Traffic to the port was not
handled as the protocol declared in the `ServiceEntry`, and port-level `PeerAuthentication`
was not applied. The pod did not recover on its own; only restarting istiod repaired it.
  ([Issue #61157](https://github.com/istio/istio/issues/61157))

- **Fixed** an issue where `istio-cni` considered `hostNetwork` pods eligible for ambient
enrollment.
  ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **Fixed** when pilot generated configuration for the agentgateway, due to a number of
issues, it basically ignored ListenerSets and routes attached to them. Now, when pilot
generates configuration for the agentgateway it does not filter out ListenerSets and
routes attached to them, enabling agentgateway in Istio to handle ListenerSets properly.

- **Fixed** ListenerSet status reporting when ListenerSet is not allowed by the parent
Gateway resource for agentgateway. When ListenerSet is not allowed by the parent Gateway
we must report `Accepted` condition status as `False`, but it wasn't the case.
Additionally, given that ListenerSet feature is not experimental as of Gateway API v1.5.0,
it's no longer guarded by the `PILOT_ENABLE_ALPHA_GATEWAY_API` feature flag.

- **Fixed** an `agentgateway` Gateway now connects to sidecar-injected (mesh) backends using
Istio mutual TLS instead of plaintext. Previously, raw TCP routed to a mesh backend (via
`TCPRoute`, or a `TLSRoute` in Terminate mode) could hang for server-first protocols — where
the backend speaks first, such as SMTP or MySQL — and backends enforcing `STRICT` mutual TLS
were unreachable.

- **Fixed** a memory and goroutine leak in Istiod ambient multi-cluster mode where the per-cluster
node locality collections were scoped to the process lifetime instead of the cluster lifetime, so
they were never torn down when a remote cluster was removed.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** a bug in Istiod ambient multi-cluster mode where the aggregated (local + remote)
collections could report themselves as synced before the remote clusters had been discovered
and synced. As a result, Istiod could begin serving with local-cluster-only data, temporarily
omitting workloads, services, and endpoints from remote clusters at startup. The aggregated
collections now wait for the multi-cluster controller and every remote cluster's collections to
sync before being marked ready.

- **Fixed** an issue where an ambient-enrolled pod could be left out of the host health-probe ipset following a
node or kubelet restart, causing kubelet probes to be redirected to ztunnel and rejected until the `istio-cni`
node agent restarted. On startup the node agent could evict still-enrolled pods from the ipset when their IP
was not yet observable, and it now re-asserts probe ipset membership for enrolled pods during reconciliation.

- **Fixed** a file descriptor leak in the istio-cni node agent: when the procfs scan found
more than one network namespace for the same pod, the losing candidate's netns fd was
dropped without being closed, pinning the namespace in the kernel until garbage collection.

- **Fixed** a deadlock in the ambient CNI node agent where a pod deletion event
concurrent with a ztunnel (re)connection could permanently block the ZDS server.
  ([Issue #1674](https://github.com/istio/ztunnel/issues/1674))

- **Fixed** an issue where endpoint mTLS mode was not derived from the DestinationRule's
top-level traffic policy when a targeted subset did not specify a TLS mode for the port.
The subset traffic policy now correctly falls back to the DestinationRule-level TLS setting.

- **Fixed** status reporting for certificate references in Gateway resources to comply with the Gateway API specification v1.5.0.
It changes the Gateway status to report conditions of type ResolvedRefs and also adds extra details to the Accepted condition when it fails
due to invalid or non-existent certificates.

- **Fixed** the `Accepted` condition on a Kubernetes Gateway to reflect the validity of its
listeners. When one or more listeners are not accepted (for example, an unsupported listener
protocol), the Gateway now reports the `ListenersNotValid` reason, and is only set to
`Accepted=False` when none of its listeners are accepted. Previously the Gateway was always
reported as `Accepted` regardless of its listeners.

- **Fixed** an issue where proxyless gRPC xDS clients could receive over-broad RDS `RouteConfiguration` responses from Istiod.

- **Fixed** a bug where an internal listener was incorrectly created when the listener is of HTTPS or TLS but without a TLS section defined.
A following version of the Gateway API will [prevent](https://github.com/kubernetes-sigs/gateway-api/pull/4788) this combination of inputs from ever reaching a controller.
  ([Issue #60562](https://github.com/istio/istio/issues/60562))

- **Fixed** config generation for sidecars prior to 1.29.2.

- **Fixed** an istiod panic when processing a `VirtualService` with TCP or TLS routes that have no destinations, which could occur when the validating webhook is not installed (e.g. deployments without a default revision).
  ([Issue #60110](https://github.com/istio/istio/issues/60110))

- **Fixed** goroutine and memory leaks in istiod in ambient multi-cluster mode when remote
clusters are removed or updated. The internal collections built for each remote cluster did
not release the event handlers they had registered on their inputs when torn down, causing
goroutines and memory to accumulate over time as clusters were removed or reconfigured.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** a memory leak in the `krt` controller framework where changing the key used in a `Fetch` filter
(for example, relabeling a pod to point to a different waypoint) left stale reverse-index entries that were
never cleaned up. Over time this could grow memory usage and cause unnecessary recomputations.

- **Fixed** a goroutine leak in istiod leader election where every election cycle
(leadership lost and re-acquired) leaked one goroutine until process exit.
  ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **Fixed** ListenerSet status reporting so that a ListenerSet with no valid listeners now
reports the `Accepted` and `Programmed` conditions as `False` with reason `ListenersNotValid`.
Previously the ListenerSet-level conditions could remain `True` even when none of its listeners
were usable.

- **Fixed** a deadlock in the multicluster `ClusterStore` where `AllReady` could recursively acquire the store `RWMutex` for read via `triggerRecomputeOnSync` -> `GetByID` while a writer was waiting, blocking further reads and writes against the store.

- **Fixed** ambient multi-cluster serving a stale snapshot of a remote cluster after its credentials
were rotated. The per-cluster collections were cached by cluster ID alone, so a secret update
carrying a new kubeconfig kept reusing the collections built for the previous generation, whose
client and informers are shut down once the new one syncs. They are now cached per generation and
rebuilt on the new client.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Fixed** a memory leak in Istiod where `needResync` entries for failed pod IPs were never cleaned up.

- **Fixed** failover routing when the network is included.
Network is considered preferred but not required when determining failover priority.
As an example PreferSameZone will have the following priority:
  Network+Region+Zone, Network+Region, Network, Region+Zone, Zone, No match.

- **Fixed** generated Gateway `Service`s being rejected when two listener names sanitize to the
same Service port name (names differing only by periods versus dashes, or only past the
63-character limit), which blocked every unpublished port on the Gateway. Colliding port names
are now disambiguated with the listener's port number.

- **Fixed** a bug where the istio-cni node agent could pair an ambient pod with another
pod's network namespace when a third-party process was inside that namespace during a
scan, which could cause traffic to be proxied with the wrong identity. The node agent
now verifies that a namespace holds one of the pod's IPs before enrolling the pod.
  ([Issue #61211](https://github.com/istio/istio/issues/61211))

- **Fixed** a bug where a ztunnel reconnect (such as the periodic connection recycle
from `keepaliveMaxServerConnectionAge`) triggered a full workload (WDS) push. Istiod now
assigns each WDS resource a content-based version and, when a reconnecting client
reports the versions it already holds via `initial_resource_versions`, re-sends only
resources that changed while the client was disconnected. Older ztunnel versions that
do not report versions continue to receive the full set.
  ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **Fixed** `zoneAwareLbSetting.enabled: false` to explicitly disable Envoy's intrinsic
zone-aware routing by emitting `routing_enabled: 0%`. Previously, `enabled: false` was
a no-op: Istio emitted no `ZoneAwareLbConfig`, causing Envoy to fall back to its default
`routing_enabled: 100%`, which engaged zone-aware routing automatically whenever a
self-discovery local cluster was present. This made gradual rollout unsafe, as pods in a
mixed state (some with self-discovery, some without) would unevenly distribute traffic.

- **Upgraded** version of `nftables` used by Istio distroless images. The `nftables` version was previously pinned to 1.1.1 to avoid a bug that could cause older versions of `nftables` on K8s nodes to crash after Istio used a newer version packaged in its images on the same node.

Major Linux distributions have been informed of the issue and have released fixes. As a result, Istio is removing the `nftables` version pinning. Users are advised to update the `nftables` package on their nodes to the latest available version to ensure that the fixed version is installed.

If you continue to experience `nftables` crashes on your nodes, downgrade to an older version of Istio and contact your node OS provider to request that the fix be backported to your OS version.
  ([Issue #58492](https://github.com/istio/istio/issues/58492))

- **Optimized** sidecar egress service resolution: listeners that import only exact (non-wildcard),
explicitly-namespaced hosts now resolve services through direct service-index lookups instead of
scanning every service visible to the namespace, reducing the per-listener cost from `O(services)`
to `O(imported hosts)` and eliminating the full-list allocation.
  ([Issue #60473](https://github.com/istio/istio/issues/60473))

## Security

- **Improved** Added `PILOT_ENABLE_STRICT_GATEWAY_MERGING` to prevent cross-namespace merging
of Istio Gateways with managed GatewayAPI Gateways. When enabled (the default), Istio Gateway
CRDs from different namespaces will not be merged with managed GatewayAPI Gateway proxies.
Unmanaged (manual deployment) GatewayAPI Gateways
are not affected. Set `PILOT_ENABLE_STRICT_GATEWAY_MERGING` to `false` to disable.

- **Added** `trustDomains` and `notTrustDomains` fields to the `Source` in `AuthorizationPolicy`,
allowing users to match or exclude requests based on the trust domain derived from the peer certificate.

- **Added** support for `fips-140-3` as a new value for the `COMPLIANCE_POLICY` environment variable.
This enforces TLS 1.2 or 1.3 with FIPS-compliant cipher suites
(ECDHE_[RSA|ECDSA]_WITH_AES_*_GCM_SHA* for TLS 1.2, AES-GCM for TLS 1.3)
and restricts key agreement to P-256 or P-384 curves. On the Envoy proxy side,
this uses the native `FIPS_202205` compliance policy.
Go components (istiod, istio-agent) must be built with Go 1.24+ using
`GOFIPS140=v1.0.0` (or later validated version) to enable the native Go FIPS 140-3
cryptographic module. The `GODEBUG=fips140=only` environment variable is automatically
injected at runtime for sidecars, gateways, and the istiod control plane when
`COMPLIANCE_POLICY` is configured via the Helm `env` value
(e.g., `--set pilot.env.COMPLIANCE_POLICY=fips-140-3`).
Note: `GOEXPERIMENT=boringcrypto` (used for FIPS 140-2) is incompatible with this
policy and must not be used. BoringCrypto targets FIPS 140-2 only and conflicts with
Go's native FIPS 140-3 module.

- **Added** a new environment variable `PILOT_ENABLE_REMOTE_CREDENTIALS_CONTROLLER` (default `true`) which toggles credential controllers for remote clusters.

- **Fixed** pilot-agent missing certificate reloads on second and subsequent Kubernetes secret rotations for file-mounted certs.
  ([Issue #59912](https://github.com/istio/istio/issues/59912))

- **Fixed** an issue where `caCertificateRefs[].kind: Secret` in Gateway API frontend mTLS (`spec.tls.frontend.default.validation.caCertificateRefs`) was rejected by SDS at runtime despite valid Gateway configuration, including same-namespace references and cross-namespace references allowed by `ReferenceGrant`
  ([Issue #60277](https://github.com/istio/istio/issues/60277))

- **Fixed** an `EnvoyFilter` validation gap where an uncapped `proxyVersion` match expression
could drive excessive istiod memory and CPU during regex compilation. The match expression
is now limited to 1024 characters.

**Credit**: This issue was reported by Artem Cherezov ([cherez0ff](https://github.com/cherez0ff)).

- **Fixed** external SDS providers configured through `extensionProviders` to use the configured service hostname
as the gRPC authority.

- **Fixed** external SDS provider for gateways to use the credential name (after stripping the `sds://`
prefix) as the SDS resource name instead of the provider name. This allows multiple gateways using the
same SDS provider to request different certificates. For MUTUAL TLS, the CA certificate resource name
is correctly derived as `<credential-name>-cacert`. When neither a UDS socket nor an SDS extension
provider is configured, the gateway now falls back to fetching certificates via ADS (Kubernetes Secrets)
instead of failing silently.
  ([Issue #57080](https://github.com/istio/istio/issues/57080))

- **Fixed** a bug where istiod did not reload its CA root certificate when it rotated if the
certificate is provided via files (for example, when using an external CA such as istio-csr).

- **Fixed** the XDS `api` generator (MCP config serving) to require a verified control-plane identity.
Previously any client that could reach istiod's XDS port could read Istio config across all namespaces.
Disable with ENABLE_XDS_API_GENERATOR_AUTH=false if needed for compatibility.

## Telemetry

- **Improved** the pilot-agent's `/stats/prometheus` endpoint to concurrently scrape
multiple targets declared by the `prometheus.istio.io/scrape-targets` annotation and
merge the output in the declared order. Single-target pods keep the existing
streaming code path byte-for-byte. For multi-target pods, OpenMetrics responses are
rewritten so the merged output contains exactly one `# EOF` terminator. Individual
target metrics responses are capped at 10 MiB to bound agent memory; responses
exceeding this limit are dropped and counted as scrape failures. Per-target scrape
failures are non-blocking and increment
`istio_agent_scrape_failures_total{type="application"}`.
  ([Issue #59567](https://github.com/istio/istio/issues/59567))

- **Added** a new environment variable `PILOT_AGENT_MERGE_ENVOY_STATS` to control whether pilot-agent merges Envoy stats
into its stats endpoint. Set to `false` to disable merging Envoy stats with agent stats.

- **Added** a new metric, `istio_cni_plugin_requests_total`, to the istio-cni node agent. It counts CNI plugin
add-event requests handled by the node agent, labeled by `response_code`.
  ([Issue #60878](https://github.com/istio/istio/pull/60878))

- **Added** a new pod annotation `prometheus.istio.io/scrape-targets` that lets users
declare multiple application-metrics endpoints per pod as a comma-separated
`port:path` list. Targets colliding with the agent status port or any Istio-reserved
data-plane port are rejected at injection time with a human-readable error.
  ([Issue #59567](https://github.com/istio/istio/issues/59567))

- **Added** Two new opt-in environment variables, `ENVOY_SECURE_METRICS_PORT` and `ENVOY_SECURE_MERGED_METRICS_PORT`,
that expose mTLS-protected Prometheus scrape endpoints on every Envoy sidecar proxy.
When set, the sidecar adds static bootstrap listeners on the configured ports that require
mutual TLS, allowing Prometheus to scrape metrics securely without relying on pod-network-level access controls.
See the [RFC](https://docs.google.com/document/d/1BiBOrYU06x5xdsnU0YDlMGOV-iHjZ2m9UVcZ62wKAn8/edit?usp=sharing) for details.
  ([Issue #50114](https://github.com/istio/istio/issues/50114))

- **Fixed** an issue when pilot-agent metric merging produces incorrect result when Envoy reports metrics using protobuf
content type. The logic currently implemented in pilot-agent cannot handle protobuf content type correctly, so the change
restrict allowed content types to text/plain and application/openmetrics-text only.
  ([Issue #60322](https://github.com/istio/istio/issues/60322))

- **Removed** the `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` feature flag. The behavior of spawning
upstream spans for gateway requests is now always enabled. Users who previously set this to
`false` should remove that configuration, as it will no longer have any effect.

## Extensibility

- **Fixed** a bug where a Service referring to a Waypoint in a different namespace did not have the namespace wide Telemetry resource included as part of its configuration.
  ([Issue #60665](https://github.com/istio/istio/issues/60665))

- **Fixed** a bug where a `WasmPlugin` in an application namespace targeting a `Service` via `targetRefs`
would cause a waypoint proxy to crash-loop on startup. The LDS path correctly included the plugin for
the waypoint, but the ECDS lookup path rejected it as cross-namespace, leaving Envoy waiting for a
resource that would never arrive.
  ([Issue #60530](https://github.com/istio/istio/issues/60530))

## Installation

- **Updated** Kiali addon to version v2.26.0.

- **Added** `ZTUNNEL_RESOURCE_CPU_LIMIT` and `ZTUNNEL_RESOURCE_CPU_REQUEST`
environment variables to the ztunnel DaemonSet, populated from the
configured `resources.limits.cpu` / `resources.requests.cpu` when set.
ztunnel uses these to derive CPU-aware worker-thread counts.

- **Added** `terminationMessagePolicy` helm field for the istiod (pilot) container, allowing configuration of how termination messages are populated.

- **Added** `dnsPolicy` and `dnsConfig` fields to the gateway Helm chart for custom DNS configuration in environments with non-standard DNS requirements.

- **Added** an `-o/--output` flag to `istioctl manifest generate` that writes
the generated manifest to a file instead of stdout. This avoids relying on
shell redirection, which is convenient for automation and required in
environments where no shell is available (for example, hardened `istioctl`
images that ship without one).

- **Added** `values.global.readerServiceAccount` with `name` and `namespace` fields to bind
the `istio-reader` ClusterRole to a custom service account. When set, the default
`istio-reader-service-account` is not created, and the ClusterRoleBinding references the
specified service account instead. Setting `global.enableReaderRBAC` to `false` suppresses
the `istio-reader` ClusterRole and ClusterRoleBinding regardless of `readerServiceAccount` settings.

- **Fixed** an issue where the `istio-init` container would use the wrong image when `global.proxy_init.image` and `global.proxy.image` were configured differently.
  ([Issue #59066](https://github.com/istio/istio/issues/59066))

- **Fixed** Waypoint and kube-gateway workload-socket volume incompatible with SPIRE CSI driver configuration.
  ([Issue #60108](https://github.com/istio/istio/issues/60108))

- **Fixed** Helm chart rendering when `global.istioNamespace` or the release namespace is numeric-only (for example, `1234`). Namespace fields in rendered manifests are now quoted so YAML parsers treat them as strings instead of numbers.
  ([Issue #60239](https://github.com/istio/istio/issues/60239))

## istioctl

- **Added** support for `istioctl remote-clusters` to display revisions.

- **Added** `istioctl analyze` now warns (IST0177) when multiple ServiceEntries define the same host and port with conflicting protocols.
  ([Issue #60447](https://github.com/istio/istio/issues/60447))

- **Added** `istioctl analyze` check `IST0176` that flags Gateway API CRDs installed at a
version below the minimum required by the current Istio version. Resources backed by such
CRDs are silently filtered by istiod, which previously made TLS passthrough breakage after
upgrading to Istio 1.30 with stale Gateway API CRDs hard to discover.

- **Fixed** `istioctl` failing to discover istiod when Istio is installed in a non-default namespace
(other than `istio-system`) with a revision tag. The `DefaultWatcher` now constructs the expected
webhook name based on the Istio namespace passed via the `-i` flag.
  ([Issue #60232](https://github.com/istio/istio/issues/60232))

- **Fixed** `istioctl tag remove` not deleting the `istiod-default-validator` ValidatingWebhookConfiguration when removing the default revision tag.
  ([Issue #60537](https://github.com/istio/istio/issues/60537))

- **Fixed** an issue where `istioctl` manifest `--set` values containing `=` were parsed as malformed input.

## Documentation changes
