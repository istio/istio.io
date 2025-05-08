---
title: Istio 1.26.0 Change Notes
linktitle: 1.26.0
subtitle: Minor Release
description: Istio 1.26.0 release notes.
publishdate: 2025-05-08
release: 1.26.0
weight: 10
aliases:
    - /news/announcing-1.26.0
    - /news/announcing-1.26.x
---

## Traffic Management

* **Improved** the CNI agent to no longer require `hostNetwork`, enhancing compatibility. Dynamic switching to the host network is now performed as needed. The previous behavior can be temporarily restored by setting the `ambient.shareHostNetworkNamespace` field in the `istio-cni` chart. ([Issue #54726](https://github.com/istio/istio/issues/54726))

* **Improved** iptables binary detection to validate baseline kernel support and to prefer `nft` when both legacy and `nft` are available but neither has existing rules.

* **Updated** the default value of maximum connections accepted per socket event to 1 to improve performance. To revert to the previous behavior, set `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP` to zero.

* **Added** the ability for `EnvoyFilter` to match a `VirtualHost` by domain name.

* **Added** initial support for the experimental Gateway API features `BackendTLSPolicy` and `XBackendTrafficPolicy`. These are disabled by default and require setting `PILOT_ENABLE_ALPHA_GATEWAY_API=true`.
  ([Issue #54131](https://github.com/istio/istio/issues/54131)), ([Issue #54132](https://github.com/istio/istio/issues/54132))

* **Added** support for referencing `ConfigMap`s, in addition to `Secret`s, for `DestinationRule` TLS in `SIMPLE` mode — useful when only a CA certificate is required.
  ([Issue #54131](https://github.com/istio/istio/issues/54131)), ([Issue #54132](https://github.com/istio/istio/issues/54132))

* **Added** customization support for [Gateway API automated deployments](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment). This applies to both Istio `Gateway` types (ingress and egress) and Istio Waypoint `Gateway` types (ambient waypoints). Users can now customize generated resources such as `Service`, `Deployment`, `ServiceAccount`, `HorizontalPodAutoscaler`, and `PodDisruptionBudget`.

* **Added** a new environment variable `ENABLE_GATEWAY_API_MANUAL_DEPLOYMENT` for `istiod`. When set to `false`, it disables automatic attachment of Gateway API resources to existing gateway deployments. By default, this is `true` to maintain the current behavior.

* **Added** the ability to configure retry host predicates using the Retry API (`retry_ignore_previous_hosts`).

* **Added** support for specifying backoff intervals during retries.

* **Added** support for using `TCPRoute` in waypoint proxies.

* **Fixed** a bug where the validation webhook incorrectly reported a warning when a `ServiceEntry` configured a `workloadSelector` with DNS resolution.
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

* **Fixed** an issue where FQDNs did not work in a `WorkloadEntry` using ambient mode.

* **Fixed** a case where `ReferenceGrants` did not function when mTLS was enabled on a Gateway listener.
  ([Issue #55623](https://github.com/istio/istio/issues/55623))

* **Fixed** an issue where Istio failed to correctly retrieve `allowedRoutes` for a sandboxed waypoint.
  ([Issue #56010](https://github.com/istio/istio/issues/56010))

* **Fixed** a bug where `ServiceEntry` endpoints were leaked when a pod was evicted.
  ([Issue #54997](https://github.com/istio/istio/issues/54997))

* **Fixed** an issue where the listener address was duplicated for dual stack services with IPv6 priority.  ([Issue #56151](https://github.com/istio/istio/issues/56151))

## Security

* **Added** experimental support for the v1alpha1 `ClusterTrustBundle` API. This can be enabled by setting `values.pilot.env.ENABLE_CLUSTER_TRUST_BUNDLE_API=true`. Ensure the corresponding feature gates are enabled in your cluster; see [KEP-3257](https://github.com/kubernetes/enhancements/tree/master/keps/sig-auth/3257-cluster-trust-bundles) for details.
  ([Issue #43986](https://github.com/istio/istio/issues/43986))

## Telemetry

* **Added** support for the `omit_empty_values` field in the `EnvoyFileAccessLog` provider via the Telemetry API.
  ([Issue #54930](https://github.com/istio/istio/issues/54930))

* **Added** environment variable `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY`, which separates tracing spans for server and client gateways. This currently defaults to `false`, but will become the default in the future.

* **Added** a warning message for use of deprecated telemetry providers Lightstep and OpenCensus.
  ([Issue #54002](https://github.com/istio/istio/issues/54002))

## Installation

* **Improved** the installation experience on GKE. When `global.platform=gke` is set, required `ResourceQuota` resources are deployed automatically. When installing via `istioctl`, this setting is also auto-enabled if GKE is detected. Additionally, the `cniBinDir` is now configured appropriately.

* **Improved** the `ztunnel` Helm chart to not assign resource names to `.Release.Name`, defaulting instead to `ztunnel`. This reverts a change introduced in Istio 1.25.

* **Added** support for setting the `reinvocationPolicy` in the revision-tag webhook when installing Istio via `istioctl` or Helm.

* **Added** the ability to configure the service `loadBalancerClass` in the Gateway Helm chart.
  ([Issue #39079](https://github.com/istio/istio/issues/39079))

* **Added** a values `ConfigMap` that stores both the user-provided Helm values and the merged values after applying profiles for the `istiod` chart.

* **Added** support for reading header values from `istiod` environment variables.
  ([Issue #53408](https://github.com/istio/istio/issues/53408))

* **Added** a configurable `updateStrategy` for the `ztunnel` and `istio-cni` Helm charts.

* **Fixed** a bug in the sidecar injection template that incorrectly removed existing init containers when both traffic interception and native sidecar were disabled.
  ([Issue #54562](https://github.com/istio/istio/issues/54562))

* **Fixed** missing `topology.istio.io/network` labels on gateway pods when `--set networkGateway` is used.
  ([Issue #54909](https://github.com/istio/istio/issues/54909))

* **Fixed** a problem where setting `replicaCount=0` in the `istio/gateway` Helm chart caused the `replicas` field to be omitted instead of explicitly set to `0`.
  ([Issue #55092](https://github.com/istio/istio/issues/55092))

* **Fixed** an issue that caused file-based certificate references (e.g., from `DestinationRule` or `Gateway`) to fail when using SPIRE as the CA.

* **Removed** the deprecated `ENABLE_AUTO_SNI` flag and associated code paths.

## istioctl

* **Added** a `--locality` parameter on `istioctl experimental workload group create`.
  ([Issue #54022](https://github.com/istio/istio/issues/54022))

* **Added** the ability to run specific analyzer checks using the `istioctl analyze` command.

* **Added** a `--tls-server-name` parameter to `istioctl create-remote-secret`, allowing the `tls-server-name` to be set in the generated kubeconfig. This ensures successful TLS connections when the `server` field is overridden with a gateway proxy hostname.

* **Added** support for the `envVarFrom` field in the `istiod` chart.

* **Fixed** an issue where `istioctl analyze` reported an unknown annotation `sidecar.istio.io/statsCompression`.
  ([Issue #52082](https://github.com/istio/istio/issues/52082))

* **Fixed** an error that blocked installation when `IstioOperator.components.gateways.ingressGateways.label` or `IstioOperator.components.gateways.ingressGateways.label` was omitted.
  ([Issue #54955](https://github.com/istio/istio/issues/54955))

* **Fixed** a bug where `istioctl` ignored the `tag` fields under `IstioOperator.components.gateways.ingressGateways` and `egressGateways`.
  ([Issue #54955](https://github.com/istio/istio/issues/54955))

* **Fixed** an issue where `istioctl waypoint delete` could remove a non-waypoint Gateway resource when a name was specified.
  ([Issue #55235](https://github.com/istio/istio/issues/55235))

* **Fixed** an issue where `istioctl experimental describe` did not respect the `--namespace` flag.
  ([Issue #55243](https://github.com/istio/istio/issues/55243))

* **Fixed** a bug that prevented simultaneous generation of `istio.io/waypoint-for` and `istio.io/rev` labels when creating a waypoint proxy using `istioctl`.
  ([Issue #55437](https://github.com/istio/istio/issues/55437))

* **Fixed** an issue where `istioctl admin log` could not modify the log level for `ingress status`.
  ([Issue #55741](https://github.com/istio/istio/issues/55741))

* **Fixed** a validation failure when `reconcileIptablesOnStartup: true` was set in the `istioctl` YAML configuration.
  ([Issue #55347](https://github.com/istio/istio/issues/55347))
