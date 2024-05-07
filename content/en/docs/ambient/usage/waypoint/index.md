---
title: Configure waypoint proxies
description: Gain the full set of Istio features with optional Layer 7 proxies.
weight: 20
aliases:
  - /docs/ops/ambient/usage/waypoint
  - /latest/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: no
---

A **waypoint proxy** is an optional deployment of the Envoy-based proxy to add Layer 7 (L7) processing to a defined set of workloads.

Waypoint proxies are installed, upgraded and scaled independently from applications; an application owner should be unaware of their existence. Compared to the sidecar {{< gloss >}}data plane{{< /gloss >}} mode, which runs an instance of the Envoy proxy alongside each workload, the number of proxies required can be substantially reduced.

A waypoint, or set of waypoints, can be shared between applications with a similar security boundary. This might be all the instances of a particular workload, or all the workloads in a namespace.

## Do you need a waypoint proxy?

The layered approach of ambient allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure L4 overlay, to full L7 processing. 

Most of the features of ambient mode are provided by the ztunnel node agent. Ztunnel is scoped to only process traffic at Layer 4 (L4), so that it can safely operate as a shared component.

When you add a waypoint proxy for a workload, traffic will be forwarded from the ztunnel to that waypoint. If your applications require any of the following L7 mesh functions, you will need to use a waypoint proxy:

* **Traffic management**: HTTP routing & load balancing, circuit breaking, rate limiting, fault injection, retries, timeouts
* **Security**: Rich authorization policies based on L7 primitives such as request type or HTTP header
* **Observability**: HTTP metrics, access logging, tracing

## Deploy a waypoint proxy

Waypoint proxies are deployed declaratively using Kubernetes Gateway resources or the helpful istioctl command. By default, a waypoint will only handle `service` traffic. It is possible for the bundled Istio waypoint class to handle `workload` traffic. Istio also recognizes a convenient `all` value which includes both previously mentioned traffic types. Finally, a waypoint may be configured for testing to handle no traffic at all by using the `none` value.

Before you deploy a waypoint proxy for a specific namespace, confirm the namespace is labeled with `istio.io/dataplane-mode: ambient`:

{{< text bash >}}
$ kubectl get ns -L istio.io/dataplane-mode
NAME              STATUS   AGE   DATAPLANE-MODE
istio-system      Active   24h
default           Active   24h   ambient
{{< /text >}}

Before you deploy a waypoint proxy, you can preview the generated Kubernetes Gateway
resource, for example, the command below generates a waypoint proxy named `waypoint` for the
`default` namespace that can process traffic for services in the namespace:

{{< text bash >}}
$ istioctl experimental waypoint generate --for service -n default
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

Note the Gateway resource has `istio-waypoint` as `gatewayClassName` which indicates it is a waypoint provided by Istio. The
Gateway resource is labeled with `istio.io/waypoint-for: service`, indicating the waypoint can process traffic for services,
which is the default.

To deploy a waypoint proxy for the `default` namespace, use the command below:

{{< text bash >}}
$ istioctl experimental waypoint apply -n default
waypoint default/namespace applied
{{< /text >}}

Or, you can deploy the generated Gateway resource from the `istioctl experimental waypoint generate` command to your Kubernetes cluster:

{{< text bash >}}
$ kubectl apply -f - <<EOF
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

To config your waypoint to process traffic differently than the default `service`, you can modify the `istio.io/waypoint-for` label
value to the desired value (`workload`, `all`, or `none`). For example, the command below deploys a waypoint proxy for the
`default` namespace that can process `all` traffic in the namespace:

{{< text bash >}}
$ kubectl apply -f - <<EOF
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: all
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

You can also use the `--for` parameter to `istioctl experimental waypoint apply`:

{{< text bash>}}
$ istioctl experimental waypoint apply -n default --for all
{{< /text >}}

After the Gateway resource is applied, Istiod will monitor the resource, deploy and manage the corresponding waypoint deployment and service for users automatically.

## Use a waypoint proxy {#useawaypoint}

