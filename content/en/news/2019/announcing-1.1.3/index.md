---
title: Announcing Istio 1.1.3
subtitle: Patch Release
description: Istio 1.1.3 patch release.
publishdate: 2019-04-15
release: 1.1.3
aliases:
    - /about/notes/1.1.3
    - /blog/2019/announcing-1.1.3
    - /news/announcing-1.1.3
---

We're pleased to announce the availability of Istio 1.1.3. Please see below for what's changed.

{{< relnote >}}

## Known issues with 1.1.3

- A [panic in the Node Agent](https://github.com/istio/istio/issues/13325) was discovered late in the 1.1.3 qualification process.  The panic only occurs in clusters with the alpha-quality SDS certificate rotation feature enabled.  Since this is the first time we have included SDS certificate rotation in our long-running release tests, we don't know whether this is a latent bug or a new regression.  Considering SDS certificate rotation is in alpha, we have decided to release 1.1.3 with this issue and target a fix for the 1.1.4 release.

## Bug fixes

- Istio-specific back-ports of Envoy patches for [`CVE-2019-9900`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9900) and
[`CVE-2019-9901`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9901) included in Istio 1.1.2 have been dropped in favor of an
Envoy update which contains the final version of the patches.

- Fix load balancer weight setting for split horizon `EDS`.

- Fix typo in the default Envoy `JSON` log format ([Issue 12232](https://github.com/istio/istio/issues/12232)).

- Correctly reload out-of-process adapter address upon configuration change ([Issue 12488](https://github.com/istio/istio/issues/12488)).

- Restore Kiali settings that were accidentally deleted ([Issue 3660](https://github.com/istio/istio/issues/3660)).

- Prevent services with same target port resulting in duplicate inbound listeners ([Issue 9504](https://github.com/istio/istio/issues/9504)).

- Fix issue with configuring `Sidecar` `egress` ports for namespaces other than `istio-system` resulting in a `envoy.tcp_proxy` filter of `BlackHoleCluster` by auto binding
to services for `Sidecar` listeners ([Issue 12536](https://github.com/istio/istio/issues/12536)).

- Fix gateway `vhost` configuration generation issue by favoring more specific host matches ([Issue 12655](https://github.com/istio/istio/issues/12655)).

- Fix `ALLOW_ANY` so it now allows external traffic if there is already an http service present on a port.

- Fix validation logic so that `port.name` is no longer a valid `PortSelection`.

- Fix [`istioctl proxy-config cluster`](/docs/reference/commands/istioctl/#istioctl-proxy-config-cluster) cluster type column rendering ([Issue 12455](https://github.com/istio/istio/issues/12455)).

- Fix SDS secret mount configuration.

- Fix incorrect Istio version in the Helm charts.

- Fix partial DNS failures in the presence of overlapping ports ([Issue 11658](https://github.com/istio/istio/issues/11658)).

- Fix Helm `podAntiAffinity` template error ([Issue 12790](https://github.com/istio/istio/issues/12790)).

- Fix bug with the original destination service discovery not using the original destination load balancer.

- Fix SDS memory leak in the presence of invalid or missing keying materials ([Issue 13197](https://github.com/istio/istio/issues/13197)).

## Small enhancements

- Hide `ServiceAccounts` from `PushContext` log to reduce log volume.

- Configure `localityLbSetting` in `values.yaml` by passing it through to the mesh configuration.

- Remove the soon-to-be deprecated `critical-pod` annotation from Helm charts ([Issue 12650](https://github.com/istio/istio/issues/12650)).

- Support pod anti-affinity annotations to improve control plane availability ([Issue 11333](https://github.com/istio/istio/issues/11333)).

- Pretty print `IP` addresses in access logs.

- Remove redundant write header to further reduce log volume.

- Improve destination host validation in Pilot.

- Explicitly configure `istio-init` to run as root so use of pod-level `securityContext.runAsUser` doesn't break it ([Issue 5453](https://github.com/istio/istio/issues/5453)).

- Add configuration samples for Vault integration.

- Respect locality load balancing weight settings from `ServiceEntry`.

- Make the TLS certificate location watched by Pilot Agent configurable ([Issue 11984](https://github.com/istio/istio/issues/11984)).

- Add support for Datadog tracing.

- Add alias to `istioctl` so 'x' can be used instead of 'experimental'.

- Provide improved distribution of sidecar certificate by adding jitter to their CSR requests.

- Allow weighted load balancing registry locality to be configured.

- Add support for standard CRDs for compiled-in Mixer adapters.

- Reduce Pilot resource requirements for demo configuration.

- Fully populate Galley dashboard by adding data source ([Issue 13040](https://github.com/istio/istio/issues/13040)).

- Propagate Istio 1.1 `sidecar` performance tuning to the `istio-gateway`.

- Improve destination host validation by rejecting `*` hosts ([Issue 12794](https://github.com/istio/istio/issues/12794)).

- Expose upstream `idle_timeout` in cluster definition so dead connections can sometimes be removed from connection pools before they are used
([Issue 9113](https://github.com/istio/istio/issues/9113)).

- When registering a `Sidecar` resource to restrict what a pod can see, the restrictions are now applied if the spec contains a
`workloadSelector` ([Issue 11818](https://github.com/istio/istio/issues/11818)).

- Update the Bookinfo example to use port 80 for TLS origination.

- Add liveness probe for Citadel.

- Improve AWS ELB interoperability by making 15020 the first port listed in the `ingressgateway` service ([Issue 12502](https://github.com/istio/istio/issues/12503)).

- Use outlier detection for failover mode but not for distribute mode for locality weighted load balancing ([Issues 12965](https://github.com/istio/istio/issues/12961)).

- Replace generation of Envoy's deprecated `enabled` field in `CorsPolicy` with the replacement `filter_enabled` field for 1.1.0+ sidecars only.

- Standardize labels on Mixer's Helm charts.
