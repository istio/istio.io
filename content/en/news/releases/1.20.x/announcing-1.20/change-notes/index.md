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
to [Istio's deprecation policy](/about/feature-stages/#feature-phase-definitions). Please consider upgrading your
environment to remove the deprecated functionality.

## Traffic Management

- **Improved** support for `ExternalName` services. See Upgrade Notes for more information.


- **Improved** the ordering of HTTP and TCP envoy filters to improve consistency.

- **Improved** `iptables` locking. The new implementation uses `iptables` builtin lock waiting when needed, and disables
  locking entirely when not needed.

- **Added** support traffic mirroring to multiple destinations in VirtualService.
  ([Issue #13330](https://github.com/istio/istio/issues/13330))

- **Added** the ability for the user to specify the `IPFamilyPolicy` and `ipFamilies` setting in Istio Service resources
  either via the operator API or the helm charts.  ([Issue #44017](https://github.com/istio/istio/issues/44017))

- **Added** support for network wasm plugins.

- **Added** Inlined `WorkloadEntry` resources via `endpoints` field on `ServiceEntry` resources on different networks do
  not require an address to be specified.  ([Issue #45150](https://github.com/istio/istio/issues/45150))

- **Added** gated flag `ISTIO_ENABLE_IPV4_OUTBOUND_LISTENER_FOR_IPV6_CLUSTERS` to manage an additional outbound listener
  for IPv6-only clusters to deal with IPv4 NAT outbound traffic.
  This is useful for IPv6-only cluster environments such as EKS which manages both egress-only IPv4 as well as IPv6 IPs.
  ([Issue #46719](https://github.com/istio/istio/issues/46719))

- **Added** the capability to attach `AuthorizationPolicy` to Kubernetes `Gateway` resources via the `targetRef`
  field.  ([Issue #46847](https://github.com/istio/istio/issues/46847))

- **Added** `failoverPriority` and `failover` to work together with each other.


- **Added** Support alternate network namespace paths (for e.g. minikube) via `values.cni.cniNetnsDir`.
  ([Issue #47444](https://github.com/istio/istio/issues/47444))

- **Fixed** when creating a `WorkloadGroup`, `WorkloadEntry` auto-registration will occur immediately for proxies
  that are already connected.  ([Issue #45329](https://github.com/istio/istio/issues/45329))

- **Fixed** When using a ServiceEntry with DNS resolution multi-network endpoints will now go through the gateway.
  ([Issue #45506](https://github.com/istio/istio/issues/45506))

- **Fixed** Remote Gateways not being recognized when valid local gateways are not present.
  Fixes https://github.com/istio/istio/issues/46435.
  ([Issue #46437](https://github.com/istio/istio/issues/46437))

- **Fixed** adding waypoints can cause traffic disruption.
  ([Issue #46540](https://github.com/istio/istio/issues/46540))

- **Fixed** attempting to reach multi-network endpoints that are unreachable due to `DestinationRule` TLS mode
  other than `ISTIO_MUTUAL`.
  ([Issue #46555](https://github.com/istio/istio/issues/46555))

- **Fixed** Waypoints missing the `ISTIO_META_NETWORK` field. It can be configured at install time using
  `values.global.network` or overridden with `topology.istio.io/network` on the Kubernetes `Gateway` resource.

- **Fixed** An issue where upstream DNS queries would result in pairs of permanently UNREPLIED conntrack
  entries.  ([Issue #46935](https://github.com/istio/istio/issues/46935))

- **Fixed** an issue where auto allocation is allocation incorrect ips.
  ([Issue #47081](https://github.com/istio/istio/issues/47081))

- **Fixed** An issue where multiple header matches in root virtual service generates incorrect
  routes.  ([Issue #47148](https://github.com/istio/istio/issues/47148))

- **Fixed** DNS Proxy resolution for wildcard ServiceEntry with the search domain suffix for glibc based containers.
  ([Issue #47290](https://github.com/istio/istio/issues/47290)),([Issue #47264](https://github.com/istio/istio/issues/47264)),([Issue #31250](https://github.com/istio/istio/issues/31250)),([Issue #33360](https://github.com/istio/istio/issues/33360)),([Issue #30531](https://github.com/istio/istio/issues/30531)),([Issue #38484](https://github.com/istio/istio/issues/38484))

- **Fixed** Issue relying only on `HTTPRoute` to check `ReferenceGrant`.
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **Fixed** an issue where using a Sidecar resource using IstioIngressListener.defaultEndpoint cannot use [::1]:PORT if
  the default IP addressing is not IPv6.
  ([Issue #47412](https://github.com/istio/istio/issues/47412))

- **Fixed** Fixed multicluster secret filtering causing Istio to pick up secrets from every namespace.
  ([Issue #47433](https://github.com/istio/istio/issues/47433))

- **Fixed** an issue causing traffic to terminating headless service instances to not function correctly.
  ([Issue #47348](https://github.com/istio/istio/issues/47348))

- **Removed** the `PILOT_ENABLE_DESTINATION_RULE_INHERITANCE` experimental feature, which has been disable-by-default
  since it was created.
  ([Issue #37095](https://github.com/istio/istio/issues/37095))

- **Removed** `forward_downstream_sni`, `tcp_cluster_rewrite`, and `sni_verifier` custom Istio network filters from
  Envoy build. This functionality can be achieved using the Wasm extensibility.

- **Removed** the requirement for a workload to have a Service associated with it in order for locality load balancing
  to work.

## Security

- **Added** the capability to attach RequestAuthentication to Kubernetes `Gateway` resources via the `targetRef` field.

- **Added** support for plugged root cert rotation.

- **Fixed** an issue where all requests were being denied when the custom external authorization service had an issue.
  Now only requests that are delegated to the custom external authorization service are denied.
  ([Issue #46951](https://github.com/istio/istio/issues/46951))

## Telemetry

- **Added** the capability to attach Telemetry to Kubernetes `Gateway` resources via the `targetRef`
  field.  ([Issue #46844](https://github.com/istio/istio/issues/46844))

- **Added** xDS workload metadata discovery to TCP metadata exchange filter as a fallback. This requires
  enabling `PEER_METADATA_DISCOVERY` flag on the proxy, and `PILOT_ENABLE_AMBIENT_CONTROLLERS` on the control plane.

- **Added** a flag `PILOT_DISABLE_MX_ALPN` on the control plane to disable advertising TCP metadata exchange ALPN
  token `istio-peer-exchange`.

## Extensibility

- **Added** the capability to attach `WasmPlugin` to Kubernetes `Gateway` resources via the `targetRef` field.

## Installation

- **Improved** Usage on OpenShift clusters is simplified by removing the need of granting the `anyuid` SCC privilege to
  Istio and applications.

- **Updated** Kiali addon to version v1.76.0.

- **Added** volumes and volumeMounts to the gateways chart.

- **Added** basic ztunnel support for revisions when installing with istioctl.
  ([Issue #46421](https://github.com/istio/istio/issues/46421))

- **Added** env var PILOT_ENABLE_GATEWAY_API_GATEWAYCLASS_CONTROLLER to enable/disable management of built-in
  GatewayClasses.
  ([Issue #46553](https://github.com/istio/istio/issues/46553))

- **Added** eBPF redirection support for ambient after CNCF established guidance around dual-licensed eBPF bytecode.
  https://github.com/cncf/foundation/issues/474#issuecomment-1739796978
  ([Issue #47257](https://github.com/istio/istio/issues/47257))

- **Added** helm values for easier installation of ambient when the user wishes to use Helm.

- **Added** a `startupProbe` by default for the sidecar. This optimizes startup time and minimizes load throughout the
  pod lifecycle. See Upgrade Notes for more information.
  ([Issue #32569](https://github.com/istio/istio/issues/32569))

- **Fixed** an issue where resources are being pruned when installing with the dry-run option.

- **Fixed** an issue where installing Istio with `empty` profile did not have components information displayed.


- **Fixed** an issue where the installation process continued even if a resource failed to be applied, causing
  unexpected behavior.
  ([Issue #43312](https://github.com/istio/istio/issues/43312))

- **Fixed** An issue where waypoint proxies were not injected with the correct image if `values.global.proxy.image` was
  set to a custom image.

- **Fixed** an issue where sometimes `uninstall` was performed without confirmation when istiod was not available to be
  connected.

- **Removed** support for installing `ambient` profile with in-cluster operator.
  ([Issue #46524](https://github.com/istio/istio/issues/46524))

## istioctl

- **Added** a new `istioctl dashboard proxy` command, which can be used to show the admin UI of differnt proxy pods,
  like Envoy, Ztunnel, Waypoint.

- **Added** output format option for `istioctl experimental pre-check` command. Valid options are `log`, `json`
  or `yaml`.

- **Added** `--output-threshold` flag in `istioctl experimental precheck` to control message output threshold.
  Now the default threshold is `warning`, which replaces the previous behavior of `info`.

- **Added** support for auto-detecting the pilot's monitoring port if it is not set to the default value of `15014`.
  ([Issue #46652](https://github.com/istio/istio/issues/46652))

- **Added** lazy loading for default namespace detection in `istioctl` to avoid checking the kube config for commands
  that require no Kubernetes environment.
  ([Issue #47159](https://github.com/istio/istio/issues/47159))

- **Added** support for setting loggers' levels of istio-proxy in `istioctl proxy-config log` command
  with `--level <level>` or `--level level=<level>`.

- **Added** An analyzer for showing warning messages about incorrect/missing information related to Istio installations
  using an External Control Plane.  ([Issue #47269](https://github.com/istio/istio/issues/47269))

- **Added** IST0162 `GatewayPortNotDefinedOnService` message to detect the issue where Gateway port was not exposed by
  Service.

- **Fixed** `istioctl operator remove` will remove all revisions of operator controller when the revision is "default"
  or not specified.  ([Issue #45242](https://github.com/istio/istio/issues/45242))

- **Fixed** an issue where `verify-install` has incorrect results when installed deployments are not healthy.

- **Fixed** `istioctl experimental describe` provides wrong Gateway information when using injected gateway.

- **Fixed** an issue where `istioctl analyze` would analyze irrelevant configmaps.
  ([Issue #46563](https://github.com/istio/istio/issues/46563))

- **Fixed** `istioctl analyze` incorrectly showing an error when ServiceEntry hosts are used in a VirtualService
  destination across namespace boundary.
  ([Issue #46597](https://github.com/istio/istio/issues/46597))

- **Fixed** an issue where `istioctl proxy-config` fails to process a config dump from file if EDS endpoints were not
  provided.
  ([Issue #47505](https://github.com/istio/istio/issues/47505))

- **Removed** `istioctl experimental revision tag` command, which was graduated to `istioctl tag`.

## Documentation changes

- **Fixed** add ambient test framework flag for quick running integration test.
  ([Issue #43508](https://github.com/istio/istio/issues/43508))
