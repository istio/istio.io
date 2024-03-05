---
title: Istio 1.21.0 Change Notes
linktitle: 1.21.0
subtitle: Minor Release
description: Istio 1.21.0 release notes.
publishdate: 2024-02-28
release: 1.21.0
weight: 10
aliases:
    - /news/announcing-1.21.0
---

## Traffic Management

- **Improved** pilot-agent to return the HTTP probe body and status code from the probe setting in the container.

- **Improved** support for `ExternalName` services. See Upgrade Notes for more information.

- **Improved** the variables `PILOT_MAX_REQUESTS_PER_SECOND` (which rate limits the incoming requests, previously defaulted to 25.0)
and `PILOT_PUSH_THROTTLE` (which limits the number of concurrent responses, previously defaulted to 100) to automatically scale with the
CPU size Istiod is running on if not explicitly configured.

- **Added** the ability to configure the IPv4 loopback CIDR used by `istio-iptables` in various firewall rules.
([Issue #47211](https://github.com/istio/istio/issues/47211))

- **Added** support for automatically setting default network for workloads if they are added to the ambient mesh before the network topology is set.
Before, when you set `topology.istio.io/network` on your Istio root namespace, you needed to manually rollout the ambient workloads to make the network change take effect.
Now, the network of ambient workloads will be automatically updated even if they do not have a network label.
Note that if your ztunnel is not in the same network as what you set in the `topology.istio.io/network` label in your Istio
root namespace, your ambient workloads will not be able to communicate with each other.

- **Added** namespace discovery selector support on gateway deployment controller. It is protected under `ENABLE_ENHANCED_RESOURCE_SCOPING`.
When enabled, the gateway controller will only watch the k8s gateways that match the selector. Note it will affect both gateway and waypoint deployment.

- **Added** support for the delta ADS client.

- **Added** support for concurrent `SidecarScope` conversion. You can use `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY` to adjust the number of concurrent executions.
Its default value is 1 and will not be executed concurrently.
When `initSidecarScopes` consumes a lot of time and you want to reduce time consumption by increasing CPU consumption,
you can increase the number of concurrent executions by increasing the value of `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY`.

- **Added** support for setting the `:authority` header in virtual service's `HTTPRouteDestination`. Now, we support host rewrite for both `host` and `:authority`.

- **Added** prefixes to the `WasmPlugin` resource name.

- **Added** support for setting `idle_timeout` in `TcpProxy` filters for outbound traffic.

- **Added** support for [In-Cluster Gateway Deployments](https://gateway-api.sigs.k8s.io/geps/gep-1762/).
Deployments now have both `istio.io/gateway-name` and `gateway.networking.k8s.io/gateway-name` labels like Pods and Services.

- **Added** support for max concurrent streams settings in the `DestinationRule`s HTTP traffic policy for HTTP2 connections.
([Issue #47166](https://github.com/istio/istio/issues/47166))

- **Added** support for setting TCP idle timeout for HTTP services.

- **Added** connection pool settings to the `Sidecar` API to enable configuring the inbound connection pool for sidecars in the mesh. Previously, the `DestinationRule`'s connection pool settings applied to both client and server sidecars. Using the updated `Sidecar` API, it's now possible to configure the server's connection pool separately from the clients' in the mesh.
([reference]( https://istio.io/latest/docs/reference/config/networking/sidecar/#Sidecar-inbound_connection_pool)) ([Issue #32130](https://github.com/istio/istio/issues/32130)),([Issue #41235](https://github.com/istio/istio/issues/41235))

- **Added** `idle_timeout` to the TCP settings in the `DestinationRule` API to enable configuring idle timeout per `TcpProxy` filter.

- **Enabled** the Envoy configuration to use an endpoint cache when there is a delay in sending endpoint configurations from Istiod when a cluster is updated.

- **Fixed** a bug where overlapping wildcard hosts in a `VirtualService` would produce incorrect routing configuration when wildcard services were selected (e.g. in `ServiceEntries`).
([Issue #45415](https://github.com/istio/istio/issues/45415))

- **Fixed** an issue where the `WasmPlugin` resource was not correctly applied to the waypoint.
([Issue #47227](https://github.com/istio/istio/issues/47227))

- **Fixed** an issue where sometimes the network of waypoint was not properly configured.

- **Fixed** an issue where the `pilot-agent istio-clean-iptables` command was not able to clean up the iptables rules generated for the Istio DNS proxy.
([Issue #47957](https://github.com/istio/istio/issues/47957))

- **Fixed** slow cleanup of auto-registered `WorkloadEntry` resources when auto-registration and cleanup would occur
shortly after the initial `WorkloadGroup` creation.
([Issue #44640](https://github.com/istio/istio/issues/44640))

- **Fixed** an issue where Istio was performing additional XDS pushes for `StatefulSets`/headless `Service` endpoints while scaling.  ([Issue #48207](https://github.com/istio/istio/issues/48207))

- **Fixed** a memory leak caused when a remote cluster is deleted or `kubeConfig` is rotated.
([Issue #48224](https://github.com/istio/istio/issues/48224))

- **Fixed** an issue where if a `DestinationRule`'s `exportTo` includes a workload's current namespace (not '.'), other namespaces are ignored from `exportTo`.
([Issue #48349](https://github.com/istio/istio/issues/48349))

- **Fixed** an issue where the QUIC listeners were not correctly created when dual-stack is enabled.
([Issue #48336](https://github.com/istio/istio/issues/48336))

- **Fixed** an issue where `convertToEnvoyFilterWrapper` returned an invalid patch that could cause a null pointer exception when it was applied.

- **Fixed** an issue where updating a Service's `targetPort` does not trigger an xDS push.
([Issue #48580](https://github.com/istio/istio/issues/48580))

- **Fixed** an issue where in-cluster analysis was unnecessarily performed when there was no configuration change.
([Issue #48665](https://github.com/istio/istio/issues/48665))

- **Fixed** a bug that results in the incorrect generation of
configurations for pods without associated services, which includes
all services within the same namespace. This can occasionally lead
to conflicting inbound listeners error.

- **Fixed** an issue where new endpoints may not be sent to proxies.
([Issue #48373](https://github.com/istio/istio/issues/48373))

- **Fixed** Gateway API `AllowedRoutes` handling for `NotIn` and `DoesNotExist` label selector match expressions.
([Issue #48044](https://github.com/istio/istio/issues/48044))

- **Fixed** `VirtualService` HTTP header present match not working when `header-name: {}` is set.
([Issue #47341](https://github.com/istio/istio/issues/47341))

- **Fixed** multi-cluster leader election not prioritizing local over remote leader.
([Issue #47901](https://github.com/istio/istio/issues/47901))

- **Fixed** a memory leak when `hostNetwork` Pods scale up and down.
([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Fixed** a memory leak when `WorkloadEntries` change their IP address.
([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Fixed** a memory leak when a `ServiceEntry` is removed.
([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Upgraded** ambient traffic capture and redirection compatibility by switching to an in-pod mechanism.
([Issue #48212](https://github.com/istio/istio/issues/48212))

- **Removed** the `PILOT_ENABLE_INBOUND_PASSTHROUGH` environment variable, which has been enabled-by-default for the past 8 releases.

## Security

- **Improved** request JWT authentication to use the upstream Envoy JWT filter
instead of the custom Istio Proxy filter. Because the new upstream JWT filter
capabilities are needed, the feature is gated for the proxies that support
them. Note that a custom Envoy or Wasm filter that used `istio_authn` dynamic
metadata key needs to be updated to use `envoy.filters.http.jwt_authn`
dynamic metadata key.

- **Updated** the default value of the feature flag `ENABLE_AUTO_SNI` to `true`. If undesired, please use the new `compatibilityVersion` feature to fallback to old behavior.

- **Updated** the default value of the feature flag `VERIFY_CERT_AT_CLIENT` to `true`.
This means server certificates will be automatically verified using the OS CA certificates when not using a `DestinationRule` `caCertificates` field.
If undesired, please use the new `compatibilityVersion` feature to fallback to old behavior, or `insecureSkipVerify`
field in `DestinationRule` to skip the verification.

- **Added** the ability for waypoints to run as non-root.
([Issue #46592](https://github.com/istio/istio/issues/46592))

- **Added** a `fallback` field for `PrivateKeyProvider` to support falling back to the default BoringSSL implementation if the private key provider isn’t available.

- **Added** support to retrieve JWT from cookies.
([Issue #47847](https://github.com/istio/istio/issues/47847))

- **Fixed** a bug that made `PeerAuthentication` too restrictive in
ambient mode.

- **Fixed** an issue where `auto-san-validation` was enabled even
when SNI was explicitly set in the `DestinationRule`.

- **Fixed** an issue where gateways were unable to fetch JWKS from `jwksUri` in `RequestAuthentication` when `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG`
was enabled and `PILOT_JWT_ENABLE_REMOTE_JWKS` was set to
`hybrid`/`true`/`envoy`.

## Telemetry

- **Improved** JSON access logs to emit keys in a stable ordering.

- **Added** support for `brotli`, `gzip`, and `zstd` compression for the Envoy stats endpoint.
([Issue #30987](https://github.com/istio/istio/issues/30987))

- **Added** the `istio.cluster_id` tag to all tracing spans.
([Issue #48336](https://github.com/istio/istio/issues/48336))

- **Fixed** a bug where `destination_cluster` reported by client proxies was occasionally incorrect
when accessing workloads in a different network.

- **Removed** legacy `EnvoyFilter` implementation for Telemetry. For the majority of users, this change has no impact, and
was already enabled in previous releases. However, the following fields are no longer respected: `prometheus.configOverride`,
`stackdriver.configOverride`, `stackdriver.disableOutbound`, `stackdriver.outboundAccessLogging`.

## Extensibility

- **Added** support for outbound traffic using the PROXY Protocol. By specifying `proxyProtocol` in a `DestinationRule` `trafficPolicy`,
the sidecar will send PROXY Protocol headers to the upstream service. This feature is not supported for HBONE proxy at the present time.

- **Added** support for matching `ApplicationProtocols` in an `EnvoyFilter`.

- **Removed** support for the `policy/v1beta1` API version of `PodDisruptionBudget`.

- **Removed** using the `BOOTSTRAP_XDS_AGENT` experimental feature to
apply `BOOTSTRAP` `EnvoyFilter` patches at startup.

## Installation

- **Improved** aborting graceful termination logic if the Envoy
process terminates early.
([Issue #36686](https://github.com/istio/istio/issues/36686))

- **Updated** Kiali addon to version v1.79.0.

- **Added** configurable scaling behavior for Gateway HPA in the Helm chart.
([usage]( https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior))

- **Added** `allocateLoadBalancerNodePorts` config option to the Gateway chart.
([Issue #48751](https://github.com/istio/istio/issues/48751))

- **Added** a message to indicate the default webhook shifting from a revisioned installation to a default installation.
([Issue #48643](https://github.com/istio/istio/issues/48643))

- **Added** the `affinity` field to Istiod Deployment. This field is used to control the scheduling of Istiod pods.

- **Added** `tolerations` field to Istiod Deployment. This field is used to control the scheduling of Istiod pods.

- **Added** support for "profiles" to Helm installation. Try it out with `--set profile=demo`!
  ([Issue #47838](https://github.com/istio/istio/issues/47838))

- **Added** the setting `priorityClassName: system-node-critical` to the ztunnel DaemonSet template to ensure it is running on all nodes.
([Issue #47867](https://github.com/istio/istio/issues/47867))

- **Fixed** an issue where the webhook generated with `istioctl tag set` is unexpectedly removed by the installer.
([Issue #47423](https://github.com/istio/istio/issues/47423))

- **Fixed** an issue where uninstalling Istio didn't prune all the resources created by custom files.
([Issue #47960](https://github.com/istio/istio/issues/47960))

- **Fixed** an issue where injection failed when the name of the Pod or its custom owner exceeded 63 characters.

- **Fixed** an issue causing Istio CNI to stop functioning on minimal/locked down nodes (such as no `sh` binary).
The new logic runs with no external dependencies, and will attempt
to continue if errors are encountered (which could be caused by things
like SELinux rules).
In particular, this fixes running Istio on Bottlerocket nodes.
([Issue #48746](https://github.com/istio/istio/issues/48746))

- **Fixed** custom injection of the `istio-proxy` container not
working on OpenShift because of the way OpenShift sets pods'
`SecurityContext.RunAs` field.

- **Fixed** veth lookup for ztunnel pod on OpenShift where default CNIs
do not create routes for each veth interface.

- **Fixed** an issue where installing with Stackdriver and having
custom configs would lead to Stackdriver not being enabled.

- **Fixed** an issue where Endpoint and Service in the istiod-remote chart did not respect the revision value.
([Issue #47552](https://github.com/istio/istio/issues/47552))

- **Removed** support for `.Values.cni.psp_cluster_role` as part of installation, as `PodSecurityPolicy` was [deprecated](https://kubernetes.io/blog/2021/04/06/podsecuritypolicy-deprecation-past-present-and-future/).

- **Removed** the `istioctl experimental revision` command. Revisions can be inspected by the stable `istioctl tag list` command.

- **Removed** the `installed-state` `IstioOperator` that was created when running `istioctl install`. This previously provided only a snapshot
of what was installed.
However, it was a common source of confusion (as users would change it and nothing would happen), and did not reliably represent the current state.
As there is no `IstioOperator` needed for these usages anymore, `istioctl install` and `helm install` no longer install the `IstioOperator` CRD.
Note this only impacts `istioctl install`, not the in-cluster operator.

## istioctl

- **Improved** injector list to exclude ambient namespaces.

- **Improved** `bug-report` performance by reducing the amount of calls to the k8s API. The pod/node details included in the report will look different, but contain the same information.

- **Improved** `istioctl bug-report` to sort gathered events by creation date.

- **Updated** `verify-install` to not require a IstioOperator file, since it is now removed from the installation process.

- **Added** support for deleting multiple waypoints at once via `istioctl experimental waypoint delete <waypoint1> <waypoint2> ...`.

- **Added** the `--all` flag to `istioctl experimental waypoint delete` to delete all waypoint resources in a given namespace.

- **Added** an analyzer to warn users if they set the `selector` field instead of the `targetRef` field for specific Istio resources, which will cause the resource to be ineffective.
  ([Issue #48273](https://github.com/istio/istio/issues/48273))

- **Added** message IST0167 to warn users that policies, such as Sidecar, will have no impact when applied to ambient namespaces.
  ([Issue #48105](https://github.com/istio/istio/issues/48105))

- **Added** bootstrap summary to all config dumps' summary.

- **Added** completion for Kubernetes pods for some commands that can select pods, such as `istioctl proxy-status <pod>`.

- **Added** `--wait` option to the `istioctl experimental waypoint apply` command.
([Issue #46297](https://github.com/istio/istio/issues/46297))

- **Added** `path_separated_prefix` to the MATCH column in the output of `proxy-config routes` command.

- **Fixed** an issue where sometimes control plane revisions and proxy versions were not obtained in the bug report.

- **Fixed** an issue where `istioctl tag list` command didn't accept `--output` flag.
  ([Issue #47696](https://github.com/istio/istio/issues/47696))

- **Fixed** an issue where the default namespace of Envoy and proxy dashboard command was not set to the actual default namespace.

- **Fixed** an issue where the IST0158 message was incorrectly reported when the `imageType` field was set to `distroless` in mesh config.
  ([Issue #47964](https://github.com/istio/istio/issues/47964))

- **Fixed** an issue where `istioctl experimental version` has no proxy info shown.

- **Fixed** an issue where the IST0158 message was incorrectly reported when the `imageType` field was set by the `ProxyConfig` resource, or the resource annotation `proxy.istio.io/config`.

- **Fixed** an issue where `proxy-config ecds` didn't show all of `EcdsConfigDump`.

- **Fixed** injector list having duplicated namespaces shown for the same injector hook.

- **Fixed** `analyze` not working correctly when analyzing files containing resources that already exist in the cluster.
([Issue #44844](https://github.com/istio/istio/issues/44844))

- **Fixed** `analyze` where it was reporting errors for empty files.
([Issue #45653](https://github.com/istio/istio/issues/45653))

- **Fixed** an issue where the External Control Plane Analyzer was not working in some remote control plane setups.

- **Removed** the `--rps-limit` flag for `istioctl bug-report` and **added** the `--rq-concurrency` flag.
The bug reporter will now limit request concurrency instead of limiting request rate to the Kube
API.

## Documentation changes

- **Fixed** `httpbin` sample manifests to deploy correctly on OpenShift.
