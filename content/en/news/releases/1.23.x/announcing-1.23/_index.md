---
title: Announcing Istio 1.23.0
linktitle: 1.23.0
subtitle: Major Release
description: Istio 1.23 Release Announcement.
publishdate: 2024-08-13
release: 1.23.0
---

We are pleased to announce the release of Istio 1.23. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.23.0 release published.

We would like to thank the Release Managers for this release, **Sumit Vij** from Credit Karma, **Zhonghu Xu** from Huawei and **Mike Morris** from Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.23.0 is officially supported on Kubernetes versions `1.27` to `1.30`.
{{< /tip >}}

## What's new

###TODO

## Upgrading to 1.23

### Internal API protobuf changes
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

Would you like to contribute directly to Istio? Find and join one of
our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
