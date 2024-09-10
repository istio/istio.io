---
title: Announcing Istio 1.23.1
linktitle: 1.23.1
subtitle: Patch Release
description: Istio 1.23.1 patch release.
publishdate: 2024-09-10
release: 1.23.1
---

This release note describes what is different between Istio 1.23.0 and 1.23.1.

{{< relnote >}}

## Changes

- **Fixed** an issue where controller-assigned IPs did not respect per-proxy DNS capture the same way that ephemeral auto-allocated IPs did.
  ([Issue #52609](https://github.com/istio/istio/issues/52609))

- **Fixed** an issue where waypoints required DNS proxy to be enabled in order to consume auto-allocated IPs.
  ([Issue #52746](https://github.com/istio/istio/issues/52746))

- **Fixed** an issue where the `ISTIO_OUTPUT` `iptables` chain was not removed with `pilot-agent istio-clean-iptables` command.
  ([Issue #52835](https://github.com/istio/istio/issues/52835))

- **Fixed** an issue causing any `portLevelSettings` to be ignored in `DestinationRule`s for waypoints.
  ([Issue #52532](https://github.com/istio/istio/issues/52532))

- **Removed** writing `kubeconfig` to CNI net directory.
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

- **Removed** `CNI_NET_DIR` from the `istio-cni` `ConfigMap`, as it now does nothing.
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

- **Removed** a change in Istio 1.23.0 causing regressions for `ServiceEntries` with multiple addresses defined.
  Note: the reverted change did fix an issue around missing addresses (#51747), but introduce a new set of issues.
  The original issue can be worked around by creating a sidecar resource.
  ([Issue #52944](https://github.com/istio/istio/issues/52944)),([Issue #52847](https://github.com/istio/istio/issues/52847))
