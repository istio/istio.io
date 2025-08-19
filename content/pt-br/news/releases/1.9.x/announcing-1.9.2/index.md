---
title: Announcing Istio 1.9.2
linktitle: 1.9.2
subtitle: Patch Release
description: Istio 1.9.2 patch release.
publishdate: 2021-03-25
release: 1.9.2
aliases:
    - /news/announcing-1.9.2
---

This release note describes what’s different between Istio 1.9.1 and Istio 1.9.2.

{{< relnote >}}

## Changes

- **Fixed** an issue so transport socket parameters are now taken into account when configured in `EnvoyFilter`
  ([Issue #28996](https://github.com/istio/istio/issues/28996))

- **Fixed** a bug causing runaway logs in `istiod` after disabling the default ingress controller.
  ([Issue #31336](https://github.com/istio/istio/issues/31336))

- **Fixed** an issue so the Kubernetes API server is now considered to be cluster-local by default. This means that any
pod attempting to reach `kubernetes.default.svc` will always be directed to the in-cluster server.
  ([Issue #31340](https://github.com/istio/istio/issues/31340))

- **Fixed** an issue with metadata handling for the Azure platform, allowing
`tagsList` serialization of tags on instance metadata.
  ([Issue #31176](https://github.com/istio/istio/issues/31176))

- **Fixed** an issue with DNS proxying causing `StatefulSets` addresses to not be load balanced.
  ([Issue #31064](https://github.com/istio/istio/issues/31064))
