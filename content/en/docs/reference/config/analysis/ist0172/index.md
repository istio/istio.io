---
title: FutureUnsupportedGatewayAPIVersion
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when [`istioctl x precheck`](/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
finds Kubernetes Gateway API CRDs that future versions of Istio will not support.

Future versions of Istio will require that the `Gateway`, `GatewayClass`, `HTTPRoute`, and `GRPCRoute`
CRDs serve the `v1` version.

## An example

You will receive a message like this:

{{< text plain >}}
Warning [IST0172] (CustomResourceDefinition httproutes.gateway.networking.k8s.io) The Gateway API CRD version v1beta1 is lower than the minimum version: v1
{{< /text >}}

## How to resolve

Upgrade the Gateway API CRDs to a version that serves `v1`. For the install command, refer to
[Kubernetes Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/).
