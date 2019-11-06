---
title: Announcing Istio 1.2.1
description: Istio 1.2.1 patch release.
publishdate: 2019-06-27
attribution: The Istio Team
release: 1.2.1
aliases:
    - /about/notes/1.2.1
    - /blog/2019/announcing-1.2.1
    - /news/announcing-1.2.1
---

We're pleased to announce the availability of Istio 1.2.1. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix duplicate CRD being generated in the install ([Issue 14976](https://github.com/istio/istio/issues/14976))
- Fix Mixer unable to start when Galley is disabled ([Issue 14841](https://github.com/istio/istio/issues/14841))
- Fix environment variable shadowing (NAMESPACE is used for listened namespaces and overwrites Citadel storage namespace (istio-system))
- Fix cause of 'TLS error: Secret is not supplied by SDS' errors during upgrade ([Issue 15020](https://github.com/istio/istio/issues/15020))

## Minor enhancements

- Allow users to disable Istio default retries by setting retries to 0 ([Issue 14900](https://github.com/istio/istio/issues/14900))
- Introduction of a Redis filter (this feature is guarded with the environment feature flag `PILOT_ENABLE_REDIS_FILTER`, disabled by default)
- Add HTTP/1.0 support to gateway configuration generation ([Issue 13085](https://github.com/istio/istio/issues/13085))
- Add [toleration](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/) for Istio components ([Pull Request 15081](https://github.com/istio/istio/pull/15081))
