---
title: UnsupportedGatewayAPIVersion
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when [`istioctl x precheck`](/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
finds Kubernetes Gateway API CRDs that this version of Istio does not support.

Istio requires that the `Gateway`, `GatewayClass`, `HTTPRoute`, and `ReferenceGrant` CRDs serve the
`v1beta1` version.

## An example

You will receive a message like this:

{{< text plain >}}
Error [IST0156] (CustomResourceDefinition httproutes.gateway.networking.k8s.io) The Gateway API CRD version v1alpha2 is lower than the minimum version: v1beta1
{{< /text >}}

## How to resolve

Upgrade the Gateway API CRDs to a supported version. For the install command, refer to
[Kubernetes Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/).
