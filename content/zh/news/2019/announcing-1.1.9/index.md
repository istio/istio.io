---
title: Announcing Istio 1.1.9
description: Istio 1.1.9 patch release.
publishdate: 2019-06-17
attribution: The Istio Team
release: 1.1.9
aliases:
    - /zh/about/notes/1.1.9
    - /zh/blog/2019/announcing-1.1.9
    - /zh/news/announcing-1.1.9
---

We're pleased to announce the availability of Istio 1.1.9. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Prevent overly large strings from being sent to Prometheus ([Issue 14642](https://github.com/istio/istio/issues/14642)).
- Reuse previously cached JWT public keys if transport errors are encountered during renewal ([Issue 14638](https://github.com/istio/istio/issues/14638)).
- Bypass JWT authentication for HTTP OPTIONS methods to support CORS requests.
- Fix Envoy crash caused by the Mixer filter ([Issue 14707](https://github.com/istio/istio/issues/14707)).

## Small enhancements

- Expose cryptographic signature verification functions to `Lua` Envoy filters ([Envoy Issue 7009](https://github.com/envoyproxy/envoy/issues/7009)).
