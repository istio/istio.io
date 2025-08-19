---
title: Announcing Istio 1.15.1
linktitle: 1.15.1
subtitle: Patch Release
description: Istio 1.15.1 patch release.
publishdate: 2022-09-23
release: 1.15.1
---

This release contains bug fixes to improve robustness.

This release note describes what is different between Istio 1.15.0 and Istio 1.15.1.

{{< relnote >}}

## Changes

- **Fixed** an issue where `AddRunningKubeSourceWithRevision` returns an error causing the Istio Operator
to go into an error loop. ([Issue #39599](https://github.com/istio/istio/issues/39599))

- **Fixed** an issue where adding a `ServiceEntry` could affect an existing `ServiceEntry` with the same hostname.
([Issue #40166](https://github.com/istio/istio/issues/40166))

- **Fixed** an issue where user can not delete Istio Operator resource with revision if istiod is not running.
([Issue #40796](https://github.com/istio/istio/issues/40796))

- **Fixed** an issue when telemetry access logs is nil, will not fallback to use MeshConfig.

- **Fixed** an issue that built-in provider should fallback to MeshConfig when format is unset.

- **Fixed** an issue with where a `DestinationRule` applying to multiple services could incorrectly apply
an unexpected `subjectAltNames` field. ([Issue #40801](https://github.com/istio/istio/issues/40801))

- **Fixed** a behavioral change in 1.15.0 causing the `ServiceEntry` `SubjectAltName` field to be ignored.
([Issue #40801](https://github.com/istio/istio/issues/40801))

- **Improved** xDS pushing to trigger partial pushes when scaling workloads down to zero instances and back up.
([Issue #39652](https://github.com/istio/istio/issues/39652))

- **Added** `PILOT_ENABLE_K8S_SELECT_WORKLOAD_ENTRIES` feature back to Istio which was removed in 1.14. Will
persist until the use case is clarified and more permanent API added. ([Pull Request #40716](https://github.com/istio/istio/pull/40716))
