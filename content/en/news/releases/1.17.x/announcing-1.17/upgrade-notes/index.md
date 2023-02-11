---
title: Istio 1.17 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.17.
publishdate: 2023-02-14
weight: 20
---

When you upgrade from Istio 1.16.x to Istio 1.17, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio `1.16.x`.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio `1.16.x`.
Users upgrading from 1.15.x to Istio 1.17 should also reference the [1.16 change notes](/news/releases/1.16.x/announcing-1.16/change-notes/).

## Gateway naming scheme updated

If you are using the [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1beta1.Gateway)
to manage your Istio gateways, the names of the `Kubernetes Deployment` and `Service` has been modified. The default `Service Account` used has also switched to use its own token. To continue using the old convention during upgrades, the `gateway.istio.io/name-override` and `gateway.istio.io/service-account` annotations can be used.
