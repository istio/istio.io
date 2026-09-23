---
title: Istio 1.23 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.23.0.
weight: 20
publishdate: 2024-08-14
---

When upgrading from Istio 1.22.x to Istio 1.23.x, please consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.22.x.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.22.x.

## Internal API protobuf changes

If you do not use Istio APIs from Go (via `istio.io/api` or `istio.io/client-go`) or Protobuf (from `istio.io/api`), this change does not impact you.

In prior versions, Istio APIs had identical contents replicated across multiple versions.
For example, the same `VirtualService` protobuf message is defined 3 times (`v1alpha3`, `v1beta1`, and `v1`).
These schemas are identical except in the package they reside in.

In this version of Istio, these have been consolidated down to a single version.
For resources that had multiple versions, the oldest version is retained.

* If you use Istio APIs only via Kubernetes (YAML), there is no impact at all.
* If you use Istio APIs by Go types, there is essentially no impact.
  Each removed version has been replaced with type aliases to the remaining version, ensuring backwards compatibility.
  However, niche use cases (reflection, etc) may have some impact.
* If you use Istio APIs directly by Protobuf, and use newer versions, these will no longer be included as part of the API.
  Please reach out to the team if you are impacted.
