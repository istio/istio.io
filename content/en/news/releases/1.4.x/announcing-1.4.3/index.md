---
title: Announcing Istio 1.4.3
linktitle: 1.4.3
subtitle: Patch Release
description: Istio 1.4.3 patch release.
publishdate: 2020-01-08
release: 1.4.3
aliases:
    - /news/announcing-1.4.3
---

This release includes bug fixes to improve robustness and user experience. This release note describes what’s different between Istio 1.4.2 and Istio 1.4.3.

{{< relnote >}}

## Bug fixes

- **Fixed** an issue where Mixer creates too many watches, overloading `kube-apiserver` ([Issue 19481](https://github.com/istio/istio/issues/19481)).
- **Fixed** an issue with injection when pod has multiple containers without exposed ports ([Issue 18594](https://github.com/istio/istio/issues/18594)).
- **Fixed** overly restrictive validation of `regex` field ([Issue 19212](https://github.com/istio/istio/pull/19212)).
- **Fixed** an upgrade issue with `regex` field ([Issue 19665](https://github.com/istio/istio/pull/19665)).
- **Fixed** `istioctl` install to properly send logs to `stderr` ([Issue 17743](https://github.com/istio/istio/issues/17743)).
- **Fixed** an issue where a file and profile could not be specified for `istioctl` installs ([Issue 19503](https://github.com/istio/istio/issues/19503)).
- **Fixed** an issue preventing certain objects from being installed for `istioctl` installs ([Issue 19371](https://github.com/istio/istio/issues/19371)).
- **Fixed** an issue preventing using certain JWKS with EC keys in JWT policy ([Issue 19424](https://github.com/istio/istio/issues/19424)).

## Improvements

- **Improved** injection template to fully specify `securityContext`, allowing `PodSecurityPolicies` to properly validate injected deployments ([Issue 17318](https://github.com/istio/istio/issues/17318)).
- **Improved** telemetry v2 configuration to support Stackdriver and forward compatibility ([Issue 591](https://github.com/istio/installer/pull/591).
- **Improved** output of `istioctl` installation ([Issue 19451](https://github.com/istio/istio/issues/19451).
- **Improved** `istioctl` installation to set exit code upon failure ([Issue 19747](https://github.com/istio/istio/issues/19747)).
