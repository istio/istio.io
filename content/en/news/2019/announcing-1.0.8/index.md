---
title: Announcing Istio 1.0.8
description: Istio 1.0.8 patch release.
publishdate: 2019-06-07
attribution: The Istio Team
release: 1.0.8
aliases:
    - /about/notes/1.0.8
    - /blog/2019/announcing-1.0.8
---

We're pleased to announce the availability of Istio 1.0.8. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix issue where Citadel could generate a new root CA if it cannot contact the Kubernetes API server, causing mutual TLS verification to incorrectly fail ([Issue 14512](https://github.com/istio/istio/issues/14512)).

## Small enhancements

- Update Citadel's default root CA certificate TTL from 1 year to 10 years.
