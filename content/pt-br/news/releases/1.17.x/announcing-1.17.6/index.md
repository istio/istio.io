---
title: Announcing Istio 1.17.6
linktitle: 1.17.6
subtitle: Patch Release
description: Istio 1.17.6 patch release.
publishdate: 2023-09-19
release: 1.17.6
---

This release contains bug fixes to improve robustness. This release note describes what is different between Istio 1.17.5 and Istio 1.17.6.

{{< relnote >}}

## Changes

- **Fixed** a SELinux issue on CentOS 9/RHEL 9 where iptables-restore isn't allowed to open files in `/tmp`. Rules passed to iptables-restore are no longer written to a file, but are passed via stdin. ([Issue #42485](https://github.com/istio/istio/issues/42485))

- **Fixed** an issue that Istio should prefer `IMDSv2` on AWS. ([Issue #45825](https://github.com/istio/istio/issues/45825))

- **Fixed** an issue where `meshConfig.defaultConfig.sampling` is ignored when there are only default providers. ([Issue #46653](https://github.com/istio/istio/issues/46653))

- **Fixed** an issue where the creation of a telemetry object without any providers throws the IST0157 error. ([Issue #46510](https://github.com/istio/istio/issues/46510))
