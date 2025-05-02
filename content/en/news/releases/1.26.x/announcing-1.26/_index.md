---
title: Announcing Istio 1.26.0
linktitle: 1.26.0
subtitle: Patch Release
description: Istio 1.26.0 patch release.
publishdate: 2025-05-08
release: 1.26.0
aliases:
    - /news/announcing-1.26
    - /news/announcing-1.26.0
---

{{< warning >}}
This is an automatically generated rough draft of the release notes and has not yet been reviewed.
{{< /warning >}}

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.25.0 and Istio 1.26.0

{{< relnote >}}

## Changes


- **Improved** The CNI agent to no longer require `hostNetwork`, improving compatibility. Dynamic switching to the host network is now performed whenever necessary.
The old behavior can temporarily be restored by setting the `ambient.shareHostNetworkNamespace` field in the `istio-cni` chart.  ([Issue #54726](https://github.com/istio/istio/issues/54726))

- **Improved** iptables binary detection to verify a degree of baseline kernel support exists,
and prefer `nft` in a `tie` situation where both legacy and nft are available, but neither has any rules.
  

- **Improved** installation on GKE. When deploying with `global.platform=gke`, required `ResourceQuota` resources are deployed automatically.
Additionally, when installing via `istioctl`, the `global.platform=gke` setting is automatically enabled when GKE is detected.
In addition to the new `ResourceQuota` resources, this also automatically configures the required `cniBinDir`.
  

- **Improved** the ztunnel Helm chart to no longer set resource names to `.Release.Name`, and instead default to `ztunnel`.
This reverts a change in Istio 1.25.
  

- **Updated** the default value of maximum connections to accept per socket event to 1 as a performance improvement.
 To get the old behavior, you can set `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP` to zero.  

- **Added** experimental support for the v1alpha1 `ClusterTrustBundle` API. This can be enabled by setting `values.pilot.env.ENABLE_CLUSTER_TRUST_BUNDLE_API=true`. Note that you will have to make sure to also enable the respective feature gates in your cluster, see [KEP-3257](https://github.com/kubernetes/enhancements/tree/master/keps/sig-auth/3257-cluster-trust-bundles) for details.
  ([Issue #43986](https://github.com/istio/istio/issues/43986))

- **Added** support to set reinvocationPolicy for the revision-tag webhook when installing Istio with istioctl or Helm.
  

- **Added** support for envoyfilter to match a virtualhost on domain name as well.
  

- **Added** support `omit_empty_values` for `EnvoyFileAccessLog` provider in Telemetry API.
  ([Issue #54930](https://github.com/istio/istio/issues/54930))

- **Added** support `--locality` parameter for `istioctl experimental workload group create`.
  ([Issue #54022](https://github.com/istio/istio/issues/54022))

- **Added** support to run specific analyzer checks using the `istioctl analyze` command.
  

- **Added** Support for configuring service `loadBalancerClass` on the Gateway Helm Chart.  ([Issue #39079](https://github.com/istio/istio/issues/39079))

- - **Added** environment variable `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY`, which separates tracing span for both server and client gateways.
This currently defaults to false but will become default in the future.
  

- **Added** parameter `--tls-server-name` to `istioctl create-remote-secret` that sets `tls-server-name` in the generated kubeconfig.
This flag ensures successful TLS connection to the kube-apiserver when the `server` field is overriden
with the hostname of a gateway proxy.
  

- **Added** a `values` ConfigMap containing the user-provided Helm values for the `istiod` chart, along with the merged values after applying profiles.
  

- **Added** support for reading header values from Istiod environment variables.
  ([Issue #53408](https://github.com/istio/istio/issues/53408))

- **Added** updateStrategy value to ztunnel and istio-cni helm charts
  

- **Added** initial support for the experimental Gateway API `BackendTLSPolicy` and `XBackendTrafficPolicy`.
These are off-by-default and require `PILOT_ENABLE_ALPHA_GATEWAY_API=true` to be enabled.
  ([Issue #54131](https://github.com/istio/istio/issues/54131)),([Issue #54132](https://github.com/istio/istio/issues/54132))

- **Added** support for referencing `ConfigMap`s (rather than just `Secret`s) for `DestinationRule` TLS `SIMPLE` mode.
This is useful when only referencing a CA certificate.
  ([Issue #54131](https://github.com/istio/istio/issues/54131)),([Issue #54132](https://github.com/istio/istio/issues/54132))

- **Added** support for customizations to [Gateway API Automated Deployments](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).
This includes both `istio` Gateway types (used for ingress and egress) as well as `istio-waypoint` Gateway types used for ambient mode waypoints.
Users can now customize arbitrary elements of the generated Service, Deployment, ServiceAccount, HorizontalPodAutoscaler, and PodDisruptionBudget.
  

- **Added** an environment variable `ENABLE_GATEWAY_API_MANUAL_DEPLOYMENT` to istiod that, if set to `false`, will disable the attachment of Gateway API resources to existing gateway deployments. The default setting is `true` to not change existing behavior.  

- **Added** support for `envVarFrom` in `istiod` chart.
  

- **Added** support for configuring retry hosts predicate via Retry API (retry_ignore_previous_hosts).  

- **Added** support for specifying backoff interval during retries.  

- **Added** warn message for deprecated telemetry providers(e.g. Lightstep, Opencensus).
  ([Issue #54002](https://github.com/istio/istio/issues/54002))

- **Added** support for `TCPRoute` to waypoint proxies.
  



- **Fixed** an issue that istioctl analyze report unknown annotation `sidecar.istio.io/statsCompression`.
  ([Issue #52082](https://github.com/istio/istio/issues/52082))

- **Fixed** an issue in the sidecar injection template, which would remove any existing init container, if both traffic intercepting and native sidecar are disabled.
  ([Issue #54562](https://github.com/istio/istio/issues/54562))

- **Fixed** missing `topology.istio.io/network` label on gateway pods when `--set networkGateway` is used.
  ([Issue #54909](https://github.com/istio/istio/issues/54909))

- **Fixed** istioctl error preventing installation when `IstioOperator.components.gateways.ingressGateways.label` or `IstioOperator.components.gateways.ingressGateways.label` is ommitted.
  ([Issue #54955](https://github.com/istio/istio/issues/54955))

- **Fixed** istioctl not using `IstioOperator.components.gateways.ingressGateways.tag` and `IstioOperator.components.gateways.egressGateways.tag` when provided.
  ([Issue #54955](https://github.com/istio/istio/issues/54955))

- **Fixed** an issue where setting `replicaCount=0` in the `istio/gateway` Helm chart incorrectly omitted the `replicas` field instead of explicitly setting it to `0`.
  ([Issue #55092](https://github.com/istio/istio/issues/55092))

- **Fixed** `istioctl waypoint delete` will delete the Gateway resource that is not a waypoint when specifying a name.
  ([Issue #55235](https://github.com/istio/istio/issues/55235))

- **Fixed** `istioctl experimental describe` ignores `--namespace` flag.
  ([Issue #55243](https://github.com/istio/istio/issues/55243))

- **Fixed** `istio.io/waypoint-for` and `istio.io/rev` labels cannot be generated simultaneously when creating Waypoint Proxy with istioctl.
  ([Issue #55437](https://github.com/istio/istio/issues/55437))

- **Fixed** an issue that validation webhook incorrectly report a warning when a ServiceEntry configures `workloadSelector` with DNS resolution.
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **Fixed** an issue ServiceEntry with WorkloadEntry not working in Ambient.
  

- **Fixed** `istioctl admin log` cannot modify the log level of `ingress status`.
  ([Issue #55741](https://github.com/istio/istio/issues/55741))

- **Fixed** an issue where setting `reconcileIptablesOnStartup: true` in the Istioctl YAML failed validation.
  ([Issue #55374](https://github.com/istio/istio/issues/55374))

- **Fixed** an issue that ReferenceGrants don't work when mTLS is enabled for a Gateway Listener.
  ([Issue #55623](https://github.com/istio/istio/issues/55623))

- **Fixed** issue where Istio did not correctly get allowedRoutes for a sandboxed waypoint.   ([Issue #56010](https://github.com/istio/istio/issues/56010))

- **Fixed** an issue where ServiceEntry endpoints are leaked when a pod is evicted.  ([Issue #54997](https://github.com/istio/istio/issues/54997))

- **Fixed** an issue causing file-based certificate references (from `DestinationRule` or `Gateway`) to not work when using SPIRE as the CA.
  


- **Removed** deprecated `ENABLE_AUTO_SNI` flag and related codepaths.
  



## Security update


