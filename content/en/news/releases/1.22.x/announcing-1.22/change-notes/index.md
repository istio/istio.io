---
title: Istio 1.22.0 Change Notes
linktitle: 1.22.0
subtitle: Minor Release
description: Istio 1.22.0 release notes.
publishdate: 2024-05-13
release: 1.22.0
weight: 10
aliases:
    - /news/announcing-1.22.0
---

## Deprecation Notices

These notices describe functionality that will be removed in a future release according to [Istio's deprecation policy](/docs/releases/feature-stages/#feature-phase-definition). Please consider upgrading your environment to remove the deprecated functionality.

- **Deprecated** usage of `values.istio_cni` in favor of `values.pilot.cni`.
  ([Issue #49290](https://github.com/istio/istio/issues/49290))

## Traffic Management

- **Improved** `ServiceEntry` with `resolution: NONE` to respect `targetPort`, if specified.
  This is particularly useful when doing TLS origination, allowing to set `port:80, targetPort: 443`.
  If undesired, set `--compatibilityVersion=1.21` to revert to the old behavior or remove the `targetPort` specification.

- **Added** support for skipping the initial installation of the CNI entirely.

- **Added** a node taint controller to istiod which removes the `cni.istio.io/not-ready` taint from a node once the Istio CNI pod is ready on that node.
  ([Issue #48818](https://github.com/istio/istio/issues/48818)),([Issue #48286](https://github.com/istio/istio/issues/48286))

- **Added** endpoints acked generation to the proxy distribution report available through the pilot debug API `/debug/config_distribution`.
  ([Issue #48985](https://github.com/istio/istio/issues/48985))

- **Added** support for configuring waypoint proxies for Services.

- **Added** capability to annotate pods, services, namespaces and other similar kinds with an annotation, `istio.io/use-waypoint`, to specify a waypoint in the form `[<namespace name>/]<waypoint name>`. This replaces the old requirement for waypoints either being scoped to the entire namespace or to a single service account. Opting out of a waypoint can also be done with a value of `#none` to allow a namespace-wide waypoint where specific pods or services are not guarded by a waypoint allowing greater flexibility in waypoint specification and use.
  ([Issue #49436](https://github.com/istio/istio/issues/49436))

- **Added** support for the `istio.io/waypoint-for` annotations in waypoint proxies.
  ([Issue #49851](https://github.com/istio/istio/issues/49851))

- **Added** a check to prevent creation of ztunnel config when user has specified a gateway as `targetRef` in their AuthorizationPolicy.
  ([Issue #50110](https://github.com/istio/istio/issues/50110))

- **Added** the annotation `networking.istio.io/address-type` to allow `istio` class Gateways to use `ClusterIP` for status addresses.

- **Added** the ability to annotate workloads or services with `istio.io/use-waypoint` pointing to Gateways of arbitrary gateway classes.
  These changes allow configuring a standard Istio gateway as a waypoint.
  For this to work, it must be configured as a `ClusterIP` Service with
  redirection enabled. This is colloquially referred to as a "gateway
  sandwich" where the ztunnel layer handles mTLS.
  ([Issue #48362](https://github.com/istio/istio/issues/48362))

- **Added** functionality to enroll individual pods into ambient by labeling them with `istio.io/dataplane-mode=ambient`.
  ([Issue #50355](https://github.com/istio/istio/issues/50355))

- **Added** the ability to allow pods to be opted out of ambient redirection by using the `istio.io/dataplane-mode=none` label.
  ([Issue #50736](https://github.com/istio/istio/issues/50736))

- **Removed** the ability to opt-out pods from ambient redirection using the `ambient.istio.io/redirection=disabled` annotation, as that is a status annotation reserved for the CNI.
  ([Issue #50736](https://github.com/istio/istio/issues/50736))

- **Added** an environment variable for istiod `PILOT_GATEWAY_API_DEFAULT_GATEWAYCLASS_NAME` that allows overriding the name of the default `GatewayClass` Gateway API resource. The default value is `istio`.

- **Added** an environment variable for istiod `PILOT_GATEWAY_API_CONTROLLER_NAME` that allows overriding the name of the Istio Gateway API controller as exposed in the `spec.controllerName` field in the `GatewayClass` resource. The default value is `istio.io/gateway-controller`.

- **Added** support for using the PROXY Protocol for outbound traffic. By specifying `proxyProtocol` in a `DestinationRule.trafficPolicy`,
  the sidecar will send PROXY Protocol headers to the upstream service. This feature is not supported with HBONE proxy for now.

- **Added** validation checks to reject `DestinationRules` with duplicate subset names.

- **Added** field `supportedFeatures` on a Gateway API's class status before the controller accepts the Gateway class.
  ([Issue #2162](https://github.com/kubernetes-sigs/gateway-api/issues/2162))

- **Added** checking services' `Resolution`, `LabelSelector`, `ServiceRegistry`, and namespace when merging services during `SidecarScope` construction.

- **Enabled** [Delta xDS](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds) by default. See upgrade notes for more information.
  ([Issue #47949](https://github.com/istio/istio/issues/47949))

- **Fixed** an issue where the Kubernetes gateway was not working correctly with the namespace-scoped waypoint proxy.

- **Fixed** an issue where the delta ADS client received a response which contained `RemoveResources`.

- **Fixed** an issue that when using `withoutHeaders` to configure route matching rules in `VirtualService`.
  If the fields specified in `withoutHeaders` do not exist in the request header, Istio cannot match the request.
  ([Issue #49537](https://github.com/istio/istio/issues/49537))

- **Fixed** an issue where the priority of envoy filters is ignored when they are in root namespace and proxy namespace.
  ([Issue #49555](https://github.com/istio/istio/issues/49555))

- **Fixed** an issue where `--log_as_json` option did not work for the `istio-init` container.
  ([Issue #44352](https://github.com/istio/istio/issues/44352))

- **Fixed** an issue with massive Virtual IPs reshuffling when adding or removing a duplicated host.
  ([Issue #49965](https://github.com/istio/istio/issues/49965))

- **Fixed** Gateway status addresses receiving Service VIPs from outside the cluster.

- **Fixed** annotation `use-waypoint` to be a label, for consistency.
  ([Issue #50572](https://github.com/istio/istio/issues/50572))

- **Fixed** build EDS-typed cluster endpoints with domain address.
  ([Issue #50688](https://github.com/istio/istio/issues/50688))

- **Fixed** a bug where injection template incorrectly evaluated when `InboundTrafficPolicy` was set to "localhost".
  ([Issue #50700](https://github.com/istio/istio/issues/50700))

- **Fixed** added server-side keepalive to waypoint HBONE endpoints.
  ([Issue #50737](https://github.com/istio/istio/issues/50737))

- **Fixed** empty prefix match in `HTTPMatchRequest` not being rejected by the validating webhook.
  ([Issue #48534](https://github.com/istio/istio/issues/48534))

- **Fixed** a behavioral change in Istio 1.20 that caused merging of `ServiceEntries` with the same hostname and port names
  to give unexpected results.
  ([Issue #50478](https://github.com/istio/istio/issues/50478))

- **Fixed** a bug when a Sidecar resource not merging ports correctly when it is configured with multiple egress listeners with different ports of a Kubernetes service. This lead to creating only one Cluster with the first port, and the second port was ignored.

- **Fixed** an issue causing routes to be overwritten by other virtual services.

- **Removed** the `values.cni.privileged` flag from `istio-cni` node agent chart in favor of feature-specific permissions.
  ([Issue #49004](https://github.com/istio/istio/issues/49004))

- **Removed** the `PILOT_ENABLE_HEADLESS_SERVICE_POD_LISTENERS` feature flag.

- **Removed** the `PILOT_ENABLE_INBOUND_PASSTHROUGH` setting, which has been enabled-by-default for the past 8 releases.
  This feature can now be configured using a new [Inbound Traffic Policy Mode](https://github.com/istio/api/blob/9911a0a6990a18a45ed1b00559156dcc7e836e52/mesh/v1alpha1/config.proto#L203).

## Security

- **Updated** the default value of the feature flag `ENABLE_AUTO_ENHANCED_RESOURCE_SCOPING` to `true`.

- **Added** support for path templating in `AuthorizationPolicy`. See Envoy URI template [docs](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/path/match/uri_template/v3/uri_template_match.proto).
  ([Issue #16585](https://github.com/istio/istio/issues/16585))

- **Added** support for customizing the connection timeout setting when resolving `jwksUri`.
  ([Issue #47328](https://github.com/istio/istio/issues/47328))

- **Added** support for Istio CA to handle node authorization for CSRs with impersonating the identity of remote clusters.
  This could help Istio CA to authenticate ztunnel in remote clusters in an external control plane scenario.
    ([Issue #47489](https://github.com/istio/istio/issues/47489))

- **Added** an environment variable `METRICS_LOCALHOST_ACCESS_ONLY` for disabling metrics endpoint from outside of the pod, to allow only localhost access. User can set this with command arguments
  `--set values.pilot.env.METRICS_LOCALHOST_ACCESS_ONLY=true` for control plane and `--set meshConfig.defaultConfig.proxyMetadata.METRICS_LOCALHOST_ACCESS_ONLY=true` for proxy during `istioctl` installation.

- **Added** Certificate Revocation List (CRL) support for peer certificate validation based on file paths specified in `ClientTLSSettings` in destination rule for Sidecars, and in `ServerTLSSettings` in Gateway for Gateways.

- **Fixed** list matching for the audience claims in JWT tokens.
  ([Issue #49913](https://github.com/istio/istio/issues/49913))

- **Removed** the `first-party-jwt` legacy option for `values.global.jwtPolicy`. Support for the more secure `third-party-jwt`
  has been default for many years and is supported in all Kubernetes platforms.

## Telemetry

- **Improved** JSON access logs to emit keys in a consistent order.

- **Added** option to export OpenTelemetry traces via HTTP.
  ([reference]( https://istio.io/latest/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider)) ([Issue #47835](https://github.com/istio/istio/issues/47835))

- **Enabled** configuring Dynatrace Sampler as the `OpenTelemetryTracingProvider` in `MeshConfig`.
  ([Issue #50001](https://github.com/istio/istio/issues/50001))

- **Enabled** configuring Resource Detectors as the `OpenTelemetryTracingProvider` in `MeshConfig`.
  ([Issue #48885](https://github.com/istio/istio/issues/48885))

- **Fixed** an issue where `TraceId` was not propagated when using OpenTelemetry access logger.
  ([Issue #49911](https://github.com/istio/istio/issues/49911))

- **Removed** default tracing configuration that enables tracing to `zipkin.istio-system.svc`. See upgrade notes for more information.

## Extensibility

- **Improved** using the tag-stripped URL and checksum as a Wasm module cache key, where the tagged URL is separately cached.
  This may increase the chance of cache hits (e.g., trying to find the same image with both of the tagged and digest URLs.)
  In addition, this will be a base to implement `ImagePullPolicy`.

## Installation

- **Improved** Helm value field names to configure whether an existing CNI install
  will be used. Instead of `values.istio_cni` the enablement fields will be in
  `values.pilot.cni`, as istiod is the affected component.
  The new setting is more clear than having `values.cni` for install config and `values.istio_cni`
  for enablement in istiod. The old `values.istio_cni` fields will still be supported
  for at least two releases.
  ([Issue #49290](https://github.com/istio/istio/issues/49290))

- **Improved** the `meshConfig.defaultConfig.proxyMetadata` field to do a deep merge when overridden, rather than replacing all values.

- **Added** the ability to add customized annotations to istiod service account resource through the Helm chart.

- **Added** the `openshift-ambient` profile.
  ([Issue #42341](https://github.com/istio/istio/issues/42341))

- **Added** a new, optional experimental admission policy that only allows stable features/fields to be used in Istio APIs.
  ([Issue #173](https://github.com/istio/enhancements/issues/173))

- **Added** support for configuring CA bundles for validation and injection webhooks.

- **Fixed** gathering `pprof` data from the local ztunnel admin endpoint, which would fail due to the lack of a writable in-container `/tmp`.
  ([Issue #50060](https://github.com/istio/istio/issues/50060))

- **Removed** deprecated `external` profile. Please use the `remote` profile instead for installation.
  ([Issue #48634](https://github.com/istio/istio/issues/48634))

## istioctl

- **Added** the `istioctl proxy-status` command, which is the promoted `istioctl experimental proxy-status` command. The old `istioctl proxy-status` command has been removed.
  This promotion should not result in any loss of functionality. However, the request is now sent based on xDS instead of HTTP, and we have introduced a set of new xDS-based flags to target the control plane.

- **Added** support for multi-cluster analysis in `istioctl analyze` command when there are remote cluster secrets set up through [Install Multicluster](/docs/setup/install/multicluster/).

- **Added** a new `istioctl dashboard proxy` command, which can be used to show the admin UI of different proxy pods, for example: Envoy, ztunnel, and waypoint.

- **Added** the `--proxy` option to `istioctl experimental wait` command.
  ([Issue #48696](https://github.com/istio/istio/issues/48696))

- **Added** namespace filtering to `istioctl proxy-config workload` command using the `--workloads-namespace` flag to display workloads in the specified namespace.

- **Added** the `istioctl dashboard istio-debug` command to display the Istio debug endpoints dashboard.

- **Added** the `istioctl experimental describe` command to support displaying the details of policies for `PortLevelSettings`.
  ([Issue #49802](https://github.com/istio/istio/issues/49802))

- **Added** ability to define the traffic address type (service, workload, all or none) for waypoints via the `--for` flag when using the `istioctl experimental waypoint apply` command.
  ([Issue #49896](https://github.com/istio/istio/issues/49896))

- **Added** the ability to name waypoints through `istioctl` via the `--name` flag on the waypoint command.
  ([Issue #49915](https://github.com/istio/istio/issues/49915)), ([Issue #50173](https://github.com/istio/istio/issues/50173))

- **Removed** the ability to specify a service account for the waypoint by deleting the `--service-account` flag on the waypoint command.
  ([Issue #49915](https://github.com/istio/istio/issues/49915)), ([Issue #50173](https://github.com/istio/istio/issues/50173))

- **Added** the ability to enroll a waypoint proxy in the waypoint's namespace through `istioctl` via the `--enroll-namespace` flag on the waypoint command.
  ([Issue #50248](https://github.com/istio/istio/issues/50248))

- **Added** the `istioctl ztunnel-config` command. This allow users to view ztunnel configuration information via the `istioctl ztunnel-config workload` command.
  ([Issue #49841](https://github.com/istio/istio/issues/49841))

- **Removed** the workload flag from proxy-config command. Use `istioctl ztunnel-config workload` command to view ztunnel configuration information instead.
  ([Issue #49841](https://github.com/istio/istio/issues/49841))

- **Added** a warning when using `istioctl experimental waypoint apply --enroll-namespace` and the namespace is not labeled for ambient redirection.
  ([Issue #50396](https://github.com/istio/istio/issues/50396))

- **Added** the `--for` flag to `istioctl experimental waypoint generate` command so that the user can preview the YAML before they apply it.
  ([Issue #50790](https://github.com/istio/istio/issues/50790))

- **Added** an experimental OpenShift Kubernetes platform profile to `istioctl`. To install with the OpenShift profile, use `istioctl install --set profile=openshift`.
  See [OpenShift Platform Setup]( https://istio.io/docs/setup/platform-setup/openshift/) and [Install OpenShift using `istioctl`]( https://istio.io/docs/setup/install/istioctl/#install-a-different-profile) documents for more information.

- **Added** the flag `--proxy-admin-port` to the command `istioctl experimental envoy-stats` to set a custom proxy admin port.

- **Fixed** an issue where the `istioctl experimental proxy-status <pod>` compare command was not working due to unknown configs.

- **Fixed** the `istioctl describe` command not displaying Ingress information under non `istio-system` namespaces.
  ([Issue #50074](https://github.com/istio/istio/issues/50074))
