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

- **Added** two mutually-exclusive flags to `istioctl x workload entry configure`

* `--internal-ip` configures the VM workload with a private IP address used for workload auto registration and health probes.
* `--external-ip` configures the VM workload with a public IP address used for workload auto registration. Meanwhile, it configures health probes to be performed through localhost. By setting the environment variable `REWRITE_PROBE_LEGACY_LOCALHOST_DESTINATION` to true.
  ([Issue #34411](https://github.com/istio/istio/issues/34411))

- **Added** topology label "topology.istio.io/network" to IstioEndpoint if it does not exist in pod/workload label.

- **Fixed** `istioctl profile diff` and `istioctl profile dump` have unexpected info logs.

- **Fixed** the deployment analyzer is ignoring service namespaces during the analysis process.

- **Fixed** `DestinationRule` updates not triggering an update for `AUTO_PASSTHROUGH` listeners on gateways.
  ([Issue #34944](https://github.com/istio/istio/issues/34944))

