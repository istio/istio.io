---
title: Announcing Istio 1.8.4
linktitle: 1.8.4
subtitle: Patch Release
description: Istio 1.8.4 patch release.
publishdate: 2021-03-10
release: 1.8.4
aliases:
    - /news/announcing-1.8.4
---

This release contains bug fixes to improve stability. This release note describes what’s different between Istio 1.8.3 and Istio 1.8.4

{{< relnote >}}

## Changes

- **Fixed** issue with metadata handling for Azure platform. Support added for `tagsList` serialization of tags on instance metadata.
  ([Issue #31176](https://github.com/istio/istio/issues/31176))

- **Fixed** an issue causing an alternative Envoy binary to be included in the docker image. The binaries are functionally equivalent.
  ([Issue #31038](https://github.com/istio/istio/issues/31038))

- **Fixed** an issue causing HTTP headers to be duplicated when using Istio probe rewrite.
  ([Issue #28466](https://github.com/istio/istio/issues/28466))
