---
title: Announcing Istio 1.11.3
linktitle: 1.11.3
subtitle: Patch Release
description: Istio 1.11.3 patch release.
publishdate: 2021-09-23
release: 1.11.3
aliases:
    - /news/announcing-1.11.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.11.2 and Istio 1.11.3

{{< relnote >}}

## Changes

- **Updated** to allow specifying NICs that bypassing traffic capture in Istio iptables.
  ([Issue #34753](https://github.com/istio/istio/issues/34753))

- **Added** values to the Istio Gateway Helm charts for configuring annotations on the `ServiceAccount`.  Can be used to enable [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) on AWS EKS.

- **Fixed** `istioctl analyze` command to not output [IST0132] message when analyzing the gateway of the virtual service.
  ([Issue #34653](https://github.com/istio/istio/issues/34653))

- **Fixed** a bug using a Service's pointer address to get its instances in the case where a sidecar's egress listener has a port.

- **Fixed** a bug in the "image: auto" analyzer causing it to fail to take into account the Deployment namespace.
  ([Issue #34929](https://github.com/istio/istio/issues/34929))

- **Fixed** `istioctl x workload` command output to set the correct `discoveryAddress` for revisioned control-planes.
  ([Issue #34058](https://github.com/istio/istio/issues/34058))

- **Fixed** gateway analyzer message reporting if there is no selector in the gateway spec.
  ([Issue #35093](https://github.com/istio/istio/issues/35093))

- **Fixed** an issue causing memory to not be freed after XDS clients disconnect.

- **Fixed** an issue occurring when multiple `VirtualServices` with the same name exist in different namespaces.
  ([Issue #35127](https://github.com/istio/istio/issues/35127))
