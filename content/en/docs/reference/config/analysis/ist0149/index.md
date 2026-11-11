---
title: JwtClaimBasedRoutingWithoutRequestAuthN
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a `VirtualService` that is bound to a gateway routes traffic based on JWT
claims, but no `RequestAuthentication` applies to the gateway pods.

The gateway must validate the JWT before the claims are available for routing. Without a
`RequestAuthentication`, the routes that match on `@request.auth.claims` do not work.

## An example

Consider this `VirtualService`, when no `RequestAuthentication` selects the gateway pods:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
      headers:
        "@request.auth.claims.groups":
          exact: group1
    route:
    - destination:
        host: httpbin
{{< /text >}}

You will receive a message like this:

{{< text plain >}}
Error [IST0149] (VirtualService default/httpbin) The virtual service uses the JWT claim based routing (key: groups) but found no request authentication for the gateway (default/httpbin-gateway) pod (istio-ingressgateway-5bdb6f9c8b-xk2vz). The request authentication must first be applied for the gateway pods to validate the JWT token and make the claims available for routing.
{{< /text >}}

## How to resolve

Apply a `RequestAuthentication` that selects the gateway pods, in the namespace of the gateway pods or
in the root namespace. For an example, refer to
[JWT claim based routing](/docs/tasks/security/authentication/jwt-route/).
