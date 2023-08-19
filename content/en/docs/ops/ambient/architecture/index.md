---
title: Ambient Mesh Architecture
description: Deep dive into ambient mesh architecture.
weight: 3
owner: istio/wg-networking-maintainers
test: n/a
---

## Differences from sidecar architecture

### Istio and sidecars

Since its inception, a defining feature of Istio’s architecture has been the use of _sidecars_ – programmable proxies deployed alongside application containers.  Sidecars allow operators to reap Istio’s benefits, without requiring applications to undergo major surgery and its associated costs.

{{< image width="100%"
    link="/blog/2022/introducing-ambient-mesh/traditional-istio.png"
    caption="Istio’s traditional model deploys Envoy proxies as sidecars within the workloads’ pods"
    >}}

Although sidecars have significant advantages over refactoring applications, they do not provide a perfect separation between applications and the Istio data plane. This results in a few limitations:

* **Invasiveness** - Sidecars must be "injected" into applications by modifying their Kubernetes pod spec and redirecting traffic within the pod.   As a result, installing or upgrading sidecars requires restarting the application pod, which can be disruptive for workloads.
* **Underutilization of resources** - Since the sidecar proxy is dedicated to its associated workload, the CPU and memory resources must be provisioned for worst case usage of each individual pod. This adds up to large reservations that can lead to underutilization of resources across the cluster.
* **Traffic breaking** - Traffic capture and HTTP processing, as typically done by Istio’s sidecars, is computationally expensive and can break some applications with non-conformant HTTP implementations.

While sidecars have their place — more on that later — we think there is a need for a less invasive and easier option that will be a better fit for many service mesh users.

### Slicing the layers

Traditionally, Istio implements all data plane functionality, from basic encryption through advanced L7 policy, in a single architectural component: the sidecar.
In practice, this makes sidecars an all-or-nothing proposition.
Even if a workload just needs simple transport security, administrators still need to pay the operational cost of deploying and maintaining a sidecar.
Sidecars have a fixed operational cost per workload that does not scale to fit the complexity of the use case.

Ambient mesh takes a different approach.
It splits Istio’s functionality into two distinct layers.
At the base, there’s a secure overlay that handles routing and zero trust security for traffic.
Above that, when needed, users can enable L7 processing to get access to the full range of Istio features.
The L7 processing mode, while heavier than the secure overlay, still runs as an ambient component of the infrastructure, requiring no modifications to application pods.

{{< image width="100%"
    link="/blog/2022/introducing-ambient-mesh/ambient-layers.png"
    caption="Layers of the ambient mesh"
    >}}

This layered approach allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure overlay, to full L7 processing — on a per-namespace basis, as needed.   Furthermore, workloads running in different ambient modes, or with sidecars, interoperate seamlessly, allowing users to mix and match capabilities based on the particular needs as they change over time.

## Building an ambient mesh

Ambient mesh uses a shared agent, running on each node in the Kubernetes cluster.  This agent is a zero-trust tunnel (or **_ztunnel_**), and its primary responsibility is to securely connect and authenticate elements within the mesh.  The networking stack on the node redirects all traffic of participating workloads through the local ztunnel agent. This fully separates the concerns of Istio’s data plane from those of the application, ultimately allowing operators to enable, disable, scale, and upgrade the data plane without disturbing applications. The ztunnel performs no L7 processing on workload traffic, making it significantly leaner than sidecars.  This large reduction in complexity and associated resource costs make it amenable to delivery as shared infrastructure.

Ztunnels enable the core functionality of a service mesh: zero trust.  A secure overlay is created when ambient is enabled for a namespace.  It provides workloads with mTLS, telemetry, authentication, and L4 authorization, without terminating or parsing HTTP.

{{< image width="100%"
    link="/blog/2022/introducing-ambient-mesh/ambient-secure-overlay.png"
    caption="Ambient mesh uses a shared, per-node ztunnel to provide a zero-trust secure overlay"
    >}}

After ambient mesh is enabled and a secure overlay is created, a namespace can be configured to utilize L7 features.
This allows a namespace to implement the full set of Istio capabilities, including the [Virtual Service API](/docs/reference/config/networking/virtual-service/), [L7 telemetry](/docs/reference/config/telemetry/), and [L7 authorization policies](/docs/reference/config/security/authorization-policy/).
Namespaces operating in this mode use one or more Envoy-based **_waypoint proxies_** to handle L7 processing for workloads in that namespace.
Istio’s control plane configures the ztunnels in the cluster to pass all traffic that requires L7 processing through the waypoint proxy.
Importantly, from a Kubernetes perspective, waypoint proxies are just regular pods that can be auto-scaled like any other Kubernetes deployment.
We expect this to yield significant resource savings for users, as the waypoint proxies can be auto-scaled to fit the real time traffic demand of the namespaces they serve, not the maximum worst-case load operators expect.

