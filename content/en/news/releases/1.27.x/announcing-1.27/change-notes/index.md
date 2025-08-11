---
title: Istio 1.27.0 Change Notes
linktitle: 1.27.0
subtitle: Minor Release
description: Istio 1.27.0 release notes.
publishdate: 2025-08-11
release: 1.27.0
weight: 10
aliases:
    - /news/announcing-1.27.0
    - /news/announcing-1.27.x
---

## Traffic Management

- **Updated** traffic distribution to disregard subzone when the Kubernetes Service `trafficDistribution` field is set to `PreferClose`. ([Issue #55848](https://github.com/istio/istio/issues/55848))

- **Added** support for multiple server certificates in gateway (istio & Gateway API). ([Issue #36181](https://github.com/istio/istio/issues/36181))

- **Added** alpha support for specifying `ServiceScope` in the MeshConfig in ambient multicluster configurations.
  `ServiceScope` enables the selection of individual services or services in a namespace to be global or local.
  A locally scoped service is only discoverable by the data plane in the same cluster as the service. A local
  service is not discoverable by the data planes in other clusters. A globally-scoped service is discoverable
  by the data planes in all clusters. Defining selectors for the `serviceScopeConfigs` determines which services
  and workloads are shared with the data plane and which clusters and listeners are configured for the waypoints
  (including e/w gateways) in the mesh.

- **Added** feature flag `EnableGatewayAPICopyLabelsAnnotations` to allow
  users to choose whether the deployment resources will inherit attributes from
  the parent Gateway API resource. This feature is enabled by default.

- **Added** support for `PreferSameNode` and `PreferSameZone` on the Kubernetes Service `trafficDistribution` field.  ([Issue #55848](https://github.com/istio/istio/issues/55848))

- **Added** Pilot environment variables `PILOT_IP_AUTOALLOCATE_IPV4_PREFIX` and `PILOT_IP_AUTOALLOCATE_IPV6_PREFIX` to configure the IP CIDR prefix(es) for auto-allocated IPs. This allows users to set a specific range of IPs for auto-allocation, providing more control over the IP address space used for VIPs by the ipallocate controller.

- **Added** logging of a secret's namespace and name when a certificate is invalid.
  ([Issue #56651](https://github.com/istio/istio/issues/56651))

- **Added** support for [Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/).
  This feature is off by default and can be turned on with the `SUPPORT_GATEWAY_API_INFERENCE_EXTENSION` environment variable.
  ([Issue #55768](https://github.com/istio/istio/issues/55768))

- **Added** support for merge operations when applying to `LISTENER_FILTER` in EnvoyFilter.

- **Added** feature `ENABLE_LAZY_SIDECAR_EVALUATION` that allows to enable lazy initialization of sidecar resources,
  Only computing internal indexes when `SidecarScopes` are actually used by a Proxy. This feature supersedes the
  previous `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY` which would allow concurrent conversion with specific given concurrency,
  instead `ENABLE_LAZY_SIDECAR_EVALUATION` will use the same concurrency as `PILOT_PUSH_THROTTLE`.

- **Added** support for native `nftables` when using Istio sidecar mode. This update makes it possible to use `nftables`
  instead of iptables to manage network rules, offering more efficient approach to traffic redirection for pods and
  services. To enable the `nftables` mode, use `--set values.global.nativeNftables=true` at the time of installation.  ([Issue #56487](https://github.com/istio/istio/issues/56487))

- **Added** support for specifying traffic distribution mode for services. ([Issue #53354](https://github.com/istio/istio/issues/53354))

- **Added** feature `ENABLE_PROXY_FIND_POD_BY_IP` that allows enabling association of Pods to Proxies by IP address, if the association by name and namespace fails.

- **Added** support of retry budget in `DestinationRule` resources.

- **Fixed** an issue where the gateway status controller leader election was not running per revision, which could lead to issues in multi-revision setups.
  The leader election is now correctly scoped to each revision, ensuring that the gateway status controller operates independently for each revision.
  ([Issue #55717](https://github.com/istio/istio/issues/55717))

- **Fixed** an issue where virtual service routes were ignored when the virtual service was configured with hosts containing mixed-case letters.
  ([Issue #55767](https://github.com/istio/istio/issues/55767))

- **Fixed** a regression in Istio 1.26.0 that caused a panic in istiod when processing Gateway API hostnames.
  ([Issue #56300](https://github.com/istio/istio/issues/56300))

- **Fixed** an issue where mTLS was disabled unexpectedly when `PILOT_ENABLE_TELEMETRY_LABEL` or `PILOT_ENDPOINT_TELEMETRY_LABEL` was set to `false`
  ([Issue #56352](https://github.com/istio/istio/issues/56352))

- **Fixed** an issue where ambient host network iptables rules were being skipped due to higher-priority CNI rules in some deployments.
  ([Issue #56414](https://github.com/istio/istio/issues/56414))

- **Fixed** an issue where `EnvoyFilter` with `targetRefs` matched incorrect resources.
  ([Issue #56417](https://github.com/istio/istio/issues/56417))

- **Fixed** ambient index to filter configurations by their revision.
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **Fixed** an issue where the `topology.istio.io/network` label was not properly skipped on the system namespace when `discoverySelectors` were in use.
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **Fixed** an issue where the CNI plugin incorrectly handled pod deletion when the pod was not yet marked as enrolled in the mesh. In some cases, this could cause a pod, which had been deleted, to be included in the ZDS snapshot and never cleaned up. If this occurred, ztunnel would not be able to become ready.  ([Issue #56738](https://github.com/istio/istio/issues/56738))

- **Fixed** an issue where Istio's outbound route configuration did not include the absolute domain name  (fully-qualified domain name with trailing dot) in the domains list for `VirtualHost` entries. This change ensures that requests using absolute domain names (ending with a dot, e.g., `my-service.my-ns.svc.cluster.local.`) are properly routed to the intended service instead of falling back to `PassthroughCluster`.
  ([Issue #56007](https://github.com/istio/istio/issues/56007))

## Security

- **Added** support for omitting the issuer claim in JWT tokens. Either the issuer claim or a `JWKSUri` is required,
  but not both. This allows for more flexible configurations when using JWT tokens for authentication, particularly
  in scenarios where the issuer claim may be dynamic. ([Issue #14400](https://github.com/istio/istio/issues/14400))

- **Added** an opt-in feature when using istio-cni in ambient mode, to create an Istio-owned CNI config
  file which contains the contents of the primary CNI config file and the Istio CNI plugin. This
  opt-in feature is a solution to the issue of traffic bypassing the mesh on node restart when the
  Istio CNI `DaemonSet` is not ready, the Istio CNI plugin is not installed, or the plugin is not
  invoked to configure traffic redirection from pods their node ztunnels. This feature is enabled by
  setting `cni.istioOwnedCNIConfig` to true in the istio-cni Helm chart values. If no value is set for
  `cni.istioOwnedCNIConfigFilename`, the Istio-owned CNI config file will be named `02-istio-cni.conflist`.
  The `istioOwnedCNIConfigFilename` value must have a higher lexicographical priority than the primary CNI.
  Ambient and chained CNI plugins must be enabled for this feature to work.

- **Added** validation for the istioctl `--clusterAliases` command argument. It should not have more than one alias per cluster.  ([Issue #56022](https://github.com/istio/istio/issues/56022))

- **Added** support for `ClusterTrustBundle` by migrating from `certificates.k8s.io/v1alpha1` to the stable `v1beta1` API in Kubernetes 1.33+. This improves compatibility and future-proofs Istio’s certificate distribution mechanism.
  ([Issue #56306](https://github.com/istio/istio/issues/56306))

- **Added** support for external Secret Discovery Service (SDS) providers in the Gateway TLS configuration. Istio now provides
  improved integration with external SDS providers for TLS certificate management at the Gateway.
  ([Issue #56522](https://github.com/istio/istio/issues/56522))

- **Added** certificate revocation list (CRL) support for plugged-in CAs, enabling Istio to watch for `ca-crl.pem` files and
  automatically distribute CRLs across all namespaces in the cluster. This enhancement allows
  proxies to validate and reject revoked certificates, strengthening the security posture of service mesh deployments
  using plugged-in CAs.  ([Issue #56529](https://github.com/istio/istio/issues/56529))

- **Added** the Post-Quantum Cryptography (PQC) option to `COMPLIANCE_POLICY`.
  This policy enforces TLS `v1.3`, cipher suites `TLS_AES_128_GCM_SHA256` and `TLS_AES_256_GCM_SHA384`,
  and post-quantum-safe key exchange `X25519MLKEM768`.
  To enable this compliance policy in ambient mode, it must be set in the pilot and ztunnel containers.
  This policy applies to the following data paths:
    - mTLS communication between Envoy proxies and ztunnels;
    - regular TLS on the downstream and the upstream of Envoy proxies (e.g. gateway);
    - Istio xDS server.
  ([Issue #56330](https://github.com/istio/istio/issues/56330))

- **Fixed** an issue where sidecars with the old `CLUSTER_ID` setting were not able to connect to istiod with the new `CLUSTER_ID` settings when `--clusterAliases` command argument was being used.
  ([Issue #56022](https://github.com/istio/istio/issues/56022))

- **Fixed** an issue in the `pluginca` feature where `istiod` would silently fallback to the self-signed CA if the provided `cacerts` bundle was incomplete.
  The system now properly validates the presence of all required CA files and fails with an error if the bundle is incomplete.

## Telemetry

- **Fixed** an issue where Grafana dashboard was linking to the Istio Mesh Dashboard using path-based links that no longer work. Workload and Service links now use dashboard UIDs.
  ([Issue #50124](https://github.com/istio/istio/issues/50124))

- **Fixed** an issue where access logs were not being updated when the referenced service was created later than the Telemetry resource.
  ([Issue #56825](https://github.com/istio/istio/issues/56825))

- **Removed** support of the `Lightstep` tracing provider.
  ([Issue #54002](https://github.com/istio/istio/issues/54002))

## Extensibility

- **Added** an option to reload the Wasm VM on new requests if the VM has failed.

## Installation

- **Promoted** the environment variable `ENABLE_NATIVE_SIDECARS` to default to `true`. This means native sidecars will be injected into all eligible pods unless explicitly disabled.
  This can be disabled explicitly or for specific workloads by adding the annotation `sidecar.istio.io/native-side: "false"` to individual pods or pod templates.
  ([Issue #48794](https://github.com/istio/istio/issues/48794))

- **Added** a setting `values.global.trustBundleName` that allows configuring the name of the ConfigMap that istiod uses to propagate its root CA certificate in the cluster. This allows running multiple control planes with overlapping namespaces in the same cluster.

- **Added** support for customizing ambient enablement Labels.
  ([Issue #53578](https://github.com/istio/istio/issues/53578))

- **Added** support for configuring `additionalContainers` and `initContainers` on the Gateway Helm Chart.

- **Added** support for configuring ztunnel tolerations via Helm chart values.
  ([Issue #56086](https://github.com/istio/istio/issues/56086))

- **Added** support for configuring istio-cni tolerations via Helm chart values.
  ([Issue #56087](https://github.com/istio/istio/issues/56087))

- **Added** defined defaults for `GOMEMLIMIT` and `GOMAXPROCS` divisors to fix an Argo perpetual out-of-sync issue.

- **Added** bootstrap override config for the `gateway-injection-template`.
  ([Issue #28302](https://github.com/istio/istio/issues/28302))

- **Added** `ENABLE_NATIVE_SIDECARS` Helm value in the compatibility profiles of Istio 1.24, 1.25, and 1.26, allowing users to disable the default enabling of native sidecars.

- **Added** support for proxy protocol on status port. ([reference](/docs/reference/commands/pilot-agent/#envvars))
  ([Issue #39868](https://github.com/istio/istio/issues/39868))

- **Added** Helm value `.Values.istiodRemote.enabledLocalInjectorIstiod` to support sidecar injection in remote clusters.
  When `profile=remote`, `.Values.istiodRemote.enabledLocalInjectorIstiod=true`, and `.Values.global.remotePilotAddress="${DISCOVERY_ADDRESS}"`,
  the remote worker cluster installs `istiod` for local sidecar injection, while XDS is still served by the remote primary cluster.
  ([Issue #56328](https://github.com/istio/istio/issues/56328))

- **Added** the `istio.io/rev` label to the istio remote service when `istiodRemote` is enabled
  ([Issue #56142](https://github.com/istio/istio/issues/56142))

- **Added** support for `deploymentAnnotations` in the istiod Helm chart. Users can now specify custom annotations to be applied to the istiod Deployment object, in addition to the existing `podAnnotations` support. This is useful for integration with monitoring tools, GitOps workflows, and policy enforcement systems that operate at the deployment level.

- **Fixed** an issue where the `ISTIO_KUBE_APP_PROBERS` environment variable was not set for probe rewrites when the Istio webhook was re-invoked.
  ([Issue #56102](https://github.com/istio/istio/issues/56102))

- **Fixed** an issue where secrets references in the env of `istio/gateway` Helm chart were incorrectly rendered as a string.
  ([Issue #55141](https://github.com/istio/istio/issues/55141))

- **Fixed** an injection failure that occurred when the `gateway` template was combined with another template, like `spire`,
which overrides `workload-socket`, resulted in Kubernetes not creating other volumes, like those with `emptyDir` and `csi` settings.

- **Fixed** a panic in `istioctl manifest translate` when the `IstioOperator` config contained multiple gateways.
  ([Issue #56223](https://github.com/istio/istio/issues/56223))

- **Fixed** assignment of incorrect UIDs and GIDs for `istio-proxy` and `istio-validation` containers on OpenShift clusters when TPROXY mode was enabled.

- **Fixed** an issue where `ClusterTrustBundle` was not properly configured when `ENABLE_CLUSTER_TRUST_BUNDLE_API` was enabled.

- **Removed** unused multicluster-related Helm values.

## istioctl

- **Added** the `--kubeclient-timeout` flag to `istioctl` root flags. May be unset, or set to a valid `time.Duration` string.
  When specified, this will override the default `15s` timeout for all `istioctl` commands that use the Kubernetes client.
  This is useful for environments with slow Kubernetes API servers, such as those with high latency or low bandwidth.
  Note that this flag is just used for the Kubernetes client, and does not affect other timeouts in `istioctl`, such as
  installation timeouts. ([Issue #54962](https://github.com/istio/istio/issues/54962))

- **Added** `--revision` flags for `istioctl dashboard controlz` and `istioctl dashboard istiod-debug`.

- **Added** support in the `istioctl proxy-status` command to dynamically display all xDS/CRD types as columns in the output table.
  ([Issue #56005](https://github.com/istio/istio/issues/56005))

- **Added** support for customizing the timeout of `istioctl waypoint status` and `istioctl waypoint apply`.
  ([Issue #56453](https://github.com/istio/istio/issues/56453))

- **Added** support for displaying `stack-trace-level` in the command `istioctl admin log`.
  ([Issue #56465](https://github.com/istio/istio/issues/56465))

- **Added** support for displaying `traffic type` in the command `istioctl waypoint list`.

- **Added** support for the `--weight` parameter in the command `istioctl experimental workload group create`.

- **Added** support for configuring the log level of `ip-autoallocate` in `istioctl admin log`.
  ([Issue #55741](https://github.com/istio/istio/issues/55741))

- **Fixed** an issue where, during installation, `istio-revision-tag-default` and `MutatingWebhookConfiguration` were not created when the revision was not the default.
  ([Issue #55980](https://github.com/istio/istio/issues/55980))

- **Fixed** an issue where false positive of IST0134 were raised in `istioctl analyze` when `PILOT_ENABLE_IP_AUTOALLOCATE` was set to `true`.
  ([Issue #56083](https://github.com/istio/istio/issues/56083))

- **Fixed** an issue where analysis included Kubernetes system namespaces (e.g., `kube-system`, `kube-node-lease`).
  ([Issue #55022](https://github.com/istio/istio/issues/55022))

- **Fixed** an issue where `create-remote-secret` created redundant RBAC resources.
  ([Issue #56558](https://github.com/istio/istio/issues/56558))
