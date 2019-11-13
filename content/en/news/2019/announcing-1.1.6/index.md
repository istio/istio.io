---
title: Announcing Istio 1.1.6
subtitle: Patch Release
description: Istio 1.1.6 patch release.
publishdate: 2019-05-11
release: 1.1.6
aliases:
    - /about/notes/1.1.6
    - /blog/2019/announcing-1.1.6
    - /news/announcing-1.1.6
---

We're pleased to announce the availability of Istio 1.1.6. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix Galley Helm charts so that the `validatingwebhookconfiguration` object can now deployed to a namespace other than `istio-system` ([Issue 13625](https://github.com/istio/istio/issues/13625)).
- Additional Helm chart fixes for anti-affinity support: fix `gatewaypodAntiAffinityRequiredDuringScheduling` and `podAntiAffinityLabelSelector` match expressions and fix the default value for `podAntiAffinityLabelSelector` ([Issue 13892](https://github.com/istio/istio/issues/13892)).
- Make Pilot handle a condition where Envoy continues to request routes for a deleted gateway while listeners are still draining ([Issue 13739](https://github.com/istio/istio/issues/13739)).

## Small enhancements

- If access logs are enabled, `passthrough` listener requests will be logged.
- Make Pilot tolerate unknown JSON fields to make it easier to rollback to older versions during upgrade.
- Add support for fallback secrets to `SDS` which Envoy can use instead of waiting indefinitely for late or non-existent secrets during startup ([Issue 13853](https://github.com/istio/istio/issues/13853)).
