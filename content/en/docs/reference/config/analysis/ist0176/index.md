---
title: GatewayAPICRDVersionBelowMinimum
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a Kubernetes Gateway API CRD is installed at a version that is lower than the
minimum version that this version of Istio requires. Istio does not process resources of this kind.

The analyzer gets the installed version from the `gateway.networking.k8s.io/bundle-version` annotation
of the CRD.

## An example

You will receive a message like this:

{{< text plain >}}
Warning [IST0176] (CustomResourceDefinition tlsroutes.gateway.networking.k8s.io) Gateway API CRD "tlsroutes.gateway.networking.k8s.io" is at version "1.2.0" but Istio requires at least "1.5.0"; resources of this kind will not be processed. Upgrade the Gateway API CRDs to satisfy the minimum version.
{{< /text >}}

## How to resolve

Upgrade the Gateway API CRDs. For the install command, refer to
[Kubernetes Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/).
