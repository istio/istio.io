---
title: Istio 1.24.0 Change Notes
linktitle: 1.24.0
subtitle: Major Release
description: Istio 1.24.0 release notes.
publishdate: 2024-11-07
release: 1.24.0
weight: 10
aliases:
    - /news/announcing-1.24.0
---

## Ambient mode

- **Added** support for attaching policies to `ServiceEntry` for waypoints.

- **Added** a new annotation, `ambient.istio.io/bypass-inbound-capture`, that can be applied to make ztunnel only capture outbound traffic.
  This can be useful to skip an unnecessary hop for workloads that only accept traffic from out-of-mesh clients (such as internet-facing pods).

- **Added** a new annotation, `networking.istio.io/traffic-distribution`, that can be applied to make ztunnel prefer sending traffic to local pods.
  This behaves the same as the [`spec.trafficDistribution`](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) field on `Service`, but
  allows usage on older Kubernetes versions (as the field was added as beta in Kubernetes 1.31).
  Note that waypoints automatically set this.

- **Fixed** an issue preventing [server first protocols](/docs/ops/deployment/application-requirements/#server-first-protocols) from working with waypoints.

- **Improved** logs from Envoy when connection failures occur in ambient mode to show more error details.

- **Added** support for `Telemetry` customization in the waypoint proxy.

- **Added** writing a status condition for binding AuthorizationPolicy to a waypoint proxy.
  The formatting of conditions is **experimental** and will change.
  Policy with multiple `targetRefs` presently receive a single condition.
  Once a pattern for conditions with multiple references is adopted by upstream Kubernetes Gateway API, Istio will adopt the convention to provide greater detail when multiple `targetRefs` are used.
  ([Issue #52699](https://github.com/istio/istio/issues/52699))

- **Fixed** an issue causing `hostNetwork` pods to function incorrectly in ambient mode.

- **Improved** how ztunnel determines which Pod it is acting on behalf of. Previously, this relied on IP addresses, which was unreliable in some scenarios.

- **Fixed** an issue causing any `portLevelSettings` to be ignored in `DestinationRule` in waypoints.  ([Issue #52532](https://github.com/istio/istio/issues/52532))

- **Fixed** an issue when using mirror policies with waypoints.
  ([Issue #52713](https://github.com/istio/istio/issues/52713))

- **Added** support for `connection.sni` rule in `AuthorizationPolicy` applied to a waypoint.
  ([Issue #52752](https://github.com/istio/istio/issues/52752))

- **Updated** the redirection method used in Ambient from `TPROXY` to `REDIRECT`.
  For most users, this should have no impact, but fixes a few compatibility issues with `TPROXY`.  ([Issue #52260](https://github.com/istio/istio/issues/52260)),([Issue #52576](https://github.com/istio/istio/issues/52576))

## Traffic Management

- **Promoted** Istio dual-stack support to Alpha
  ([Issue #47998](https://github.com/istio/istio/issues/47998))

- **Added** `warmup.aggression`, `warmup.duration`, `warmup.minimumPercent` parameters to `DestinationRule` to provide more control on warmup behavior.
  ([Issue #3215](https://github.com/istio/api/issues/3215))

- **Added** retry policy for inbound requests that automatically resets the requests that the service has not seen/processed.
  It can be reverted by setting `ENABLE_INBOUND_RETRY_POLICY` to false.
  ([Issue #51704](https://github.com/istio/istio/issues/51704))

- **Fixed** default retry policy to exclude retries on 503 which is potentially unsafe for idempotent requests.
  This behavior can be temporarily reverted with `EXCLUDE_UNSAFE_503_FROM_DEFAULT_RETRY=false`.
  ([Issue #50506](https://github.com/istio/istio/issues/50506))

- **Updated** the behavior of XDS generation to be aligned when a user has a `Sidecar` configured and when they do not. See upgrade notes for more information.

- **Improved** Istiod's validation webhook to accept versions it does not know about.
  This ensures that an older Istio can validate resources created by newer CRDs.

- **Improved** support for dual-stack services by associating multiple IPs with one single endpoint, rather than treating them as two distinct endpoints.
  ([Issue #40394](https://github.com/istio/istio/issues/40394))

- **Added** support for matching multiple IPs (for dual-stack services) in HTTP route.

- **Added** `VirtualService` `sourceNamespaces` will now be taken into account when filtering unneeded configuration.

- **Added** support for by passing overload manager for static listeners. This can be reverted by setting
  `BYPASS_OVERLOAD_MANAGER_FOR_STATIC_LISTENERS` to false in agent Deployment.  ([Issue #41859](https://github.com/istio/istio/issues/41859)),([Issue #52663](https://github.com/istio/istio/issues/52663))

- **Added** new istiod environment variable `ENVOY_DNS_JITTER_DURATION`, with a default value of `100ms` that sets jitter for periodic DNS resolution.
  See `dns_jitter` in `https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto`.
  This can help decrease the load on the cluster DNS server.
  ([Issue #52877](https://github.com/istio/istio/issues/52877))

- **Added** support for configuring certificate details while populating XFCC header via a new `ProxyConfig` field, `proxyHeaders.setCurrentClientCertDetails`.

- **Added** Allow users to put extra white spaces between namespaces in `networking.istio.io/exportTo` annotation.
  ([Issue #53429](https://github.com/istio/istio/issues/53429))

- **Added** an experimental feature to enable lazily create subset of Envoy statistics.
  This will save memory and CPU cycles when creating the objects that own these stats,
  if those stats are never referenced throughout the lifetime of the process.
  This can be disabled by setting `ENABLE_DEFERRED_STATS_CREATION` to false in agent Deployment.

- **Fixed** matching multiple service VIPs in ServiceEntry. See upgrade notes for more information.
  ([Issue #51747](https://github.com/istio/istio/issues/51747)),([Issue #30282](https://github.com/istio/istio/issues/30282))

- **Fixed** `MeshConfig`'s `serviceSettings.settings.clusterLocal` to favor more precise hostnames, allowing host exclusions.

- **Fixed** `DestinationRules` on same host to not merge if they have different `exportTo` values.
  The hold behavior can be temporarily restored with `ENABLE_ENHANCED_DESTINATIONRULE_MERGE=false`.
  ([Issue #52519](https://github.com/istio/istio/issues/52519))

- **Fixed** an issue where controller-assigned IPs did not respect per-proxy DNS capture the same way that ephemeral auto-allocated IPs did.
  ([Issue #52609](https://github.com/istio/istio/issues/52609))

- **Fixed** an issue causing Waypoints to ignore auto-allocated IPs for `ServiceEntry` in some cases.
  ([Issue #52746](https://github.com/istio/istio/issues/52746))

- **Fixed** an issue where the `ISTIO_OUTPUT` `iptables` chain was not removed with `pilot-agent istio-clean-iptables` command.  ([Issue #52835](https://github.com/istio/istio/issues/52835))

- **Fixed** an issue where using HTTPS in slow request scenarios such as high packet loss networks could potentially lead to Envoy memory leak.
  ([Issue #52850](https://github.com/istio/istio/issues/52850))

- **Fixed** a bug where DNS proxying contained unready endpoints for headless services.

- **Removed** the deprecated `istio.io/gateway-name` label, please use `gateway.networking.k8s.io/gateway-name` label instead.

- **Removed** writing `kubeconfig` to CNI net directory.
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

- **Removed** `CNI_NET_DIR` from the `istio-cni` configmap, as it now does nothing.
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

## Telemetry

- **Updated** CEL vocabulary used in the telemetry APIs and extensions. See upgrade notes for more information.

- **Added** add new pattern variable (`%SERVICE_NAME%`) for stat prefix
  ([Issue #52177](https://github.com/istio/istio/issues/52177))

- **Added** `logAsJson` value to ztunnel helm chart
  ([Issue #52631](https://github.com/istio/istio/issues/52631))

- **Added** stats tags configuration for watchdog metrics.
  ([Issue #52731](https://github.com/istio/istio/issues/52731))

- **Added** support headers and timeout configurations of gRPC requests when exporting traces to OpenTelemetry Collector.  ([Issue #52873](https://github.com/istio/istio/issues/52873))

- **Added** support customized Zipkin collector endpoint under `meshConfig.extensionProviders.zipkin.path`.  ([Issue #53086](https://github.com/istio/istio/issues/53086))

- **Fixed** Added the metrics port to the pods created by [`Gateway` automated deployments](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).

- **Fixed** The `citadel_server_root_cert_expiry_timestamp`, `citadel_server_root_cert_expiry_seconds`, `citadel_server_cert_chain_expiry_timestamp`, and `citadel_server_cert_chain_expiry_seconds` update when new certificates are loaded.

- **Added** `SECRET_GRACE_PERIOD_RATIO_JITTER` with a default value of `0.01` to introduce a randomized offset in `SECRET_GRACE_PERIOD_RATIO`.
  Without this configuration, proxies deployed at the same time will all request renewed certificates simultaneously which can cause excessive CA server load.
  The new default behavior of renewing certificates every 12 hours is augmented by this value to be +/- approximately 15 minutes.
  ([Issue #52102](https://github.com/istio/istio/issues/52102))

## Installation

- **Updated** `securityContext.privileged` to false for istio-cni in favor of feature-specific permissions.
  istio-cni remains a ["privileged" container as per the Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/#privileged), since even without this
  flag it has privileged capabilities, namely `CAP_SYS_ADMIN`.
  ([Issue #52558](https://github.com/istio/istio/issues/52558))

- **Improved** Waypoint `resources` are now configurable using `global.waypoint.resources`.
  ([Issue #51496](https://github.com/istio/istio/issues/51496))

- **Improved** Waypoint pod `affinity` is now configurable using `waypoint.affinity`.
  ([Issue #52883](https://github.com/istio/istio/issues/52883))

- **Improved** Waypoint pod `topologySpreadConstraints` are now configurable using `global.waypoint.topologySpreadConstraints`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Improved** Waypoint pod `tolerations` are now configurable using `global.waypoint.tolerations`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Improved** Waypoint pod `nodeSelector` are now configurable using `global.waypoint.nodeSelector`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Improved** the memory footprint of the `istio-cni-node` DaemonSet. In many cases this can result in up to 80% memory reduction.
  ([Issue #53493](https://github.com/istio/istio/issues/53493))

- **Updated** Kiali addon sample to [version v2.0](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e).

- **Updated** all Istio components to read `v1` CRDs where applicable. This should have no impact, unless the cluster is using Istio CRDs from 1.21 or older (which is not a supported version skew).

- **Added** the `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/part-of`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by`, and `helm.sh/chart` labels to almost all resources.
  ([Issue #52034](https://github.com/istio/istio/issues/52034))

- **Added** Platform-specific configurations for Helm installs. Example:
  `helm install istio-cni --set profile=ambient --set global.platform=k3s`
  `helm install istiod --set profile=ambient --set global.platform=k3s`

  For list of currently-supported platform overrides, see `manifests/charts/platform-xxx.yaml` files.

**Removed** the `openshift` profile variants, replaced with `global.platform` overrides. Example:
`helm install istio-cni --set profile=ambient-openshift` is now
`helm install istio-cni --set profile=ambient --set global.platform=openshift`

- **Added** Add the ability to configure `initContainers` for Istiod.
  ([Issue #53120](https://github.com/istio/istio/issues/53120))

- **Added** Add settings (`strategy`, `minReadySeconds`, and `terminationGracePeriodSeconds`) to stabilize gateways for high traffic.
  ([Issue #53121](https://github.com/istio/istio/issues/53121))

- **Added** value `seLinuxOptions` to `istio-cni` chart. On some platforms (e.g. OpenShift) it is necessary to set
  `seLinuxOptions.type` to `spc_t` in order to work around some SELinux constraints related to `hostPath` volumes.
  Without this setting, the `istio-cni-node` pods may fail to start.  ([Issue #53558](https://github.com/istio/istio/issues/53558))

- **Added** support for providing arbitrary environment variables to `istio-cni` chart

- **Added** a new annotation `sidecar.istio.io/nativeSidecar` to allow users to control native sidecar injection on a per-pod basis.
  This annotation can be set to `true` or `false` to enable or disable native sidecar injection for a pod.
  This annotation takes precedence over the global `ENABLE_NATIVE_SIDECARS` environment variable.
  ([Issue #53452](https://github.com/istio/istio/issues/53452))

- **Added** Allow user to add customized annotation to `MutatingWebhookConfiguration` for revision-tags through helm chart.

- **Fixed** `kube-virt-interfaces` rules not being removed by `istio-clean-iptables` tool.
  ([Issue #48368](https://github.com/istio/istio/issues/48368))

- **Fixed** Allow for re-executions of istio-iptables by skipping apply step if existing rules are compatible.

- **Fixed** an issue where some installation status lines were not finalized correctly which can cause odd rendering when terminal windows are resized.
  ([Issue #52525](https://github.com/istio/istio/issues/52525))

- **Fixed** Set `allowPrivilegeEscalation` to `true` in ztunnel - it has always been forced to `true` in reality but K8S does not properly validate this: <https://github.com/kubernetes/kubernetes/issues/119568>.

- **Fixed** Remove non-critical components from `base` chart, and remove `pilot.enabled` from
  `istiod-remote` and `istio-discovery` charts.

- **Fixed** templated CRD installation in the `base` chart by default. Previously this only worked under certain conditions,
  and when certain install flags were used, could result in CRDs that could only be upgraded via manual `kubectl` intervention.
  See upgrade notes for more information.

- **Deprecated** `Values.base.enableCRDTemplates`. This option now defaults to `true` and will be removed
  in a future release. Until then, the legacy behavior can be enabled by setting this to `false`
  ([Issue #43204](https://github.com/istio/istio/issues/43204))

- **Removed** some fields from the helm values API that had been without effect and in some cases long-deprecated.
  Removed fields are: `pilot.configNamespace`, `pilot.configSource`, `pilot.enableProtocolSniffingForOutbound`, `pilot.enableProtocolSniffingForInbound`, `pilot.useMCP`,
  `global.autoscalingV2API`, `global.configRootNamespace`, `global.defaultConfigVisibilitySettings`, `global.useMCP`, `sidecarInjectorWebhook.objectSelector`, and `sidecarInjectorWebhook.useLegacySelectors`.
  ([Issue #51987](https://github.com/istio/istio/issues/51987))

- **Removed** unused `istio_cni` values from the `istiod` chart that were marked as deprecated (#49290) 2 releases ago.
  ([Issue #52645](https://github.com/istio/istio/issues/52645))

- **Removed** `istiod-remote` chart in favor of `helm install istio-discovery --set profile=remote`.

- **Removed** support for the `1.20` `compatibilityProfile`. This configured the following settings: `ENABLE_EXTERNAL_NAME_ALIAS`,
  `PERSIST_OLDEST_FIRST_HEURISTIC_FOR_VIRTUAL_SERVICE_HOST_MATCHING`, `VERIFY_CERTIFICATE_AT_CLIENT`, and `ENABLE_AUTO_SNI`.
  All of these flags, except for `ENABLE_AUTO_SNI`, have also been removed from Istio entirely.

- **Removed** the `sidecar.istio.io/enableCoreDump` annotation. See the sample provided in `samples/proxy-coredump` for more preferred approaches to enable core dumps.

- **Removed** the legacy `--log_rotate_*` flag options. Users wishing to use log rotation should use external log rotation tools.

## istioctl

- **Added** automatic detection of a variety of platform-specific incompatibilities during installation.

- **Added** a new command, `istioctl manifest translate`, to help migrate from `istioctl install` to `helm`.

- **Added** a new flag `remote-contexts` to the `istioctl analyze` command to specify remote cluster contexts during multi-cluster analysis.
  ([Issue #51934](https://github.com/istio/istio/issues/51934))

- **Added** support for filtering Pods by label selector to `istioctl x envoy-stats`.

- **Added** support for filtering resources by namespace to `istioctl experimental injector list`.

- **Added** support for the `--impersonate` flags in the istioctl.
  ([Issue #52285](https://github.com/istio/istio/issues/52285))

- **Fixed** istioctl analyze report IST0145 error with wildcard host and specific subdomain.
  ([Issue #52413](https://github.com/istio/istio/issues/52413))

- **Fixed** `istioctl experimental injector list` prints webhooks not related to istio.

- **Removed** `istioctl manifest diff` and `istioctl manifest profile diff` commands. Users looking to compare manifest can use generic YAML comparison tools.

- **Removed** `istioctl profile` command. The same information can be found in Istio documentation.

## Documentation changes

- **Improved** legibility of Istio's documentation by renaming the `sleep` sample to `curl`.
  ([Issue #15725](https://github.com/istio/istio.io/issues/15725))