{{< image width="100%"
    link="/blog/2022/introducing-ambient-mesh/ambient-waypoint.png"
    caption="When additional features are needed, ambient mesh deploys waypoint proxies, which ztunnels connect through for policy enforcement"
    >}}

Ambient mesh uses HTTP CONNECT over mTLS to implement its secure tunnels and insert waypoint proxies in the path, a pattern we call HBONE (HTTP-Based Overlay Network Environment). HBONE provides for a cleaner encapsulation of traffic than TLS on its own while enabling interoperability with common load-balancer infrastructure. FIPS builds are used by default to meet compliance needs. More details on HBONE, its standards-based approach, and plans for UDP and other non-TCP protocols will be provided in a future blog.

Mixing sidecars and ambient in a single mesh does not introduce limitations on the capabilities or security properties of the system. The Istio control plane ensures that policies are properly enforced regardless of the deployment model chosen. Ambient simply introduces an option that has better ergonomics and more flexibility.

## Traffic routing

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, workloads can fall into 3 categories:
1. **Uncaptured:** this is a standard pod without any mesh features enabled.
1. **Captured:** this is a pod that has traffic intercepted by {{< gloss >}}ztunnel{{< /gloss >}}. Pods can be captured by setting the `istio.io/dataplane-mode=ambient` label on a namespace.
1. **Waypoint enabled:** this is a pod that is "Captured" *and* has a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} deployed.
  A waypoint will, by default, apply to all pods in the same namespace.
  It can optionally be set to apply to only a specific service account with the `istio.io/for-service-account` annotation on the `Gateway`.
  If there is both a namespace waypoint and service account waypoint, the service account waypoint takes precedence.

Depending on which category a workload is in, the request path will be different.

### Ztunnel routing

#### Outbound

When a captured pod makes an outbound request, it will be transparently redirected to ztunnel which will determine where and how to forward the request.
In general, the traffic routing behaves just like Kubernetes default traffic routing;
requests to a `Service` will be sent to an endpoint within the `Service` while requests directly to a `Pod` IP will go directly to that IP.

However, depending on the destination's capabilities, different behavior will occur.
If the destination is also captured, or otherwise has Istio proxy capabilities (such as a sidecar), the request will be upgraded to an encrypted {{< gloss "HBONE" >}}HBONE tunnel{{< /gloss >}}.
If the destination has a waypoint proxy, in addition to being upgraded to HBONE, the request will instead be forwarded to that waypoint.

Note that in the case of a request to a `Service`, a specific endpoint will be selected to determine if it has a waypoint.
However, if it *has* a waypoint, the request will be sent with a target destination of the `Service`, not the selected endpoint.
This allows the waypoint to apply service-oriented policies to the traffic.
In the rare case that a `Service` has a mix of waypoint enabled and non-enabled endpoints, some requests would be sent to a waypoint while other requests to the same service would not.

#### Inbound

When a captured pod receives an inbound request, it will be transparently redirected to ztunnel.
When ztunnel receives the request, it will apply Authorization Policies and forward the request only if the request meets the policies.

A pod can receive HBONE traffic or plaintext traffic.
By default, both will be accepted by ztunnel.
Because plaintext requests will have no peer identity when Authorization Policies are evaluated,
a user can set a policy requiring an identity (either *any* identity, or a specific one) to block all plaintext traffic.

When the destination is waypoint enabled, all requests *must* go through the waypoint where policy is enforced.
The ztunnel will make sure this occurs.
However, there is an edge case: a well behaving HBONE client (such as another ztunnel or Istio sidecar) would know to send to the waypoint, but other clients
(such as a workload outside of the mesh) likely would not know anything about waypoint proxies and send requests directly.
When these direct calls are made, the ztunnel will "hairpin" the request to its own waypoint to ensure policies are properly enforced.

### Waypoint routing

A waypoint exclusively receives HBONE requests.
Upon receiving a request, the waypoint will ensure it is targeting either a `Pod` that it manages or a `Service` that contains a `Pod` it manages.

For either type of request, the waypoint will enforce policies (such as `AuthorizationPolicy`, `WasmPlugin`, `Telemetry`, etc) before forwarding.

For direct requests to a `Pod`, the requests are simply forwarded directly after policy is applied.

For requests to a `Service`, the waypoint will also apply routing and load balancing.
By default, a `Service` will simply route to itself, load balancing across its endpoints.
This can be overridden with Routes for that `Service`.

For example, the below policy will ensure that requests to the `echo` service are forwarded to `echo-v1`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: echo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: echo
  rules:
  - backendRefs:
    - name: echo-v1
      port: 80
{{< /text >}}

## Security
