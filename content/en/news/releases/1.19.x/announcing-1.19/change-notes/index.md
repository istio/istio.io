---
title: Istio 1.19.0 Change Notes
linktitle: 1.19.0
subtitle: Minor Release
description: Istio 1.19.0 change notes.
publishdate: 2023-09-01
release: 1.19.0
weight: 20
---

## Deprecation Notices

These notices describe functionality that will be removed in a future release according to [Istio's deprecation policy](/about/feature-stages/#feature-phase-definitions). Please consider upgrading your environment to remove the deprecated functionality.

- There are no new deprecations in Istio 1.19.0

## Traffic Management


- **Improved** JWT claim based routing, now support using `[]` as a separator for nested claim names.
  ([Issue #44228](https://github.com/istio/istio/issues/44228))

- **Improved** performance of sidecar injection, in particular with pods with a large number of environment variables.
  

- **Updated** When using a ServiceEntry with DNS resolution, DNS for multi-network gateways 
will be resolved at the proxy instead of in the control plane. 
  

- **Added** support for traffic.sidecar.istio.io/excludeInterfaces annotation in proxy.
  ([Issue #41271](https://github.com/istio/istio/issues/41271))

- **Added** `WorkloadEntry` resources on different networks do not require an address to be specified.
  ([Issue #45150](https://github.com/istio/istio/issues/45150))

- **Added** initial ambient support for WorkloadEntry. Fixes (#45472)[https://github.com/istio/istio/issues/45472).  ([Issue #45472](https://github.com/istio/istio/issues/45472))

- **Added** ambient support for workload entries without an address. Fixes (#45758)[https://github.com/istio/istio/issues/45758).  ([Issue #45758](https://github.com/istio/istio/issues/45758))

- **Added** initial ambient support for ServiceEntry.  

- **Added** support for Regex Rewrite in VirtualService HTTPRewrite
  ([Issue #22290](https://github.com/istio/istio/issues/22290))

- **Added** a new TLS mode 'OPTIONAL_MUTUAL' in ServerTLSSettings of Gateway that will validate client certificate if presented but not mandate it.  


- **Fixed** Istio's Gateway API implementation to adhere to the Gateway API
requirement that a `group: ""` field must be set for a `parentRef` of `kind: Service`.
Istio previously tolerated the missing group for Service-kind parent references. This
is a breaking change; see the upgrade notes for details.
  ([Issue #2309](https://github.com/kubernetes-sigs/gateway-api/issues/2309))

- **Fixed** configuring istio.alpn filter for non-Istio mTLS.
  ([Issue #40680](https://github.com/istio/istio/issues/40680))

- **Fixed** enhancement for Dual Stack to set up the correct DNS family type. 1. `CheckIPFamilyTypeForFirstIPs` has been added to help confirm the IP family type based on the first IP address. 2. Uniform the Dual Stack feature flags for both control and data plane to `ISTIO_DUAL_STACK` with the same environment variable.  ([Issue #41462](https://github.com/istio/istio/issues/41462))

- **Fixed** the bug where patching http_route affects other virtualhosts.
  ([Issue #44820](https://github.com/istio/istio/issues/44820))

- **Fixed** EnvoyFilter run delete at last, It is not follow priority concept
  ([Issue #45089](https://github.com/istio/istio/issues/45089))

- **Fixed** VirtualMachine Workloadentry auto register failed with invalid `istio-locality` label when user specify `istio-locality` in ./etc/istio/pod/labels.  ([Issue #45413](https://github.com/istio/istio/issues/45413))

- **Fixed** an issue in dual stack meshes where virtualHost.Domains was missing the second IP address from dual stack services.
  ([Issue #45557](https://github.com/istio/istio/issues/45557))

- **Fixed** a bug where route configuration is rejected with duplicate domains when virtual service has same hosts with different case.  ([Issue #45719](https://github.com/istio/istio/issues/45719))

- **Fixed** an issue where Istiod might crash when a cluster is deleted if the xDS cache is disabled.
  ([Issue #45798](https://github.com/istio/istio/issues/45798))

- **Fixed** creating `istioin` and `istioout` geneve links on nodes which already have configured
an external geneve link or another geneve link for the same VNI and remote IP. To avoid getting errors
in these cases, istio-cni dynamically determines available destination ports for created geneve links.
  

- **Fixed** an issue where Istiod can't auto-detect the service port change in the case of that this service is referred by ingress using service port name.
  ([Issue #46035](https://github.com/istio/istio/issues/46035))

- **Fixed** app probe: http request.host is not well propagated.
  ([Issue #46087](https://github.com/istio/istio/issues/46087))

- **Fixed** ambient WorkloadEntry xds events to fire on updates to spec. Fixes (#46267)[https://github.com/istio/istio/issues/46267).  ([Issue #46267](https://github.com/istio/istio/issues/46267))

- **Fixed** health_checkers extensions is not compiled in.
  ([Issue #46277](https://github.com/istio/istio/issues/46277))

- **Fixed** Do not include empty IP strings in VIPs (fixes crash when LoadBalancer.Ingress.IP is unset/not present)
  

- **Fixed** Regression in HTTPGet healthcheck probe translation.
  ([Issue #45632](https://github.com/istio/istio/issues/45632))


- **Removed** the `CNI_ENABLE_INSTALL`, `CNI_ENABLE_REINSTALL`, `SKIP_CNI_BINARIES`, and `UPDATE_CNI_BINARIES` feature flags.
  

- **Removed** the support for deprecated envoy filter names in Envoy API name maches. Envoy filter will only be matched with canonical naming standard. See https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.14.0#deprecated
  

- **Removed** the `ISTIO_DEFAULT_REQUEST_TIMEOUT` feature flag. Please use timeout in VirtualService API.  

- **Removed** the `ENABLE_AUTO_MTLS_CHECK_POLICIES` feature flag.  

- **Removed** the `PILOT_ENABLE_LEGACY_AUTO_PASSTHROUGH` feature flag.
  

- **Removed** the `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME` feature flag.  

- **Removed** the `PILOT_LEGACY_INGRESS_BEHAVIOR` feature flag.  

- **Removed** the `PILOT_ENABLE_ISTIO_TAGS` feature flag.  

- **Removed** the `ENABLE_LEGACY_LB_ALGORITHM_DEFAULT` feature flag.  

- **Removed** the `PILOT_PARTIAL_FULL_PUSHES` feature flag.  

- **Removed** the `PILOT_INBOUND_PROTOCOL_DETECTION_TIMEOUT` feature flag. This can be configured in MeshConfig if needed.
  

- **Removed** the `AUTO_RELOAD_PLUGIN_CERTS` feature flag.
  

- **Removed** the `PRIORITIZED_LEADER_ELECTION` feature flag.
  

- **Removed** the `SIDECAR_IGNORE_PORT_IN_HOST_MATCH` feature flag.
  

- **Removed** the `REWRITE_TCP_PROBES` feature flag.
  

- **Removed** support for XDS v2 types in `EnvoyFilter`s. These should use the v3 interface. This has been a warning for multiple releases and is now upgraded to an error.
  

- **Removed** the `PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_OUTBOUND` and `PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_INBOUND` feature flags. These have been enabled by default since Istio 1.5.
  

- **Removed** support for looking up Envoy extensions in `EnvoyFilter` configuration by name without the typed config URL.
  

- **Optimized** EnvoyFilter index generation to avoid rebuilding all EnvoyFilters everytime a single one has changed, instead only rebuild the changed EnvoyFilter and update it in place.
  


## Security




- **Added** `insecureSkipVerify` implementation from DestinationRule. Setting `insecureSkipVerify` to `true` will disable CA certificate and Subject Alternative Names verification for the host.
  ([Issue #33472](https://github.com/istio/istio/issues/33472))

- **Added** support for PeerAuthentication policies in Ambient
  ([Issue #42696](https://github.com/istio/istio/issues/42696))

- **Added** cipher_suites support for non ISTIO_MUTUAL traffic through MeshConfig API.
  ([Issue #28996](https://github.com/istio/istio/issues/28996))

- **Added** cipher_suites support for mesh to mesh traffic through MeshConfig API.
  ([Issue #28996](https://github.com/istio/istio/issues/28996))

- **Added** Certificate Revocation List(CRL) support for peer certificate validation.
  

- **Added** support for a flag called USE_EXTERNAL_WORKLOAD_SDS, when set to true, it will require an external SDS workload socket and it will prevent the istio-proxy from starting if the workload SDS socket is not found.
  ([Issue #45534](https://github.com/istio/istio/issues/45534))


- **Fixed** use defer to unlock mutex
  

- **Fixed** an issue where jwk issuer was not resolved correctly when having a trailing slash in the issuer URL.
  ([Issue #45546](https://github.com/istio/istio/issues/45546))


- **Removed** the `SPIFFE_BUNDLE_ENDPOINTS` feature flag.
  



## Telemetry




- **Added** new metric named `provider_lookup_cluster_failures` for lookup cluster failures.
  

- **Added** support for K8s controller queue metrics, enabled by setting env variable `ISTIO_ENABLE_CONTROLLER_QUEUE_METRICS` as `true`.  ([Issue #44985](https://github.com/istio/istio/issues/44985))

- **Added** an flag to disable OTel builtin resource labels.
  

- **Added** `cluster` label for remote_cluster_sync_timeouts_total metric.  ([Issue #44489](https://github.com/istio/istio/issues/44489))

- **Added** support for an annotation `sidecar.istio.io/statsHistogramBuckets` to customize the histogram buckets in the proxy.
  

- **Added** HTTP metadata exchange filter to support a fallback to xDS workload metadata discovery in addition to the metadata HTTP headers. The discovery method is off by default.
  

- **Added** Provide an option to configure the Envoy to report load stats to the LRS (LoadReportingService) server via LRS.
  


- **Fixed** an issue where disabling a log provider through Istio telemetry API would not work.  

- **Fixed** an issue where `Telemetry` would not be fully disabled unless `match.metric=ALL_METRICS` was explicitly specified; matching all metrics is now correctly considered as the default.
  





## Extensibility




- **Added** an option to fail open on fetch failure and VM fatal errors.
  







## Installation


- **Improved** Usage on OpenShift clusters is simplified by removing the need of manually creating a `NetworkAttachmentDefinition` resource on every application namespace.
  

- **Updated** Kiali addon to version v1.72.0.
  

- **Added** support for `PodDisruptionBudget` (PDB) in the Gateway chart.
  ([Issue #44469](https://github.com/istio/istio/issues/44469))

- **Added** the helm value of setting cni ambient config dir path.
  ([Issue #45400](https://github.com/istio/istio/issues/45400))

- **Added** amd64 named artifacts for MacOS and Windows. The amd64 flavor of the artifacts didgit push not contain the
architecture in the name as we do for the other operating systems. This makes the artifact naming consistent.
**Deprecated** the MacOS and Windows artifacts without an architecture specified in the name
(ex: istio-1.18.0-osx.tar.gz). They will be removed in several releases. They have been replaced
by artifacts containing the architecture in the name (ex: istio-1.18.0-osx-amd64.tar.gz).  ([Issue #45677](https://github.com/istio/istio/issues/45677))

- **Added** rolling update max unavailable to CNI Helm chart to speed up deploys.
  

- **Added** an automatically set `GOMEMLIMIT` and `GOMAXPROCS` to all deployments to improve performance.
  

- **Added** configurable scaling behavior for Istiod's HPA in helm chart 
 ([usage]( https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior)) ([Issue #42634](https://github.com/istio/istio/issues/42634))

- **Added** values to the Istio Pilot Helm charts for configuring additional container arguments, volumeMounts, and volumes. Can be used in conjunction with cert-manager istio-csr.
  ([Issue #113](https://github.com/cert-manager/istio-csr/issues/113))

- **Added** values to the Istiod Helm chart for configuring [topologySpreadConstraints](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/) on the Deployment. Can be used for better placement of istiod workloads.
  ([Issue #42938](https://github.com/istio/istio/issues/42938))

- **Added** Allow setting terminationGracePeriodSeconds for ztunnel pod via Helm chart.
  


- **Fixed** an issue where removing field(s) from IstioOperator and re-installing did not reflect changes in existing IstioOperator spec.  ([Issue #42068](https://github.com/istio/istio/issues/42068))

- **Fixed** `ValidatingWebhookConfiguration` not being generated correctly with operator installation when the revision is not set.
  ([Issue #43893](https://github.com/istio/istio/issues/43893))

- **Fixed** an issue where the operator did not reject invalid CIDR entries that included spaces.
  ([Issue #45338](https://github.com/istio/istio/issues/45338))

- **Fixed** an issue where the hostname package is not listed as a dependency for the VM packages.
  ([Issue #45866](https://github.com/istio/istio/issues/45866))

- **Fixed** an issue preventing the gateway chart from being used with a custom HorizontalPodAutoscaler resource.
  

- **Fixed** an issue that istio should using IMDSv2 as possible on AWS.
  ([Issue #45825](https://github.com/istio/istio/issues/45825))

- **Fixed** OpenShift profile setting `sidecarInjectorWebhook` causing `k8s.v1.cni.cncf.io/networks` to be overwritten when using multiple networks. 
  ([Issue #43632](https://github.com/istio/istio/issues/43632)),([Issue #45034](https://github.com/istio/istio/issues/45034))

- **Fixed** Null traversal issue when using datadog or stackdriver with no tracing options.
  ([Issue #45855](https://github.com/istio/istio/issues/45855))

- **Fixed** an issue preventing the ports of waypoint and ztunnel ports being exposed. Now scrape configs can be created for the Ambient components too. 
  ([Issue #45093](https://github.com/istio/istio/issues/45093))


- **Removed** the following experimental `istioctl` commands: `add-to-mesh`, `remove-from-mesh` and `kube-uninject`.
Usage of automatic sidecar injection is recommended instead.
  

- **Removed** the `ENABLE_LEGACY_FSGROUP_INJECTION` feature flag. This was intended to support Kubernetes 1.18 and older, which are out of support.  

- **Removed** obsolete manifests from the `base` Helm chart. See Upgrade Notes for more information.
  



## istioctl


- **Improved** IST0123 warning message description.
  

- **Updated** minimum supported Kubernetes version to 1.24.x.
  

- **Updated** `istioctl x workload configure` accepts IPv6 address passed in `--ingressIP`.
  

- **Added** config type and endpoint configuration summaries to `istioctl proxy-config all`
  ([Issue #43807](https://github.com/istio/istio/issues/43807))

- **Added** directory support for `istioctl validate`. Now, the `-f` flag accepts both file paths and directory paths.
  

- **Added** support for yaml output to `istioctl admin log`.
  

- **Added** support for checking telemetry labels, which now includes Istio canonical labels and K8S recommended labels.
  

- **Added** support for namespace filtering for proxy statuses. Note: please ensure that both istioctl and istiod are upgraded for this feature to work.
  

- **Added** support for validating json files to istioctl validate.
  ([Issue #46136](https://github.com/istio/istio/issues/46136)),([Issue #46136](https://github.com/istio/istio/issues/46136))

- **Added** warning if user specifies more than one Istio labels in the same namespace. Including istio-injection, istio.io/rev, istio.io/dataplane-mode.
  

- **Added** support for displaying multiple addresses of listeners in `istioctl proxy-config listeners`.
  


- **Fixed** `verify-install` fails to detect daemonsets' component statuses. 
  

- **Fixed** an issue where the cert validity was not accurate for `istioctl pc secret` command. 
  

- **Fixed** an issue where xDS `proxy-status` was showing inaccurate Istio version. Note: please ensure that both istioctl and istiod are upgraded for this fix to work.
  

- **Fixed** an issue where Ztunnel pods could be compared to Envoy configs in `istioctl proxy-status` and `istioctl x proxy-status`. They are now excluded from the comparison.
  

- **Fixed** an issue where there was a parse error when performing rootCA comparison for Ztunnel pods.
  

- **Fixed** an issue where analyzers were reporting messages for the gateway-managed services.
  

- **Fixed** an issue where specifying multiple include conditions by `--include` in bug report didn't't work as expected.
  ([Issue #45839](https://github.com/istio/istio/issues/45839))

- **Fixed** an issue where K8S resources with revision labels were being filtered out by `istioctl analyze` when the `--revision` flag was not used.
  ([Issue #46239](https://github.com/istio/istio/issues/46239))

- **Fixed** an issue where the creation of a Telemetry object without any providers throws the IST0157 error.
  ([Issue #46510](https://github.com/istio/istio/issues/46510))

- **Fixed** Analyzer produces incorrect results for `GatewayPortNotOnWorkload` due to incorrect association of `Gateway.Spec.Servers[].Port.Number` with Service's `Port` instead of `TargetPort`.
  

- **Fixed** `revision` flag missing in `istioctl x precheck`.
  


- **Removed** `uninstall` command from `istioctl experimental`, use `istioctl uninstall` instead.
  

- **Removed** the following experimental `istioctl` commands: `create-remote-secret` and `remote-clusters`.
They have been moved to the top level `istioctl` command.
  



## Documentation changes


- **Improved** Bookinfo samples can now be used in OpenShift without the `anyuid` SCC privilege
  








