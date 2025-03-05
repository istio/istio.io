---
title: Istio 1.25.0 Change Notes
linktitle: 1.25.0
subtitle: Major Release
description: Istio 1.25.0 release notes.
publishdate: 2025-03-03
release: 1.25.0
weight: 10
aliases:
    - /news/announcing-1.25.0
---

## Deprecation Notices

These notices describe functionality that will be removed in a future release according to [Istio's deprecation policy](/docs/releases/feature-stages/#feature-phase-definition). Please consider upgrading your environment to remove the deprecated functionality.

- **Deprecated** use of `ISTIO_META_DNS_AUTO_ALLOCATE` in `proxyMetadata` in favor of a newer version of [DNS auto-allocation](/docs/ops/configuration/traffic-management/dns-proxy#address-auto-allocation). New users of Istio IP `auto-allocation` should adopt the new status based controller. Existing users may continue to use the older implementation.
  ([Issue #53596](https://github.com/istio/istio/issues/53596))

- **Deprecated** `traffic.sidecar.istio.io/kubevirtInterfaces`, in favor of `istio.io/reroute-virtual-interfaces`.
  ([Issue #49829](https://github.com/istio/istio/issues/49829))

## Traffic Management

- **Promoted** the `cni.ambient.dnsCapture` value to default to `true`.
  This enables the DNS proxying for workloads in ambient mesh by default, improving security, performance, and enabling
  a number of features. This can be disabled explicitly or with `compatibilityVersion=1.24`.
  Note: only new pods will have DNS enabled. To enable for existing pods, pods must be manually restarted, or the iptables reconciliation feature must be enabled with `--set cni.ambient.reconcileIptablesOnStartup=true`.

- **Promoted** the `PILOT_ENABLE_IP_AUTOALLOCATE` value to default to `true`.
  This enables the new iteration of [IP auto-allocation](/docs/ops/configuration/traffic-management/dns-proxy/#address-auto-allocation),
  fixing long-standing issues around allocation instability, ambient support, and increased visibility.
  `ServiceEntry` objects without `spec.address` set will now see a new field, `status.addresses`, automatically set.
  Note: these will not be used unless proxies are configured to do DNS proxying, which remains off-by-default.

- **Updated** the `PILOT_SEND_UNHEALTHY_ENDPOINTS` feature (which is off by default) to not include terminating endpoints.
  This ensures a service is not considered unhealthy during scale down or rollout events.

- **Updated** DNS proxying algorithm to randomly select which upstream to forward DNS requests to.
  ([Issue #53414](https://github.com/istio/istio/issues/53414))

- **Added** new istiod environment variable `PILOT_DNS_JITTER_DURATION` that sets jitter for periodic DNS resolution.
  See `dns_jitter` in `https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto`.
  ([Issue #52877](https://github.com/istio/istio/issues/52877))

- **Added** `ObservedGeneration` to ambient status conditions. This field will show the generation of the object that was observed by the controller when the condition was generated.
  ([Issue #53331](https://github.com/istio/istio/issues/53331))

- **Added** Istiod environment variable `PILOT_DNS_CARES_UDP_MAX_QUERIES` that controls the `udp_max_queries` field of Envoy's default Cares DNS resolver. This value defaults to 100 when unset.
  For more information, see [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/network/dns_resolver/cares/v3/cares_dns_resolver.proto#envoy-v3-api-field-extensions-network-dns-resolver-cares-v3-caresdnsresolverconfig-udp-max-queries)
  ([Issue #53577](https://github.com/istio/istio/issues/53577))

- **Added** support for reconciling in-pod iptables rules of existing ambient pods from the previous version on `istio-cni` upgrade. Feature can be toggled with `--set cni.ambient.reconcileIptablesOnStartup=true`, and will be enabled by default in future releases.
  ([Issue #1360](https://github.com/istio/istio/issues/1360))

- **Added** `istio.io/reroute-virtual-interfaces` annotation, a comma separated list of virtual interfaces whose inbound traffic will be unconditionally treated as outbound. This allows workloads using virtual networking (KubeVirt, VMs, docker-in-docker, etc) to function correctly with both sidecar and ambient mesh traffic capture.

- **Added** support for attaching policy defaults for istio-waypoint by targeting the `GatewayClass`.
  ([Issue #54696](https://github.com/istio/istio/issues/54696))

- **Added** `ambient.istio.io/dns-capture` annotation, which may be unset, or set to `true` or `false`.
  When specified on a `Pod` enrolled in ambient mesh, controls whether DNS traffic (TCP and UDP on port 53) will be captured and proxied in ambient.
  This pod-level annotation, if present on a pod, will override the global `istio-cni` `AMBIENT_DNS_CAPTURE` setting, which as of 1.25 defaults to `true`.
  Note: setting this to `false` will break some Istio features, such as `ServiceEntries` and egress waypoints, but may be desirable for workloads that interact poorly with DNS proxies.
  ([Issue #49829](https://github.com/istio/istio/issues/49829))

- **Added** support for configuring the `istio.io/ingress-use-waypoint` label at the namespace level.

- **Added** support to preserve the original case of HTTP/1.x headers.  ([Issue #53680](https://github.com/istio/istio/issues/53680))

- **Added** support for the `Service.spec.trafficDistribution` field and `networking.istio.io/traffic-distribution` annotation, allowing a simpler mechanism to make traffic prefer geographically close endpoints.
  Note: this feature previously existed only for ztunnel, but is now supported across all data planes.

- **Fixed** a bug with mixed cased Hosts in Gateway and TLS redirect which resulted in stale RDS.  ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **Fixed** an issue where an `HTTPRoute` in a `VirtualService` with a matcher specifying `sourceLabels` would be applied to a waypoint.
  ([Issue #51565](https://github.com/istio/istio/issues/51565))

- **Fixed** an issue where if a WASM image fetch fails, an allow all RBAC filter is used. Now if `failStrategy` is set to `FAIL_CLOSE`, a DENY-ALL RBAC filter will be used.  ([Issue #53279](https://github.com/istio/istio/issues/53279)),([Issue #23624](https://github.com/istio/istio/issues/23624))

- **Fixed** waypoint proxy to respect trust domain.

- **Fixed** an issue where merging `Duration` in an `EnvoyFilter` could lead to all listeners associated attributes unexpectedly being modified because all listeners shared the same pointer type (`listener_filters_timeout`).

- **Fixed** an issue where errors were being raised during cleanup of iptables rules that were conditional.

- **Fixed** a configuration issue so that DNS traffic (UDP and TCP) is now affected by traffic annotations like `traffic.sidecar.istio.io/excludeOutboundIPRanges` and `traffic.sidecar.istio.io/excludeOutboundPorts`. Before, UDP/DNS traffic would uniquely ignore these traffic annotations, even if a DNS port was specified, because of the rule structure. The behavior change actually happened in the 1.23 release series, but was left out of the release notes for 1.23.
  ([Issue #53949](https://github.com/istio/istio/issues/53949))

- **Fixed** an issue where istiod did not handle `RequestAuthentication` correctly for cross-namespace waypoint proxies.  ([Issue #54051](https://github.com/istio/istio/issues/54051))

- **Fixed** an issue that caused patches to a managed gateway/waypoint deployment to fail during upgrade to 1.24.
  ([Issue #54145](https://github.com/istio/istio/issues/54145))

- **Fixed** an issue where non-default revisions controlling gateways lacked `istio.io/rev` labels.
  ([Issue #54280](https://github.com/istio/istio/issues/54280))

- **Fixed** the wording of the status message when L7 rules are present in an `AuthorizationPolicy` which is bound to ztunnel to be more clear.
  ([Issue #54334](https://github.com/istio/istio/issues/54334))

- **Fixed** a bug where request mirror filter incorrectly computed the percentage.
  ([Issue #54357](https://github.com/istio/istio/issues/54357))

- **Fixed** an issue where using a tag in the `istio.io/rev` label on a gateway causes the gateway to be improperly programmed and to lack status.
  ([Issue #54458](https://github.com/istio/istio/issues/54458))

- **Fixed** an issue where out-of-order ztunnel disconnects could put `istio-cni` in a state where it believes it has no connections.
  ([Issue #54544](https://github.com/istio/istio/issues/54544)),([Issue #53843](https://github.com/istio/istio/issues/53843))

- **Fixed** excessive iptables info-level log entries for rule checks and deletions.
  Detailed logging can be re-enabled by switching to debug-level logs, if necessary.
  ([Issue #54644](https://github.com/istio/istio/issues/54644))

- **Fixed** an issue that caused `ExternalName` services to fail to resolve when using ambient mode and DNS proxying.

- **Fixed** an issue causing configuration to be rejected when there is a partial overlap between IP addresses across multiple services.
  For example, a Service with `[IP-A]` and one with `[IP-B, IP-A]`.
  ([Issue #52847](https://github.com/istio/istio/issues/52847))

- **Fixed** an issue causing `VirtualService` header name validation to reject valid header names.

- **Fixed** an issue when upgrading waypoint proxies from Istio 1.23.x to Istio 1.24.x.
  ([Issue #53883](https://github.com/istio/istio/issues/53883))

## Security

- **Added** the `DAC_OVERRIDE` capability to the `istio-cni-node` `DaemonSet`. This fixes issues when running in environments
  where certain files are owned by non-root users.
  Note: prior to Istio 1.24, the `istio-cni-node` ran as `privileged`. Istio 1.24 removed this, but removed some required
  privileges which are now added back. Relatively to Istio 1.23, `istio-cni-node` still has fewer privileges than it does with this change.

- **Added** unconfined AppArmor annotation to the `istio-cni-node` `DaemonSet` to avoid conflicts with
  AppArmor profiles which block certain privileged pod capabilities. Previously, AppArmor
  (when enabled) was bypassed for the `istio-cni-node` `DaemonSet` since privileged was set to true
  in the `SecurityContext`. This change ensures that the AppArmor profile is set to unconfined
  for the `istio-cni-node` `DaemonSet`.

- **Fixed** an issue where ambient `PeerAuthentication` policies were overly strict.
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **Fixed** a possible race conditions in JWK resolution cache for JWT policies that, when triggered, would cause
  cache misses & failures to update signing keys when rotated.
  ([Issue #52121](https://github.com/istio/istio/issues/52121))

- **Fixed** a bug in ambient (only) where multiple `STRICT` port-level mTLS rules in a `PeerAuthentication` policy would effectively result
  in a permissive policy due to incorrect evaluation logic (`AND` vs. `OR`).
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **Fixed** an issue where ingress gateways did not use WDS discovery to retrieve metadata for ambient destinations.

## Telemetry

- **Added** support for additional label exchange for telemetry in sidecar mode.
  ([Issue #54000](https://github.com/istio/istio/issues/54000))

- **Added** a new `service.istio.io/workload-name` label that can be added to a `Pod` or `WorkloadEntry` to override the "workload name" reported in telemetry.

- **Added** a fallback to use the `WorkloadGroup` name as the "workload name" (as reported in telemetry) for `WorkloadEntry`s created by a `WorkloadGroup`.

- **Fixed** `$(HOST_IP)` interpolation causes istio-proxy failures when Datadog tracing enabled on IPv6 clusters.
  ([Issue #54267](https://github.com/istio/istio/issues/54267))

- **Fixed** an issue where access log order instability caused connection draining.
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

- **Fixed** an issue where many panels in the Grafana dashboards showed **No data** if Prometheus had a scrape
  interval configured to be larger than `15s`.
  ([Background information](https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/) and [usage](/docs/tasks/observability/metrics/using-istio-dashboard/))

- **Removed** OpenCensus support.

## Installation

- **Improved** Both `platform` and `profile` Helm values overrides now equivalently support global or local override forms, e.g.
    - `--set global.platform=foo`
    - `--set global.profile=bar`
    - `--set platform=foo`
    - `--set profile=bar`

- **Improved** the ztunnel Helm chart to set resource names to `.Release.Name` instead of being hard-coded to ztunnel.

- **Added** new messages to the `WaypointBound` condition to represent a service binding to a waypoint proxy for ingress.

- **Added** an issue where `istioctl install` not working on Windows.

- **Added** a pod `dnsPolicy` of `ClusterFirstWithHostNet` to `istio-cni` when it runs with `hostNetwork=true` (i.e. ambient mode).

- **Added** GKE platform profile for ambient mode. When installing on GKE, use `--set global.platform=gke` (Helm) or `--set values.global.platform=gke` (istioctl) to apply GKE-specific value overrides. This replaces the previous GKE auto detection based on K8S version used in the `istio-cni` chart.

- **Added** support for Envoy config parameter to skip deprecated logs, with the default set to true. Setting the `ENVOY_SKIP_DEPRECATED_LOGS` environment variable to false will enable deprecated logs.

- **Added** ambient dataplane exclusion labels to Istio-shipped gateways by default, to avoid out-of-the-box confusing behavior if installing gateways outside of `istio-system`.
  ([Issue #54824](https://github.com/istio/istio/issues/54824))

- **Fixed** an issue where `ipset` entry creation would fail on certain kinds of Docker-based Kubernetes nodes.
  ([Issue #53512](https://github.com/istio/istio/issues/53512))

- **Fixed** Helm render to properly apply annotations on pilot `serviceAccount`.
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **Fixed** a issue where `includeInboundPorts: ""` not working when `istio-cni` is enabled.
  ([Issue #54288](https://github.com/istio/istio/issues/54288))

- **Fixed** an issue where the CNI installation left temporary files when a container was repeatedly killed during the binary copy, which could have filled the storage space.
  ([Issue #54311](https://github.com/istio/istio/issues/54311))

- **Fixed** an issue in the gateway chart where `--set platform` worked but `--set global.platform` did not.

- **Fixed** an issue where  `gateway` injection template did not respect the `kubectl.kubernetes.io/default-logs-container`
  and `kubectl.kubernetes.io/default-container` annotations.

- **Fixed** an issue causing the `istio-iptables` command to fail when a non-built-in table is present in the system.

- **Fixed** an issue preventing the `PodDisruptionBudget` `maxUnavailable` field from being customizable.
  ([Issue #54087](https://github.com/istio/istio/issues/54087))

- **Fixed** an issue where injection configuration errors were being silenced (i.e. logged and not returned) when the sidecar injector was unable to process the sidecar config. This change will now propagate the error to the user instead of continuing to process a faulty config.
  ([Issue #53357](https://github.com/istio/istio/issues/53357))

## istioctl

- **Improved** the output of `istioctl proxy-config secret` to display trust bundles provided by Spire.

- **Added** alias `-r` for `--revision` flags in `istioctl analyze`.

- **Added** support for `AuthorizationPolicies` with `CUSTOM` action in the `istioct x authz check` command.

- **Added** support for the `--network` parameter to the `istioctl experimental workload group create` command.
  ([Issue #54022](https://github.com/istio/istio/issues/54022))

- **Added** the ability to safely restart/upgrade the `system-node-critical` `istio-cni` node agent `DaemonSet` in-place. This works by preventing new pods from starting on the node while `istio-cni` is being restarted or upgraded. This feature is enabled by default and can be disabled by setting the environment variable `AMBIENT_DISABLE_SAFE_UPGRADE=true` in `istio-cni`.
  ([Issue #49009](https://github.com/istio/istio/issues/49009))

- **Added** changes for `rootca-compare` command to handle the case when pod has multiple root CA.  ([Issue #54545](https://github.com/istio/istio/issues/54545))

- **Added** support for `istioctl waypoint delete` to delete specified revision waypoints.

- **Added** support for the analyzer to report negative status conditions on select Istio and Kubernetes Gateway API resources.
  ([Issue #55055](https://github.com/istio/istio/issues/55055))

- **Improved** the performance of `istioctl proxy-config secret` and `istioctl proxy-config`.
  ([Issue #53931](https://github.com/istio/istio/issues/53931))

- **Fixed** an issue in the `rootca-compare` command to handle the case when a pod has multiple root CAs.  ([Issue #54545](https://github.com/istio/istio/issues/54545))

- **Fixed** an issue where `istioctl install` deadlocks if multiple ingress gateways are specified in the `IstioOperator` file.
  ([Issue #53875](https://github.com/istio/istio/issues/53875))

- **Fixed** an issue where `istioctl waypoint delete --all` would delete all gateway resources, even non-waypoints.
  ([Issue #54056](https://github.com/istio/istio/issues/54056))

- **Fixed** the `istioctl experimental injector list` command to not print redundant namespaces for injector webhooks.

- **Fixed** `istioctl analyze` reporting `IST0145` errors when using the same host with different ports and multiple gateways.
  ([Issue #54643](https://github.com/istio/istio/issues/54643))

- **Fixed** an issue where `istioctl --as` implicitly set `--as-group=""` when `--as` is used without `--as-group`.

- **Removed** `--recursive` flags and set recursion to true for `istioctl analyze`.

- **Removed** the experimental flag `--xds-via-agents` from the `istioctl proxy-status` command.
