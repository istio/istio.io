---
title: EnvoyFilterMayClearRouteCache
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when an `AuthorizationPolicy` targets an `HTTPRoute`, and an `EnvoyFilter` adds an HTTP
filter to a gateway or a waypoint.

A policy that targets an `HTTPRoute` depends on the route that Envoy selects. If a filter that runs after
the policy changes the request and clears the route cache, Envoy can select a different route. The request
can then go to a destination that the policy did not examine. For more information, refer to the
[Envoy security considerations](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_filters.html#security-considerations).

The analyzer does not examine `EnvoyFilter` patches with the `SIDECAR_INBOUND` or `SIDECAR_OUTBOUND` context.

## An example

You will receive a message like this:

{{< text plain >}}
Warning [IST0178] (EnvoyFilter istio-system/add-header) Using an EnvoyFilter with route-dependent filters may cause the routing cache to be cleared after the route-dependent filter has run. This can cause a request to be routed differently than it was when the route-dependent filter was evaluated. See https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_filters.html#security-considerations.
{{< /text >}}

## How to resolve

Make sure that the HTTP filters that the `EnvoyFilter` adds do not change the route of a request after
the authorization filter runs. If you cannot do this, do not use `AuthorizationPolicy` resources that
target an `HTTPRoute` together with this `EnvoyFilter`.
