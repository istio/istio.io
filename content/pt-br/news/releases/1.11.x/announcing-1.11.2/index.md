---
title: Announcing Istio 1.11.2
linktitle: 1.11.2
subtitle: Patch Release
description: Istio 1.11.2 patch release.
publishdate: 2021-09-02
release: 1.11.2
aliases:
    - /news/announcing-1.11.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.11.1 and Istio 1.11.2.

{{< relnote >}}

## Changes

- **Improved** `istioctl install` to give more details during installation failures.

- **Added** support for gRPC configuring workloads via xDS without an Envoy proxy.

- **Added** two mutually-exclusive flags to `istioctl x workload entry configure`
    - **`--internal-ip`** configures the VM workload with a private IP address used for workload auto registration and health probes.
    - **`--external-ip`** configures the VM workload with a public IP address used for workload auto registration. Meanwhile, it configures health probes to be performed through localhost by setting the environment variable `REWRITE_PROBE_LEGACY_LOCALHOST_DESTINATION` to true.
  ([Issue #34411](https://github.com/istio/istio/issues/34411))

- **Added** topology label `topology.istio.io/network` to `IstioEndpoint` if it does not exist in pod/workload label.

- **Added** a configuration `FILE_DEBOUNCE_DURATION` that allows users to configure the duration SDS server should wait after it sees first file change event. This is useful in File mounted certificate flows to ensure key and cert are fully written before they are pushed to Envoy. Default is `100ms`.

- **Fixed** unexpected info logs for Istio when using command line tool `istioctl profile diff` and `istioctl profile dump`.

- **Fixed** issue of deployment analyzer ignoring service namespaces during the analysis process.

- **Fixed** `DestinationRule` updates not triggering an update for `AUTO_PASSTHROUGH` listeners on gateways.
  ([Issue #34944](https://github.com/istio/istio/issues/34944))
