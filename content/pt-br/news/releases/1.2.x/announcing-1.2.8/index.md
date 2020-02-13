---
title: Announcing Istio 1.2.8
linktitle: 1.2.8
subtitle: Patch Release
description: Istio 1.2.8 patch release.
publishdate: 2019-10-23
release: 1.2.8
aliases:
    - /news/2019/announcing-1.2.8
    - /news/announcing-1.2.8
---

We're pleased to announce the availability of Istio 1.2.8. Please see below for what's changed.

{{< relnote >}}

## Bug fixes

- Fix a bug introduced by [our October 8th security release](/pt-br/news/security/istio-security-2019-005) which incorrectly calculated HTTP header and body sizes ([Issue 17735](https://github.com/istio/istio/issues/17735)).

- Fix a minor bug where endpoints still remained in /clusters while scaling a deployment to 0 replica ([Issue 14336](https://github.com/istio/istio/issues/14336)).

- Fix Helm upgrade process to correctly update mesh policy for mutual TLS ([Issue 16170](https://github.com/istio/istio/issues/16170)).

- Fix inconsistencies in the destination service label for TCP connection opened/closed metrics ([Issue 17234](https://github.com/istio/istio/issues/17234)).

- Fix the Istio secret cleanup mechanism ([Issue 17122](https://github.com/istio/istio/issues/17122)).

- Fix the Mixer Stackdriver adapter encoding process to handle invalid UTF-8 ([Issue 16966](https://github.com/istio/istio/issues/16966)).

## Features

- Add `pilot` support for the new failure domain labels: `zone` and `region`.