When a waypoint proxy is deployed, it is not used by any resources until you they are explicitly configured to use it.

To enable a namespace, service or Pod to use a waypoint, add the `istio.io/use-waypoint` label with a value of the waypoint name.
We recommend to start with namespace waypoint proxy first as it can be used by any resources in the namespace.

If you use `istioctl` to deploy your namespace waypoint, you can use the `--enroll-namespace` parameter to automatically label a namespace for you.

{{< text bash >}}
$ istioctl experimental waypoint apply -n default --enroll-namespace
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Alternatively, you may add the `istio.io/use-waypoint: waypoint` label to the `default` namespace using `kubectl`:

{{< text bash >}}
$ kubectl label ns default istio.io/use-waypoint=waypoint
namespace/default labeled
{{< /text >}}

After a namespace is enrolled to use a waypoint, any requests from any pods in ambient to any service running in that namespace will be routed through the waypoint for L7 processing and policy enforcement.

If you prefer more granularity than running a waypoint for an entire namespace, you can label a specific service or pod to use a waypoint. This may be useful if you want a `WasmPlugin` resource to apply only on a specific service, or if you are calling a Kubernetes
[headless service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) by its pod IP address.

### Configure a service to use a specific waypoint

Deploy a waypoint called `reviews-svc-waypoint` for the `reviews` service:

{{< text bash >}}
$ istioctl experimental waypoint apply -n default --name reviews-svc-waypoint
waypoint default/reviews-svc-waypoint applied
{{< /text >}}

Label the `reviews` service to use the `reviews-svc-waypoint` waypoint:

{{< text bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint
service/reviews labeled
{{< /text >}}

Any requests from pods in the ambient mesh to the `reviews` service will now be routed through the `reviews-svc-waypoint` waypoint.

### Configure a pod to use a specific waypoint

Deploy a waypoint called `reviews-v2-pod-waypoint` for the `reviews-v2` pod:

{{< text bash >}}
$ istioctl experimental waypoint apply -n default --name reviews-v2-pod-waypoint --for workload
waypoint default/reviews-v2-pod-waypoint applied
{{< /text >}}

Label the `reviews-v2` pod to use the `reviews-v2-pod-waypoint` waypoint:

{{< text bash >}}
$ kubectl label pod -l version=v2,app=reviews istio.io/use-waypoint=reviews-v2-pod-waypoint
pod/reviews-v2-5b667bcbf8-spnnh labeled
{{< /text >}}

Any requests from pods in the ambient mesh to the `reviews-v2` pod IP will now be routed through the `reviews-v2-pod-waypoint` waypoint.
for L7 processing and policy enforcement.

## Attach L7 policies to waypoint proxies {#attachl7policies}

The following L7 policies are supported for waypoint proxy:

|  Name  | Feature Status | Policy Attachment |
| --- | --- | --- |
| `HTTPRoute` | Beta | `parentRefs` |
| `TCPRoute` | Alpha | `parentRefs` |
| `TLSRoute` | Alpha | `parentRefs` |
| `AuthorizationPolicy` | Beta | `targetRefs` |
| `RequestAuthentication` | Beta | `targetRefs` |
| `Telemetry` | Alpha | `targetRefs` |
| `WasmPlugin` | Alpha | `targetRefs` |
| `EnvoyFilter` | Alpha | `targetRefs` |

### Attach a L7 policy to the entire waypoint proxy

To attach a L7 policy to the entire waypoint, set `Gateway` as the `parentRefs` or `targetRefs` value, depending on your policy type.
The example below shows how to apply an `AuthorizationPolicy` policy to the waypoint named `waypoint` for the `default` namespace:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: viewer
  namespace: default
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: waypoint
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["default", "istio-system"]
    to:
    - operation:
        methods: ["GET"]
EOF
{{< /text >}}

### Attach a L7 policy to a specific service

To attach a L7 policy to a specific service within the waypoint, set `Service` as the `parentRefs` or `targetRefs` value. The example below shows how to apply
the `reviews` HTTPRoute to the `reviews` service in the `default` namespace:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
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
EOF
{{< /text >}}
