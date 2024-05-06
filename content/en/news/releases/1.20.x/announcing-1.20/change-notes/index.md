---
title: Istio 1.20.0 Change Notes
linktitle: 1.20.0
subtitle: Minor Release
description: Istio 1.20.0 change notes.
publishdate: 2023-11-14
release: 1.20.0
weight: 20
---

## Deprecation Notices

These notices describe functionality that will be removed in a future release according
to [Istio's deprecation policy](/docs/releases/feature-stages/#feature-phase-definitions). Please consider upgrading
your
environment to remove the deprecated functionality.

- There are no new deprecations in Istio 1.20.0.

## Traffic Management

- **Improved** support for `ExternalName` services. See the Upgrade Notes for more information.

- **Improved** the ordering of HTTP and TCP envoy filters to enhance consistency.

- **Improved** `iptables` locking. The new implementation uses the built-in `iptables` lock waiting when needed, and
  disables locking entirely when it's not needed.

- **Improved** `WorkloadEntry` resources added inline via the `endpoints` field in `ServiceEntry` resources on different
  networks to no longer require an address to be specified.
  ([Issue #45150](https://github.com/istio/istio/issues/45150))

- **Added** support for traffic mirroring to multiple destinations in `VirtualService`.
  ([Issue #13330](https://github.com/istio/istio/issues/13330))

- **Added** the ability for the user to specify the `ipFamilyPolicy` and `ipFamilies` settings in Istio Service
  resources either via the operator API or the Helm charts.
  ([Issue #44017](https://github.com/istio/istio/issues/44017))

- **Added** support for network `WasmPlugin`.

- **Added** a gated flag `ISTIO_ENABLE_IPV4_OUTBOUND_LISTENER_FOR_IPV6_CLUSTERS` to manage an additional outbound
  listener
  for IPv6-only clusters to handle IPv4 NAT outbound traffic.
  This is useful for IPv6-only cluster environments such as EKS, which manages both egress-only IPv4 and IPv6 IPs.
  ([Issue #46719](https://github.com/istio/istio/issues/46719))

- **Added** the capability to attach `AuthorizationPolicy` to Kubernetes `Gateway` resources via the `targetRef`
  field. ([Issue #46847](https://github.com/istio/istio/issues/46847))

- **Added** support for alternate network namespace paths (for e.g. minikube) via `values.cni.cniNetnsDir`.
  ([Issue #47444](https://github.com/istio/istio/issues/47444))

- **Updated** `failoverPriority` and `failover` to work in conjunction with each other.

- **Fixed** immediate `WorkloadEntry` auto-registration for proxies that are already connected
  when creating a `WorkloadGroup`. ([Issue #45329](https://github.com/istio/istio/issues/45329))

- **Fixed** `ServiceEntry` with DNS resolution for multi-network endpoints to now go through the gateway.
  ([Issue #45506](https://github.com/istio/istio/issues/45506))

- **Fixed** an issue with remote gateways not being recognized in the absence of valid local gateways.
  ([Issue #46435](https://github.com/istio/istio/issues/46435))

- **Fixed** an issue where adding Waypoint proxies could cause traffic disruption.
  ([Issue #46540](https://github.com/istio/istio/issues/46540))

- **Fixed** an issue with reaching multi-network endpoints that are unreachable due to a `DestinationRule` TLS mode
  set to something other than `ISTIO_MUTUAL`.
  ([Issue #46555](https://github.com/istio/istio/issues/46555))

- **Fixed** an issue where Waypoint proxies were missing the `ISTIO_META_NETWORK` field when not configured at install
  time using
  `values.global.network` or overridden with `topology.istio.io/network` on the Kubernetes `Gateway` resource.

- **Fixed** an issue where upstream DNS queries would result in pairs of permanently `UNREPLIED` `conntrack`
  `iptables` entries. ([Issue #46935](https://github.com/istio/istio/issues/46935))

- **Fixed** an issue with auto-allocation assigning incorrect IPs.
  ([Issue #47081](https://github.com/istio/istio/issues/47081))

- **Fixed** an issue where multiple header matches in the root `VirtualService` generated incorrect
  routes. ([Issue #47148](https://github.com/istio/istio/issues/47148))

- **Fixed** DNS Proxy resolution for wildcard `ServiceEntry` with the search domain suffix for glibc-based containers.
  ([Issue #47264](https://github.com/istio/istio/issues/47264)),
  ([Issue #31250](https://github.com/istio/istio/issues/31250)),
  ([Issue #33360](https://github.com/istio/istio/issues/33360)),
  ([Issue #30531](https://github.com/istio/istio/issues/30531)),
  ([Issue #38484](https://github.com/istio/istio/issues/38484))

- **Fixed** an issue relying only on `HTTPRoute` to check `ReferenceGrant`.
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **Fixed** an issue where using a `Sidecar` resource with `IstioIngressListener.defaultEndpoint` could not use [::1]:
  PORT
  if the default IP addressing was not IPv6.
  ([Issue #47412](https://github.com/istio/istio/issues/47412))

- **Fixed** multicluster secret filtering causing Istio to pick up secrets from every namespace.
  ([Issue #47433](https://github.com/istio/istio/issues/47433))

- **Fixed** an issue causing traffic to terminating headless service instances to not function correctly.
  ([Issue #47348](https://github.com/istio/istio/issues/47348))

- **Removed** the `PILOT_ENABLE_DESTINATION_RULE_INHERITANCE` experimental feature, which has been disabled by default
  since it was created.
  ([Issue #37095](https://github.com/istio/istio/issues/37095))

- **Removed** custom Istio network filters `forward_downstream_sni`, `tcp_cluster_rewrite`, and `sni_verifier` from
  the Envoy build. This functionality can be achieved using Wasm extensibility.

- **Removed** the requirement for a workload to have a `Service` associated with it for locality load balancing
  to work.

## Security

- **Added** the capability to attach `RequestAuthentication` to Kubernetes `Gateway` resources via the `targetRef`
  field.

- **Added** support for plugged root cert rotation.

- **Fixed** an issue where all requests were being denied when the custom external authorization service had an issue.
  Now only requests that are delegated to the custom external authorization service are denied.
  ([Issue #46951](https://github.com/istio/istio/issues/46951))

## Telemetry

- **Added** the capability to attach `Telemetry` to Kubernetes `Gateway` resources via the `targetRef`
  field. ([Issue #46844](https://github.com/istio/istio/issues/46844))

- **Added** xDS workload metadata discovery to the TCP metadata exchange filter as a fallback. This requires
  enabling the `PEER_METADATA_DISCOVERY` flag on the proxy and `PILOT_ENABLE_AMBIENT_CONTROLLERS` on the control plane.

- **Added** flag `PILOT_DISABLE_MX_ALPN` on the control plane to disable advertising the TCP metadata exchange ALPN
  token `istio-peer-exchange`.

## Extensibility

- **Added** the capability to attach `WasmPlugin` to Kubernetes `Gateway` resources via the `targetRef` field.

## Installation

- **Improved** Usage on OpenShift clusters by removing the need to grant the `anyuid` SCC privilege to
  Istio and applications.

- **Updated** the Kiali addon to version `v1.76.0`.

- **Added** `volumes` and `volumeMounts` values to the gateways Helm chart.

- **Added** basic revision support to Ztunnel when installing with `istioctl`.
  ([Issue #46421](https://github.com/istio/istio/issues/46421))

- **Added** the `PILOT_ENABLE_GATEWAY_API_GATEWAYCLASS_CONTROLLER` flag to enable/disable management of built-in
  `GatewayClasses`.
  ([Issue #46553](https://github.com/istio/istio/issues/46553))

- **Added** eBPF redirection support for ambient after CNCF established guidance around dual-licensed eBPF bytecode.
  <https://github.com/cncf/foundation/issues/474#issuecomment-1739796978>
  ([Issue #47257](https://github.com/istio/istio/issues/47257))

- **Added** Helm values for easier installation of ambient for users who wish to use Helm.

- **Added** a `startupProbe` by default to the sidecar resource. This optimizes startup time and minimizes load
  throughout the
  pod lifecycle. See the Upgrade Notes for more information.
  ([Issue #32569](https://github.com/istio/istio/issues/32569))

- **Fixed** an issue where resources were being pruned when installing with the `--dry-run` option.

- **Fixed** an issue where installing Istio with the `empty` profile did not display component information.

- **Fixed** an issue where the installation process continued even if a resource failed to be applied, causing
  unexpected behavior.
  ([Issue #43312](https://github.com/istio/istio/issues/43312))

- **Fixed** an issue where Waypoint proxies were not injected with the correct image if `values.global.proxy.image` was
  set to a custom image.

- **Fixed** an issue where sometimes `uninstall` was performed without confirmation when Istiod was not available.

- **Removed** support for installing the `ambient` profile with the in-cluster operator.
  ([Issue #46524](https://github.com/istio/istio/issues/46524))

## istioctl

- **Added** a new `istioctl dashboard proxy` command, which can be used to show the admin UI of different proxy pods,
  like Envoy, Ztunnel, Waypoint.

- **Added** an output format option for the `istioctl experimental precheck` command. Valid options are `log`, `json`
  or `yaml`.

- **Added** the `--output-threshold` flag in `istioctl experimental precheck` to control the message output threshold.
  The default threshold is now `warning`, which replaces the previous default of `info`.

- **Added** support for auto-detecting the pilot's monitoring port if it is not set to the default value of `15014`.
  ([Issue #46652](https://github.com/istio/istio/issues/46652))

- **Added** lazy loading for default namespace detection in `istioctl` to avoid checking the kubeconfig for commands
  that do not require a Kubernetes environment.
  ([Issue #47159](https://github.com/istio/istio/issues/47159))

- **Added** support for setting loggers' levels of istio-proxy in the `istioctl proxy-config log` command
  with `--level <level>` or `--level level=<level>`.

- **Added** an analyzer for showing warning messages about incorrect/missing information related to Istio installations
  using an External Control Plane. ([Issue #47269](https://github.com/istio/istio/issues/47269))

- **Added** IST0162 `GatewayPortNotDefinedOnService` message to detect an issue where a `Gateway` port was not exposed
  by `Service`.

- **Fixed** `istioctl operator remove` command to not remove all revisions of the operator controller when the revision
  is "default" or not specified. ([Issue #45242](https://github.com/istio/istio/issues/45242))

- **Fixed** an issue where `verify-install` had incorrect results when installed deployments were not healthy.

- **Fixed** the `istioctl experimental describe` command to provide correct `Gateway` information when using the
  injected gateway.

- **Fixed** an issue where `istioctl analyze` would analyze irrelevant configmaps.
  ([Issue #46563](https://github.com/istio/istio/issues/46563))

- **Fixed** `istioctl analyze` incorrectly showing an error when `ServiceEntry` hosts are used in a `VirtualService`
  destination across a namespace boundary.
  ([Issue #46597](https://github.com/istio/istio/issues/46597))

- **Fixed** an issue where `istioctl proxy-config` failed to process a config dump from a file if EDS endpoints were not
  provided.
  ([Issue #47505](https://github.com/istio/istio/issues/47505))

- **Removed** the `istioctl experimental revision tag` command, which was graduated to `istioctl tag`.
