---
title: Layer 7 with Waypoint Proxies
description: Gain the full set of Istio feature with optional waypoint proxies.
weight: 2
aliases:
  - /docs/ops/ambient/usage/waypoint
  - /latest/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: no
---

Ambient splits Istio’s functionality into two distinct layers, a secure overlay layer and a Layer 7 processing layer.
The waypoint proxy is an optional component that is Envoy-based and handles L7 processing for different resources.
What is unique about the waypoint proxy is that it runs outside of the application pod. A waypoint proxy can install,
upgrade, and scale independently from the application, as well as reduce operational costs. When deploying a waypoint,
you can configure the waypoint to process traffic for different resource types such as `service` or `workload` or `all`.

## Do you need a waypoint proxy?

This layered approach of ambient allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure overlay, to full L7 processing. If your applications require any of the following L7 mesh functions, you will need to use waypoint proxy for your applications:

{{< image width="100%"
link="L7-processing-layer.png"
caption="L7 processing layer"
>}}

## Deploy a waypoint proxy

Waypoint proxies can process traffic for `service`, `workload` or `all`. You can also configure your waypoint proxy to
process `none` of the traffic, which is primarily used for testing purpose as you incrementally add a waypoint proxy to
your application.

Before you deploy a waypoint proxy for a specific namespace, confirm the namespace is labeled with `istio.io/dataplane-mode: ambient`:

{{< text bash >}}
$ kubectl get ns -L istio.io/dataplane-mode
NAME              STATUS   AGE   DATAPLANE-MODE
istio-system      Active   24h
default           Active   24h   ambient
{{< /text >}}

Waypoint proxies are deployed declaratively using Kubernetes Gateway resources or the helpful istioctl command. You can
preview the generated Kubernetes Gateway resource, for example, the command below generates a waypoint proxy named `waypoint` for the
`default` namespace that can process traffic for services in the namespace:

{{< text bash >}}
$ istioctl x waypoint generate -n default
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
$ istioctl x waypoint apply -n default
waypoint default/namespace applied
{{< /text >}}

Or, you can deploy the generated Gateway resource from the `istioctl x waypoint generate` command to your Kubernetes cluster:

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
value to the desired value (`workload` or `all` or `none`). For example, the command below deploys a waypoint proxy for the
`default` namespace that can process `all` traffic in the namespace declaratively using the Kubernetes Gateway resource:

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

Or use the `istioctl x waypoint apply` command with the `--for` parameter such as `istioctl x waypoint apply -n default --for all`.

After the Gateway resource is applied, Istiod will monitor the resource, deploy and manage the corresponding waypoint deployment and service for users automatically.

## Use a waypoint proxy

When a waypoint proxy is deployed, it is not used by any resource until you explicitly configure your resource to use it. You can label your resource such as namespace, service or pods with the `istio.io/use-waypoint` label to use a waypoint. We recommend
to start with namespace waypoint proxy first. To enable a specific namespace such as the `default` namespace for a waypoint proxy,
simply add the `--enroll-namespace` parameter to your `istioctl x waypoint apply` command, which labels the namespace with `istio.io/use-waypoint: waypoint` for you automatically:

{{< text bash >}}
$ istioctl x waypoint apply -n default --enroll-namespace
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Or you can add the `istio.io/use-waypoint: waypoint` label to the `default` namespace using `kubectl`:

{{< text bash >}}
$ kubectl label ns default istio.io/use-waypoint=waypoint
namespace/default labeled
{{< /text >}}

After the namespace is enabled for waypoint, the waypoint proxy can be used for L7 processing for any services running in the namespace. For any requests from any pods in ambient to any service in the `default` namespace, the requests must go through the `waypoint` for L7 processing and policy enforcement.

If you prefer more granularity than namespace waypoint, you can label your specific service or pod in the namespace to use a different waypoint. For example, you may want your `WasmPlugin` resource to apply only on a specific service or you are calling a Kubernetes
[headless service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) by its Pod IP address.

### Configure a specific service with its own waypoint

Deploy a waypoint called `reviews-svc-waypoint` for the `reviews` service:

{{< text bash >}}
$ istioctl x waypoint apply -n default --name reviews-svc-waypoint
waypoint default/reviews-svc-waypoint applied
{{< /text >}}

Label the `reviews` service to use the `reviews-svc-waypoint` waypoint:

{{< text bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint
service/reviews labeled
{{< /text >}}

For any requests from any pods in ambient to the `reviews` service, the requests must go through the `reviews-svc-waypoint` for L7 processing and policy enforcement.

### Configure a specific pod with its own waypoint

Deploy a waypoint called `reviews-v2-pod-waypoint` for the `reviews-v2` pod:

{{< text bash >}}
$ istioctl x waypoint apply -n default --name reviews-v2-pod-waypoint
waypoint default/reviews-v2-pod-waypoint applied
{{< /text >}}

Label the `reviews-v2` pod to use the `reviews-v2-pod-waypoint` waypoint:

{{< text bash >}}
$ kubectl label pod -l version=v2,app=reviews istio.io/use-waypoint=reviews-v2-pod-waypoint
pod/reviews-v2-5b667bcbf8-spnnh labeled
{{< /text >}}

For any requests from any pods in ambient to the `reviews-v2` pod IP, the requests must go through the `reviews-v2-pod-waypoint`
for L7 processing and policy enforcement.

## Attach L7 policies to the waypoint proxy

The following L7 policies are supported for waypoint proxy:

|  Name  | Feature Status | Policy Attachment |
| --- | --- | --- |
| HTTPRoute | Beta | `parentRefs` |
| TCPRoute | Beta | `parentRefs` |
| AuthorizationPolicy | Beta | `targetRefs` |
| RequestAuthentication | Beta | `targetRefs` |
| Telemetry | Alpha | `targetRefs` |
| WasmPlugin | Alpha | `targetRefs` |
| EnvoyFilter | Alpha | `targetRefs` |

## Attach a L7 policy to the entire waypoint proxy

To attach a L7 policy to the entire waypoint, set `Gateway` as the `parentRefs` or `targetRefs` value, depending on your policy type.
The example below shows how to apply a `AuthorizationPolicy` policy to the waypoint named `waypoint` for the `default` namespace:

    {{< text yaml >}}
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
            namespaces: ["default"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

## Attach a L7 policy to a specific service

To attach a L7 policy to a specific service within the waypoint, set `Service` as the `parentRefs` or `targetRefs` value. The example below shows how to apply
the `reviews` HTTPRoute to the `reviews` service in the `default` namespace:

    {{< text yaml >}}
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
## Debug your waypoint proxy

1. If your L7 policy isn't enforced, run `istioctl analyzer` to check if your policy has any validation issue.

{{< text yaml >}}
$ istioctl analyze
✔ No validation issues found when analyzing namespace: default.
{{< /text >}}

1. Check which waypoint is enforcing the L7 policy via the `istioctl x ztunnel-config all` command.

{{< text yaml >}}
$ istioctl x ztunnel-config all
{{< /text >}}

1. Check the logs of the waypoint proxy.

1. Check the waypoint's proxy status via the `istioctl proxy-status` command.

1. Check the envoy configuration for the waypoint via the `istioctl proxy-config` command.
