---
title: Announcing Istio 1.13.3
linktitle: 1.13.3
subtitle: Patch Release
description: Istio 1.13.3 patch release.
publishdate: 2022-04-18
release: 1.13.3
aliases:
    - /news/announcing-1.13.3
---

This release contains bug fixes to improve robustness and some additional configuration support.
This release note describes what's different between Istio 1.13.2 and 1.13.3.

{{< relnote >}}

## Changes

- **Added** support for skipping the initial installation of CNI entirely.

- **Added** values to the istiod Helm charts for configuring affinity rules and toleration on the Deployment.
  This can be used for better placement of istiod instances.

- **Fixed** an issue where platform detection took 5 seconds on Minikube.
  ([Issue #37832](https://github.com/istio/istio/issues/37832))

- **Fixed** an issue where removing a HTTP filter did not work properly.

- **Fixed** an issue causing some cross-namespace VirtualService to be incorrectly ignored after upgrading to Istio 1.12+.
  ([Issue #37691](https://github.com/istio/istio/issues/37691))
