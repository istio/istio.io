---
title: "Gateway API Mesh Support Promoted To Stable"
description: The next-generation Kubernetes traffic routing APIs are now Generally Available for service mesh use cases. 
publishdate: 2024-05-13
attribution: John Howard - solo.io
keywords: [istio, traffic, API]
target_release: 1.22
---

We are thrilled to announce that Service Mesh support in the [Gateway API](https://gateway-api.sigs.k8s.io/) is now officially "Stable"!
With this release (part of Gateway API v1.1 and Istio v1.22), users can make use of the next-generation traffic management APIs for both ingress ("north-south") and service mesh use cases ("east-west").

## What is the Gateway API?

The Gateway API is a collection of APIs that are part of Kubernetes, focusing on traffic routing and management.
The APIs are inspired by, and serve many of the same roles as, Kubernetes' `Ingress` and Istio's `VirtualService` and `Gateway` APIs.

These APIs have been under development both in Istio, as well as with [broad collaboration](https://gateway-api.sigs.k8s.io/implementations/), since 2020, and have come a long way since then.
While the API initially targeted only serving ingress use cases (which went GA [last year](https://kubernetes.io/blog/2023/10/31/gateway-api-ga/)), we had always envisioned allowing the same APIs to be used for traffic *within* a cluster as well.

With this release, that vision is made a reality: Istio users can use the same routing API for all of their traffic!

## Getting started

Throughout the Istio documentation, all of our examples have been updated to show how to use the Gateway API, so explore some of the [tasks](/docs/tasks/traffic-management/) to gain a deeper understanding.

Using Gateway API for service mesh should feel familiar both to users already using Gateway API for ingress, and users using `VirtualService` for service mesh today.

* Compared to Gateway API for ingress, routes target a `Service` instead of a `Gateway`.
* Compared to `VirtualService`, where routes associate with a set of `hosts`, routes target a `Service`.

Here is a simple example, which demonstrates routing requests to two different versions of a `Service` based on the request header:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
      - name: my-favorite-service-mesh
        value: istio
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
      add:
        - name: hello
          value: world
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
{{< /text >}}

Breaking this down, we have a few parts:
* First, we identify what routes we should match.
  By attaching our route to the `reviews` Service, we will apply this routing configuration to all requests that were originally targeting `reviews`.
* Next, `matches` configures criteria for selecting which traffic this route should handle.
* Optionally, we can modify the request. Here, we add a header.
* Finally, we select a destination for the request. In this example, we are picking between two versions of our application.

For more details, see [Istio's traffic routing internals](/docs/ops/configuration/traffic-management/traffic-routing/) and [Gateway API's Service documentation](https://gateway-api.sigs.k8s.io/mesh/service-facets/).

## Which API should I use?

With overlapping responsibilities (and names!), picking which APIs to use can be a bit confusing.

Here is the breakdown:

| API Name     | Object Types                                                                                                                          | Status                            | Recommendation                                                             |
|--------------|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|----------------------------------------------------------------------------|
| Gateway APIs | [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/), [Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/), ... | Stable in Gateway API v1.0 (2023) | Use for new deployments, in particular with [ambient mode](/docs/ambient/) |
| Istio APIs   | [Virtual Service](/docs/reference/config/networking/virtual-service/), [Gateway](/docs/reference/config/networking/gateway/)          | `v1` in Istio 1.22 (2024)         | Use for existing deployments, or where advanced features are needed        |
| Ingress API  | [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress)                                                            | Stable in Kubernetes v1.19 (2020) | Use only for legacy deployments                                            |

You may wonder, given the above, why the Istio APIs were [promoted to `v1`](/blog/2024/v1-apis) concurrently?
This was part of an effort to accurate categorize the *stability* of the APIs.
While we view Gateway API as the future (and present!) of traffic routing APIs, our existing APIs are here to stay for the long run, with full compatibility.
This mirrors Kubernetes' approach with [`Ingress`](https://kubernetes.io/docs/concepts/services-networking/ingress), which was promoted to `v1` while directing future work towards the Gateway API.

## Community

This stability graduation represents the culmination of countless hours of work and collaboration across the project.
It is incredible to look at the [list of organizations](https://gateway-api.sigs.k8s.io/implementations/) involved in the API and consider back at how far we have come.

A special thanks goes out to my [co-leads on the effort](https://gateway-api.sigs.k8s.io/mesh/gamma/): Flynn, Keith Mattix, and Mike Morris, as well as the countless others involved.

Interested in getting involved, or even just providing feedback?
Check out Istio's [community page](/get-involved/) or the Gateway API [contributing guide](https://gateway-api.sigs.k8s.io/contributing/)!
