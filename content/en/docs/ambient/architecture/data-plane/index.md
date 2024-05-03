---
title: Ambient data plane
description: Understand how the ambient data plane routes traffic between workloads in an ambient mesh.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, workloads can fall into 3 categories:
1. **Out of Mesh**: a standard pod without any mesh features enabled. Istio and the ambient {{< gloss >}}data plane{{< /gloss >}} are not enabled.
1. **In Mesh**: a pod that is included in the ambient {{< gloss >}}data plane{{< /gloss >}}, and has traffic intercepted at the Layer 4 level by {{< gloss >}}ztunnel{{< /gloss >}}. In this mode, L4 policies can be enforced for pod traffic. This mode can be enabled by setting the `istio.io/dataplane-mode=ambient` label. See [labels](docs/ambient/architecture#ambient-labels) for more details.
1. **In Mesh, Waypoint enabled**: a pod that is _in mesh_ *and* has a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} deployed. In this mode, L7 policies can be enforced for pod traffic. This mode can be enabled by setting the `istio.io/use-waypoint` label. See [labels](docs/ambient/architecture#ambient-labels) for more details.

Depending on which category a workload is in, the traffic path will be different.

## In Mesh Routing

### Outbound

When a pod in an ambient mesh makes an outbound request, it will be transparently redirected to the node-local ztunnel which will determine where and how to forward the request.
In general, the traffic routing behaves just like Kubernetes default traffic routing;
requests to a `Service` will be sent to an endpoint within the `Service` while requests directly to a `Pod` IP will go directly to that IP.

However, depending on the destination's capabilities, different behavior will occur.
If the destination is also added in the mesh, or otherwise has Istio proxy capabilities (such as a sidecar), the request will be upgraded to an encrypted {{< gloss "HBONE" >}}HBONE tunnel{{< /gloss >}}.
If the destination has a waypoint proxy, in addition to being upgraded to HBONE, the request will be forwarded to that waypoint for L7 policy enforcement.

Note that in the case of a request to a `Service`, if the service *has* a waypoint, the request will be sent to its waypoint to apply L7 policies to the traffic.
Similarly, in the case of a request to a `Pod` IP, if the pod *has* a waypoint, the request will be sent to its waypoint to apply L7 policies to the traffic.
Since it is possible to vary the labels associated with pods in a `Deployment` it is technically possible for
some pods to use a waypoint while others do not. Users are generally recommended to avoid this advanced use case.

### Inbound

When a pod in an ambient mesh receives an inbound request, it will be transparently redirected to ztunnel.
When ztunnel receives the request, it will apply Authorization Policies and forward the request only if the request passes these checks.

A pod can receive HBONE traffic or plaintext traffic.
By default, both will be accepted by ztunnel.
Requests from sources out of mesh will have no peer identity when Authorization Policies are evaluated,
a user can set a policy requiring an identity (either *any* identity, or a specific one) to block all plaintext traffic.

When the destination is waypoint enabled, if the source is in ambient mesh, the source's ztunnel ensures the request **will** go through
the waypoint where policy is enforced. However, a workload outside of the mesh doesn't know anything about waypoint proxies therefore it sends
requests directly to the destination without going through any waypoint proxy even if the destination is waypoint enabled.
Currently, traffic from sidecars and gateways won't go through any waypoint proxy either and they will be made aware of waypoint proxies
in a future release.

#### Dataplane details

The L4 ambient dataplane between is depicted in the following figure.

{{< image width="100%"
link="ztunnel-datapath-1.png"
caption="Basic ztunnel L4-only datapath"
>}}

The figure shows several workloads added to the ambient mesh, running on nodes W1 and W2 of a Kubernetes cluster. There is a single instance of the ztunnel proxy on each node. In this scenario, application client pods C1, C2 and C3 need to access a service provided by pod S1. There is no requirement for advanced L7 features such as L7 traffic routing or L7 traffic management, so a L4 data plane is sufficient to obtain {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}} and L4 policy enforcement - no waypoint proxy is required.

The figure shows that pods C1 and C2, running on node W1, connect with pod S1 running on node W2.

The TCP traffic for C1 and C2 is securely tunneled via ztunnel-created {{< gloss >}}HBONE{{< /gloss >}} connections. {{< gloss "mutual tls authentication" >}}Mutual TLS (mTLS){{< /gloss >}} is used for encryption as well as mutual authentication of traffic being tunneled. [SPIFFE](https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE.md) identities are used to identify the workloads on each side of the connection. For more details on the tunneling protocol and traffic redirection mechanism, refer to the guides on [HBONE](/docs/ambient/architecture/hbone) and [ztunnel traffic redirection](/docs/ambient/architecture/traffic-redirection).

{{< tip >}}
Note: Although the figure shows the HBONE tunnels to be between the two ztunnel proxies, the tunnels are in fact between the source and destination pods. Traffic is HBONE encapsulated and encrypted in the network namespace of the source pod itself, and eventually decapsulated and decrypted in the network namespace of the destination pod on the destination worker node. The ztunnel proxy still logically handles both the control plane and data plane needed for HBONE transport; however, it is able to do that from inside the network namespaces of the source and destination pods.
{{< /tip >}}

Note that local traffic - shown in the figure from pod C3 to destination pod S1 on worker node W2 - also traverses the local ztunnel proxy instance, so that L4 traffic management functions such as L4 Authorization and L4 Telemetry will be enforced identically on traffic, whether or not it crosses a node boundary.

## In Mesh routing with Waypoint enabled

Istio waypoints exclusively receive HBONE traffic.
Upon receiving a request, the waypoint will ensure that the traffic is for a `Pod` or `Service` which uses it.

Having accepted the traffic, the waypoint will then enforce L7 policies (such as `AuthorizationPolicy`, `RequestAuthentication`, `WasmPlugin`, `Telemetry`, etc) before forwarding.

For direct requests to a `Pod`, the requests are simply forwarded directly after policy is applied.

For requests to a `Service`, the waypoint will also apply routing and load balancing.
By default, a `Service` will simply route to itself, performing L7 load balancing across its endpoints.
This can be overridden with Routes for that `Service`.

For example, the below policy will ensure that requests to the `echo` service are forwarded to `echo-v1`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
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

The following figure shows the datapath between ztunnel and a waypoint, if one is configured for L7 policy enforcement. Here ztunnel uses HBONE tunneling to send traffic to a waypoint proxy for L7 processing. After processing, the waypoint sends traffic via a second HBONE tunnel to the ztunnel on the node hosting the selected service destination pod. In general the waypoint proxy may or may not be located on the same nodes as the source or destination pod.

{{< image width="100%"
link="ztunnel-waypoint-datapath.png"
caption="Ztunnel datapath via an interim waypoint"
>}}
