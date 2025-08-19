---
title: Announcing Istio 1.10.5
linktitle: 1.10.5
subtitle: Patch Release
description: Istio 1.10.5 patch release.
publishdate: 2021-10-07
release: 1.10.5
aliases:
    - /news/announcing-1.10.5
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.10.4 and Istio 1.10.5.

{{< relnote >}}

## Changes

- **Improved** `istioctl install` to give more details when encountering installation failures.

- **Added** values to the Istio Gateway Helm charts for configuring ServiceAccount annotations.  Can be used to enable [IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) on AWS EKS.
  ([Issue #34837](https://github.com/istio/istio/issues/34837))

- **Fixed** an issue causing `istioctl profile diff` and `istioctl profile dump` to output unexpected info logs.

- **Fixed** an issue causing `istioctl analyze` to show an unexpected `IST0132` message when analyzing the gateway associated with a virtual service.
  ([Issue #34653](https://github.com/istio/istio/issues/34653))

- **Fixed** an issue causing the deployment analyzer to ignore service namespaces during the analysis process.

- **Fixed** an issue resulting in `DestinationRule` updates not triggering updates for `AUTO_PASSTHROUGH` listeners on gateways.
  ([Issue #34944](https://github.com/istio/istio/issues/34944))

- **Fixed** an issue causing memory to not be freed after XDS clients disconnect.
