---
title: NegativeConditionStatus
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when the status of a resource has a condition that shows a problem.

The analyzer examines these conditions:

| Kind | Condition | Negative status |
|------|-----------|-----------------|
| `Service`, `ServiceEntry`, `WorkloadEntry` | `istio.io/WaypointBound` | `False` |
| `AuthorizationPolicy` | `ZtunnelAccepted`, `WaypointAccepted` | `False` |
| `AuthorizationPolicy` | `WaypointAccepted` with the reason `PartiallyInvalid` | `True` |
| `Gateway`, `HTTPRoute`, `GRPCRoute` (Kubernetes Gateway API) | `Accepted`, `Programmed`, `ResolvedRefs` | `False` |

## An example

You will receive a message like this:

{{< text plain >}}
Warning [IST0171] (HTTPRoute default/httpbin) A condition with a negative status is present: type=ResolvedRefs, reason=BackendNotFound, message=backend(httpbin.default.svc.cluster.local) not found.
{{< /text >}}

## How to resolve

Read the reason and the message of the condition. They tell you what the problem is. Fix the resource,
or the resources that it refers to.
