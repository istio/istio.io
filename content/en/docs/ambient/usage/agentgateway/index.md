---
title: Use agentgateway
description: Configure agentgateway as an ingress gateway and as a waypoint in ambient mode.
weight: 40
owner: istio/wg-networking-maintainers
test: yes
---

{{< boilerplate experimental-feature-warning >}}

[agentgateway](https://agentgateway.dev) is a data plane proxy that can be used as an
alternative to Envoy. It is purpose-built for AI agent and
[Model Context Protocol (MCP)](https://modelcontextprotocol.io) traffic, while also supporting
general-purpose Layer 7 routing. When agentgateway is enabled, Istio can program it in place of
Envoy for two roles in an {{< gloss "ambient" >}}ambient mesh{{< /gloss >}}:

* as an **ingress gateway**, handling north-south traffic entering the mesh, and
* as a {{< gloss >}}waypoint{{< /gloss >}} proxy, handling east-west Layer 7 processing for a set of workloads.

This guide explains how the integration works, which APIs are supported, and how to install Istio
and configure agentgateway for each role.

## How the integration works

Istiod configures agentgateway **exclusively through Kubernetes Gateway API resources**, which it
delivers to the proxy over xDS. The proxy is a distinct {{< gloss >}}data plane{{< /gloss >}}
implementation from Envoy: when a `Gateway` selects an agentgateway
[`GatewayClass`](https://gateway-api.sigs.k8s.io/api-types/gatewayclass/), Istiod provisions and
manages an agentgateway `Deployment` and `Service` for it, in the same way it manages Istio's
Envoy-based gateways.

Enabling agentgateway registers two `GatewayClass` resources:

| `GatewayClass` | Controller | Role |
| -------------- | ---------- | ---- |
| `istio-agentgateway` | `istio.io/agentgateway-controller` | Ingress gateway |
| `istio-agentgateway-waypoint` | `istio.io/agentgateway-waypoint-controller` | Waypoint proxy |

Because the data plane is selected per-`Gateway` through the `gatewayClassName` field, agentgateway
and Istio's default Envoy-based gateways and waypoints can coexist in the same cluster. You choose
agentgateway for a specific gateway or waypoint simply by referencing one of the classes above.

## Supported and unsupported configuration

Istio supports the following [Gateway API](https://gateway-api.sigs.k8s.io/) resources for
agentgateway:

* `Gateway` (using the `istio-agentgateway` or `istio-agentgateway-waypoint` class)
* `HTTPRoute`, `GRPCRoute`, `TCPRoute`, and `TLSRoute`
* `InferencePool`, from the [Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/), for routing to AI inference workloads

{{< warning >}}
Istio configures agentgateway **only** through the Gateway API resources listed above. Istio's own
configuration APIs — such as `VirtualService`, `DestinationRule`, `Sidecar`, `AuthorizationPolicy`,
`PeerAuthentication`, `RequestAuthentication`, `Telemetry`, `WasmPlugin`, and `EnvoyFilter` — are
**not** applied to agentgateway proxies. Use the Gateway API to express routing and policy instead.

agentgateway's own native configuration format and custom resources are likewise not managed by
Istio; Istio programs the proxy solely through the Gateway API resources described in this guide.
{{< /warning >}}

## Before you begin

{{< boilerplate gateway-api-install-crds >}}

### Install Istio with agentgateway enabled

agentgateway support is gated behind the `PILOT_ENABLE_AGENTGATEWAY` feature flag on istiod, and is
disabled by default. Install Istio using the `ambient` profile with the flag enabled. The `ambient`
profile is required so that the waypoint `GatewayClass` is also registered:

{{< text syntax=bash snip_id=install_istio >}}
$ istioctl install --set profile=ambient --set values.pilot.env.PILOT_ENABLE_AGENTGATEWAY=true -y
{{< /text >}}

{{< tip >}}
When installing with Helm, set the same flag on the `istiod` chart with
`--set pilot.env.PILOT_ENABLE_AGENTGATEWAY=true`.
{{< /tip >}}

Confirm that both agentgateway `GatewayClass` resources are registered:

{{< text syntax=bash snip_id=verify_gateway_classes >}}
$ kubectl get gatewayclass istio-agentgateway istio-agentgateway-waypoint
NAME                          CONTROLLER                                  ACCEPTED   AGE
istio-agentgateway            istio.io/agentgateway-controller            True       30s
istio-agentgateway-waypoint   istio.io/agentgateway-waypoint-controller   True       30s
{{< /text >}}

### Deploy a sample application

Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application, which is used by the examples in
this guide:

{{< text syntax=bash snip_id=deploy_bookinfo >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
{{< /text >}}

## Configure agentgateway as an ingress gateway

To use agentgateway as an ingress gateway, create a `Gateway` that references the
`istio-agentgateway` class. Istiod provisions and manages the corresponding agentgateway deployment
automatically.

{{< text syntax=bash snip_id=deploy_ingress_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bookinfo-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio-agentgateway
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

The `gatewayClassName: istio-agentgateway` field is what selects the agentgateway data plane instead
of Envoy. By default, Istio creates a `LoadBalancer` service for a gateway; the
`networking.istio.io/service-type: ClusterIP` annotation requests a `ClusterIP` service instead so
that the gateway can be reached with `kubectl port-forward` in this guide.

Attach an `HTTPRoute` to expose the `productpage` service through the gateway:

{{< text syntax=bash snip_id=deploy_ingress_route >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookinfo
spec:
  parentRefs:
  - name: bookinfo-gateway
  rules:
  - matches:
    - path:
        type: Exact
        value: /productpage
    - path:
        type: PathPrefix
        value: /static
    - path:
        type: Exact
        value: /login
    - path:
        type: PathPrefix
        value: /api/v1/products
    backendRefs:
    - name: productpage
      port: 9080
EOF
{{< /text >}}

Confirm that the gateway has been provisioned and is programmed. The `CLASS` column shows the
agentgateway class:

{{< text syntax=bash snip_id=verify_ingress_gateway >}}
$ kubectl get gateway bookinfo-gateway
NAME               CLASS                ADDRESS                                      PROGRAMMED   AGE
bookinfo-gateway   istio-agentgateway   bookinfo-gateway.default.svc.cluster.local   True         30s
{{< /text >}}

You can now access the application through the agentgateway ingress gateway. Forward a local port to
the gateway service and open `http://localhost:8080/productpage` in your browser:

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway 8080:80
{{< /text >}}

## Configure agentgateway as a waypoint

A waypoint proxy adds Layer 7 processing to a set of workloads in an ambient mesh. To use
agentgateway for this role, deploy a `Gateway` that references the `istio-agentgateway-waypoint`
class.

First, confirm the namespace is enrolled in the ambient data plane:

{{< text syntax=bash snip_id=label_ambient >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
namespace/default labeled
{{< /text >}}

{{< warning >}}
The `istioctl waypoint` subcommands (`apply`, `generate`, `list`, and `status`) currently only
support the default Envoy-based `istio-waypoint` class. To deploy an agentgateway waypoint, apply a
`Gateway` resource directly, as shown below.
{{< /warning >}}

Deploy the waypoint. Like all waypoints, it must define a single listener named `mesh` on port
`15008` using the `HBONE` protocol; the only difference from an Envoy waypoint is the
`gatewayClassName`:

{{< text syntax=bash snip_id=deploy_waypoint >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: agentgateway-waypoint
  labels:
    istio.io/waypoint-for: service
spec:
  gatewayClassName: istio-agentgateway-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

Confirm the waypoint is programmed:

{{< text syntax=bash snip_id=verify_waypoint >}}
$ kubectl get gateway agentgateway-waypoint
NAME                    CLASS                         ADDRESS        PROGRAMMED   AGE
agentgateway-waypoint   istio-agentgateway-waypoint   10.96.15.112   True         30s
{{< /text >}}

Enroll a service to use the waypoint by adding the `istio.io/use-waypoint` label with the name of
the waypoint. For example, to send traffic destined for the `reviews` service through the
agentgateway waypoint:

{{< text syntax=bash snip_id=enroll_waypoint >}}
$ kubectl label service reviews istio.io/use-waypoint=agentgateway-waypoint
service/reviews labeled
{{< /text >}}

Requests from workloads in the ambient mesh to the `reviews` service are now routed through the
agentgateway waypoint for Layer 7 processing. To learn more about enrolling namespaces, services, and
pods, and about how waypoints handle different traffic types, see
[Configure waypoint proxies](/docs/ambient/usage/waypoint/).

To apply Layer 7 routing policy at the waypoint, attach a Gateway API route to the `Service` using a
`parentRef` whose `kind` is `Service`. For example, the following `HTTPRoute` sends 90% of traffic
for the `reviews` service to `reviews-v1` and 10% to `reviews-v2`:

{{< text syntax=yaml >}}
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
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
{{< /text >}}

## Cleanup

Remove the ingress gateway and its route:

{{< text syntax=bash snip_id=cleanup_ingress >}}
$ kubectl delete httproute bookinfo
$ kubectl delete gateway bookinfo-gateway
{{< /text >}}

Remove the waypoint and unenroll the `reviews` service:

{{< text syntax=bash snip_id=cleanup_waypoint >}}
$ kubectl label service reviews istio.io/use-waypoint-
$ kubectl delete gateway agentgateway-waypoint
{{< /text >}}

Remove the sample application and the ambient label:

{{< text syntax=bash snip_id=cleanup_bookinfo >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

Uninstall Istio:

{{< text syntax=bash snip_id=uninstall_istio >}}
$ istioctl uninstall --purge -y
$ kubectl delete namespace istio-system
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
