---
title: Istio 1.18.0 Change Notes
linktitle: 1.18.0
subtitle: Minor Release
description: Istio 1.18.0 change notes.
publishdate: 2023-06-07
release: 1.18.0
weight: 20
---

## Deprecation Notices

These notices describe functionality that will be removed in a future release according to [Istio's deprecation policy](/docs/releases/feature-stages/#feature-phase-definitions). Please consider upgrading your environment to remove the deprecated functionality.

- There are no new deprecations in Istio 1.18.0

## Traffic Management

- **Improved** [Gateway API Automated Deployment](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment) management logic. See Upgrade Notes for more information.

- **Updated** the VirtualService validation to fail on empty prefix header matcher. ([Issue #44424](https://github.com/istio/istio/issues/44424))

- **Updated** `ProxyConfig` resources with workload selector will be applied to Kubernetes `Gateway` pods
only if the specified label is `istio.io/gateway-name`. Other labels are ignored.

- **Added** provision to provide overridden/explicit value for `failoverPriority` label. This provided value is used while assigning priority for endpoints instead of the client's value.
  ([Issue #39111](https://github.com/istio/istio/issues/39111))

- **Added** prefix matching on query parameter. ([Issue #43710](https://github.com/istio/istio/issues/43710))

- **Added** health checks for those VMs that are not using auto-registration.
  ([Issue #44712](https://github.com/istio/istio/issues/44712))

- **Fixed** admission webhook fails with custom header value format.
  ([Issue #42749](https://github.com/istio/istio/issues/42749))

- **Fixed** fixed bug of Istio cannot be deployed on IPv6-first DS clusters for Dual Stack support in Istio.
 ([Optimized Design]( https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/))([Original Design]( https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/)) ([Issue #40394](https://github.com/istio/istio/issues/40394))([Issue #41462](https://github.com/istio/istio/issues/41462))

- **Fixed** an issue where `EnvoyFilter` for `Cluster.ConnectTimeout` was affecting unrelated `Clusters`.
  ([Issue #43435](https://github.com/istio/istio/issues/43435))

- **Fixed** reporting Programmed condition on Gateway API Gateway resources.
  ([Issue #43498](https://github.com/istio/istio/issues/43498))

- **Fixed** an issue that when there are different Binds specified in the Gateways with the same port and different protocols, listeners are not generated correctly.
  ([Issue #43688](https://github.com/istio/istio/issues/43688))

- **Fixed** an issue that when there are different Binds specified in the Gateways with the same port and TCP protocol, listeners are not generated correctly.
  ([Issue #43775](https://github.com/istio/istio/issues/43775))

- **Fixed** an issue with service entry deletion not deleting the corresponding endpoints in some cases.
  ([Issue #43853](https://github.com/istio/istio/issues/43853))

- **Fixed** an issue where auto allocated service entry IPs change on host reuse.
  ([Issue #43858](https://github.com/istio/istio/issues/43858))

- **Fixed** `WorkloadEntry` resources never being cleaned up if multiple
`WorkloadEntries` were auto-registered with the same IP and network.
  ([Issue #43950](https://github.com/istio/istio/issues/43950))

- **Fixed** the `dns_upstream_failures_total` metric was mistakenly deleted in the previous release.
  ([Issue #44151](https://github.com/istio/istio/issues/44151))

- **Fixed** an issue where ServiceEntry and Service had undefined or empty workload selectors. If the workload selector is undefined or empty, ServiceEntry and Service should not select any `WorkloadEntry` or endpoint.

- **Fixed** An issue where a Service Entry configured with partial wildcard hosts generates a warning during validation as the config can some times generate invalid server name match. ([Issue #44195](https://github.com/istio/istio/issues/44195))

- **Fixed** an issue where `Istio Gateway` (Envoy) would crash due to a duplicate `istio_authn` network filter in the Envoy filter chain.
  ([Issue #44385](https://github.com/istio/istio/issues/44385))

- **Fixed** a bug where services are missing in gateways if `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` is enabled.  ([Issue #44439](https://github.com/istio/istio/issues/44439))

- **Fixed** CPU usage abnormally high when cert specified by DestinationRule are invalid.
  ([Issue #44986](https://github.com/istio/istio/issues/44986))

- **Fixed** an issue where changing a label on a workload instance with a previously matched `ServiceEntry` would not properly get removed.
  ([Issue #42921](https://github.com/istio/istio/issues/42921))

- **Fixed** istiod not reconciling k8s gateway deployments and services when they are changed.
  ([Issue #43332](https://github.com/istio/istio/issues/43332))

- **Fixed** an issue where istiod does not retry resolving east-west gateway hostnames on failure.
  ([Issue #44155](https://github.com/istio/istio/issues/44155))

- **Fixed** an issue where istiod generates incorrect endpoints when it fails to resolve east-west gateway hostnames.
  ([Issue #44155](https://github.com/istio/istio/issues/44155))

- **Fixed** an issue where sidecars do not proxy DNS properly for a hostname backed by multiple services.
  ([Issue #43152](https://github.com/istio/istio/pull/43152))

- **Fixed** an issue where updating Service ExternalName does not take effect.
  ([Issue #43440](https://github.com/istio/istio/issues/43440))

- **Fixed** an issue causing VMs using auto-registration to ignore labels other than those defined in a `WorkloadGroup`.
  ([Issue #32210](https://github.com/istio/istio/issues/32210))

- **Upgraded** the gateway-api integration to read `v1beta1` resources for `ReferenceGrant`, `Gateway`, and `GatewayClass`. Users of the gateway-api must be on `v0.6.0+` before upgrading Istio. `istioctl x precheck` can detect this issue before upgrading.

- **Removed** support for `proxy.istio.io/config` annotation applied to Kubernetes `Gateway` pods.

- **Removed** support for `Ingress` version `networking.k8s.io/v1beta1`. The `v1` version has been available since Kubernetes 1.19.

- **Removed** `alpha` Gateway API types by default. They can be explicitly re-enabled with `PILOT_ENABLE_ALPHA_GATEWAY_API=true`.

- **Removed** the experimental "taint controller" for Istio CNI.

- **Removed** support for `EndpointSlice` version `discovery.k8s.io/v1beta1`. The `v1` version has been available since Kubernetes 1.21.
`EndpointSlice` `v1` is automatically used on Kubernetes 1.21+, while `Endpoints` is used on older versions.
This change only impacts users explicitly enabling `PILOT_USE_ENDPOINT_SLICE` on Kubernetes versions older than 1.21, which is no longer supported.

- **Removed** deprecated and unsupported status conditions `Ready`, `Scheduled`, and `Detached` from Gateway API.

## Security

- **Added** `--profiling` flag to allow enabling or disabling profiling on pilot-agent status port.
  ([Issue #41457](https://github.com/istio/istio/issues/41457))

- **Added** support for pushing additional federated trust domains from `caCertificates` to the peer SAN validator.
  ([Issue #41666](https://github.com/istio/istio/issues/41666))

- **Added** support for using P384 curves when using ECDSA ([PR #44459](https://github.com/istio/istio/pull/44459))

- **Added** `ecdh_curves` support for non `ISTIO_MUTUAL` traffic through MeshConfig API.
  ([Issue #41645](https://github.com/istio/istio/issues/41645))

- **Enabled** the `AUTO_RELOAD_PLUGIN_CERTS` env var by default for istiod to notice `cacerts` file changes in common cases (e.g. reload intermediate certs).
  ([Issue #43104](https://github.com/istio/istio/issues/43104))

- **Fixed** ignoring default CA certificate when `PeerCertificateVerifier` is created.

- **Fixed** issue with metadata handling for Azure platform. Support added for
`tagsList` serialization of tags on instance metadata.
  ([Issue #31176](https://github.com/istio/istio/issues/31176))

- **Fixed** an issue where RBAC updates were not sent to older proxies after upgrading istiod to 1.17.
  ([Issue #43785](https://github.com/istio/istio/issues/43785))

- **Fixed** handling of remote SPIFFE trust bundles containing multiple certs.
  ([Issue #44831](https://github.com/istio/istio/issues/44831))

- **Removed** support for the `certificates` field in `MeshConfig`. This was deprecated in 1.15, and does not work on Kubernetes 1.22+.
  ([Issue #36231](https://github.com/istio/istio/issues/36231))

## Telemetry

- **Added** support to control trace id length on Zipkin tracing provider.
  ([Issue #43359](https://github.com/istio/istio/issues/43359))

- **Added** support for `METADATA` command operator in access log.
  ([Issue #44074](https://github.com/istio/istio/issues/44074))

- **Added** metric expiry support, when env flags `METRIC_ROTATION_INTERVAL` and
`METRIC_GRACEFUL_DELETION_INTERVAL` are enabled.

- **Fixed** an issue where you could not disable tracing in `ProxyConfig`.
  ([Issue #31809](https://github.com/istio/istio/issues/31809))

- **Fixed**  an issue where `ALL_METRICS` does not disable metrics as expected. ([PR #43179](https://github.com/istio/istio/pull/43179))

- **Fixed** a bug that would cause unexpected behavior when applying access logging configuration based on the direction of traffic. With this fix, access logging configuration for `CLIENT` or `SERVER` will not affect each other.

- **Fixed** pilot has an additional invalid gateway metric that was not created by the user.

- **Fixed** an issue where grpc stats are absent.
  ([Issue #43908](https://github.com/istio/istio/issues/43908)),([Issue #44144](https://github.com/istio/istio/issues/44144))

## Installation

- **Improved** `istioctl operator remove` command to run without the confirmation in the dry-run mode. ([PR #43120](https://github.com/istio/istio/pull/43120))

- **Improved** the `downloadIstioCtl.sh` script to not change to the home directory at the end. ([Issue #43771](https://github.com/istio/istio/issues/43771))

- **Improved** the default telemetry installation to configure `meshConfig.defaultProviders` instead of custom `EnvoyFilter`s
when advanced customizations are not used, improving performance.

- **Updated** the proxies `concurrency` configuration to always be detected based on CPU limits, unless explicitly configured. See upgrade notes for more info. ([PR #43865](https://github.com/istio/istio/pull/43865))

- **Updated** `Kiali` addon to version `v1.67.0`. ([PR #44498](https://github.com/istio/istio/pull/44498))

- **Added** env variables to support modifying grpc keepalive values.
  ([Issue #43256](https://github.com/istio/istio/issues/43256))

- **Added** support for scraping metrics in dual stack clusters.
  ([Issue #35915](https://github.com/istio/istio/issues/35915))

- **Added** make inbound port configurable.
  ([Issue #43655](https://github.com/istio/istio/issues/43655))

- **Added** injection of `istio.io/rev` annotation to sidecars and gateways for multi-revision observability.

- **Added** an automatically set GOMEMLIMIT to `istiod` to reduce the risk of out-of-memory issues.
  ([Issue #40676](https://github.com/istio/istio/issues/40676))

- **Added** support for labels to be added to the Gateway pod template via `.Values.labels`.
  ([Issue #41057](https://github.com/istio/istio/issues/41057)),([Issue #43585](https://github.com/istio/istio/issues/43585))

- **Added** check to limit the `clusterrole` for k8s CSR permissions for
external CA `usecases` by verifying `.Values.pilot.env.EXTERNAL_CA` and `.Values.global.pilotCertProvider` parameters.

- **Added** configurable node affinity to istio-cni `values.yaml`. Can be used to allow excluding istio-cni from being scheduled on specific nodes.

- **Fixed** SELinux issue on `CentOS9`/RHEL9 where iptables-restore isn't allowed
to open files in `/tmp`. Rules passed to iptables-restore are no longer written
to a file, but are passed via `stdin`.
  ([Issue #42485](https://github.com/istio/istio/issues/42485))

- **Fixed** an issue where webhook configuration was being modified in dry-run mode when installing Istio with istioctl. ([PR #44345](https://github.com/istio/istio/pull/44345))

- **Removed** injecting label `istio.io/rev` to gateways to avoid creating pods indefinitely when `istio.io/rev=<tag>`.
  ([Issue #33237](https://github.com/istio/istio/issues/33237))

- **Removed** operator skip reconcile for `iop` resources with names starting with `installed-state`. It now relies solely on the annotation `install.istio.io/ignoreReconcile`.
This won't affect the behavior of `istioctl install`.
  ([Issue #29394](https://github.com/istio/istio/issues/29394))

- **Removed** `kustomization.yaml` and `pre-generated` installation manifests (`gen-istio.yaml`, etc) from published releases.
These previously installed unsupported testing images, which led to accidental usage by users and tools such as Argo CD.

## istioctl

- **Improved** the `istioctl pc secret` output to display the certificate serial number in HEX. ([Issue #43765](https://github.com/istio/istio/issues/43765))

- **Improved** the `istioctl analyze` to output mismatched proxy image messages as IST0158 on namespace level instead of IST0105 on pod level, which is more succinct.

- **Added** `istioctl analyze` will display a error when encountering two additional erroneous Telemetry scenarios.
  ([Issue #43705](https://github.com/istio/istio/issues/43705))

- **Added** `--output-dir` flag to specify the output directory for the `bug-report` command's generated archive file.
  ([Issue #43842](https://github.com/istio/istio/issues/43842))

- **Added** credential validation when using `istioctl analyze` to validate the secrets specified with `credentialName` in Gateway resources.
  ([Issue #43891](https://github.com/istio/istio/issues/43891))

- **Added** an analyzer for showing warning messages when the deprecated `lightstep` provider is still being used.
  ([Issue #40027](https://github.com/istio/istio/issues/40027))

- **Added** istiod metrics to `bug-report`, and a few more debug points like `telemetryz`.
  ([Issue #44062](https://github.com/istio/istio/issues/44062))

- **Added** a "VHOST NAME" column to the output of `istioctl pc route`.
  ([Issue #44413](https://github.com/istio/istio/issues/44413))

- **Added** local flags `--ui-port` for different `istioctl dashboard` commands to allow users to specify the component UI port to use for the dashboard.

- **Fixed** Server Side Apply is enabled by default for Kubernetes cluster versions above 1.22
or be detected if it can be run in Kubernetes versions 1.18-1.21.

- **Fixed** `istioctl install --set <boolvar>=<bool>` and `istioctl manifests generate --set <boolvar>=<bool>` improperly converting a boolean into a string. ([Issue #43355](https://github.com/istio/istio/issues/43355))

- **Fixed** `istioctl experimental describe` not showing all weighted routes when the VirtualService is defined to split traffic across multiple services.
  ([Issue #43368](https://github.com/istio/istio/issues/43368))

- **Fixed** `istioctl x precheck` displays unwanted IST0136 messages which are set by Istio as default.
  ([Issue #36860](https://github.com/istio/istio/issues/36860))

- **Fixed** a bug in `istioctl analyze` where some messages are missed when there are services with no selector in the analyzed namespace.

- **Fixed** resource namespace resolution for `istioctl` commands.

- **Fixed** an issue where specifying the directory for temporary artifacts with `--dir` when using `istioctl bug-report` did not work.
  ([Issue #43835](https://github.com/istio/istio/issues/43835))

- **Fixed** `istioctl experimental revision describe` warning gateway is not enabled when gateway exists.
  ([Issue #44002](https://github.com/istio/istio/issues/44002))

- **Fixed** `istioctl experimental revision describe` has incorrect number of egress gateways.
  ([Issue #44002](https://github.com/istio/istio/issues/44002))

- **Fixed** inaccuracies in analysis results when analyzing configuration files with empty content.

- **Fixed** `istioctl analyze` no longer expects pods and runtime resources when analyzing files.
  ([Issue #40861](https://github.com/istio/istio/issues/40861))

- **Fixed** `istioctl analyze` to prevent panic when the server port in Gateway is nil.  ([Issue #44318](https://github.com/istio/istio/issues/44318))

- **Fixed** the `istioctl experimental revision list` `REQD-COMPONENTS` column data being incomplete and general output format.

- **Fixed** `istioctl operator remove` cannot remove the operator controller due to a `no Deployment detected` error.
  ([Issue #43659](https://github.com/istio/istio/issues/43659))

- **Fixed** `istioctl verify-install` fails when using multiple `iops`.
  ([Issue #42964](https://github.com/istio/istio/issues/42964))

- **Fixed** `istioctl experimental  wait` has undecipherable message when `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` is not enabled. ([PR #43023](https://github.com/istio/istio/pull/43023))
