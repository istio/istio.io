---
title: Announcing Istio 1.14.4
linktitle: 1.14.4
subtitle: Patch Release
description: Istio 1.14.4 patch release.
publishdate: 2022-09-12
release: 1.14.4
---

This release contains bug fixes to improve robustness.
This release note describes what’s different between Istio 1.14.3 and Istio 1.14.4.

{{< relnote >}}

## Changes

- **Added** support for `ALPN` negotiation to Istio [health checks](/docs/ops/configuration/mesh/app-health-check/), mirroring
how `Kubelet` functions. This allows `HTTPS` type probes to use `HTTP2`. To revert to the older behavior,
which always used `HTTP/1.1`, you can set the `ISTIO_ENABLE_HTTP2_PROBING=false` variable.

- **Added** `PILOT_ENABLE_K8S_SELECT_WORKLOAD_ENTRIES` feature back to Istio which was removed in 1.14.
The feature will persist until the use case is clarified and a more permanent API is added.

- **Fixed** the `%REQ_WITHOUT_QUERY(X?:Y):Z%` command operator, which should now work when using `JSON` encoding
for the log format. ([Issue #39271](https://github.com/istio/istio/issues/39271))

- **Fixed** an issue where Istio did not update the list of endpoints in `STRICT_DNS` clusters
during workload instance updates. ([Issue #39505](https://github.com/istio/istio/issues/39505))

- **Fixed** analyze `ConflictingMeshGatewayVirtualServiceHosts` (`IST0109`) message,
appearing when using `exportTo` to a specific namespace. ([Issue #39634](https://github.com/istio/istio/issues/39634))

- **Fixed** an issue where `istioctl analyze` started showing invalid warning messages.

- **Fixed** `IST0103` warning from `istioctl analyze` for non-injected pods on the host network.

- **Fixed** an issue when there is `Bind` specified in the Gateway with same hosts,
listeners are not generated correctly. ([Issue #40268](https://github.com/istio/istio/issues/40268))

- **Fixed** `istioctl install` to not show a warning message when `values.pilot.replicaCount` is set
to its default value. ([Issue #40246](https://github.com/istio/istio/issues/40246))

- **Fixed** an issue where a service, with and without Virtual Service timeouts specified,
is incorrectly setting the timeouts.  ([Issue #40299](https://github.com/istio/istio/issues/40299))

- **Fixed** an issue preventing the Istio ingress/egress gateway from matching any nodes. ([Issue #40378](https://github.com/istio/istio/issues/40378))

- **Fixed** an issue where `ProxyConfig` overrides could unexpectedly apply to other workloads.
  ([Issue #40445](https://github.com/istio/istio/issues/40445))

- **Fixed** an issue causing TLS `ServiceEntries` to sometimes not work when created after TCP ones.

- **Fixed** potential memory leak when updating hostname of service entries.
