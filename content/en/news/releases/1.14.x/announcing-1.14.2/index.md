---
title: Announcing Istio 1.14.2
linktitle: 1.14.2
subtitle: Patch Release
description: Istio 1.14.2 patch release.
publishdate: 2022-07-25
release: 1.14.2
---

{{< warning >}}
Istio 1.14.2 does not contain a fix for [CVE-2022-31045](/news/security/istio-security-2022-005/#cve-2022-31045). We recommend users to not install Istio 1.14.2
and use Istio 1.14.1 for now. Istio 1.14.3 will be released later this week.
{{< /warning >}}

This release contains bug fixes to improve robustness and some additional support.
This release note describes what’s different between Istio 1.14.1 and Istio 1.14.2.

FYI, [Go 1.18.4 has been released](https://groups.google.com/g/golang-announce/c/nqrv9fbR0zE),
which includes 9 security fixes. We recommend you to upgrade to this newer Go version if you are using Go locally.

{{< relnote >}}

## Changes

- **Added** `istioctl experimental envoy-stats -o prom-merged` for retrieving `istio-proxy` merged metrics from Prometheus.
  ([Issue #39454](https://github.com/istio/istio/issues/39454))

- **Added** support for Kubernetes 1.25 by using new `HorizontalPodAutoscaler` and `PodDisruptionBudget` API versions when supported.

- **Added** the ability to read `kubernetes.io/tls` type `cacerts` secrets.
  ([Issue #38528](https://github.com/istio/istio/issues/38528))

- **Fixed** a bug when updating a multi-cluster secret, the previous cluster is not stopped. Even deleting the secret will not stop the previous cluster.  ([Issue #39366](https://github.com/istio/istio/issues/39366))

- **Fixed** a bug where specifying `warmupDuration` without `Lb` policy is not configuring the warmup duration.  ([Issue #39430](https://github.com/istio/istio/issues/39430))

- **Fixed** a bug when sending access logging to injected `OTel-collector` pod throws a `http2.invalid.header.field` error.  ([Issue #39196](https://github.com/istio/istio/issues/39196))

- **Fixed** an issue where Istio is sending traffic to unready pods when `PILOT_SEND_UNHEALTHY_ENDPOINTS` is enabled.
  ([Issue #39825](https://github.com/istio/istio/issues/39825))

- **Fixed** an issue causing Service merging to only take into account the first and last Service, rather than all of them.

- **Fixed** an issue where the `ProxyConfig` image type is not taking effect.
  ([Issue #38959](https://github.com/istio/istio/issues/38959))
