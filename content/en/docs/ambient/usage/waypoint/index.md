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
you can configure the waypoint to process traffic for different resource types such as `service`, `workload`, or `all`.

## Do you need a waypoint proxy?

This layered approach of ambient allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure overlay, to full L7 processing. If your applications require any of the following L7 mesh functions, you will need to use waypoint proxy for your applications:

{{< image width="100%"
link="L7-processing-layer.png"
caption="L7 processing layer"
>}}

## Deploy a waypoint proxy

Waypoint proxies can process traffic for `service`, `workload`, or `all`. You can also configure your waypoint proxy to
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
value to the desired value (`workload`, `all`, or `none`). For example, the command below deploys a waypoint proxy for the
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

## Use a waypoint proxy {#useawaypoint}

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
$ istioctl x waypoint apply -n default --name reviews-v2-pod-waypoint --for workload
waypoint default/reviews-v2-pod-waypoint applied
{{< /text >}}

Label the `reviews-v2` pod to use the `reviews-v2-pod-waypoint` waypoint:

{{< text bash >}}
$ kubectl label pod -l version=v2,app=reviews istio.io/use-waypoint=reviews-v2-pod-waypoint
pod/reviews-v2-5b667bcbf8-spnnh labeled
{{< /text >}}

For any requests from any pods in ambient to the `reviews-v2` pod IP, the requests must go through the `reviews-v2-pod-waypoint`
for L7 processing and policy enforcement.

## Attach L7 policies to waypoint proxies {#attachl7policies}

The following L7 policies are supported for waypoint proxy:

|  Name  | Feature Status | Policy Attachment |
| --- | --- | --- |
| `HTTPRoute` | Beta | `parentRefs` |
| `TCPRoute` | Beta | `parentRefs` |
| `TLSRoute` | Beta | `parentRefs` |
| `AuthorizationPolicy` | Beta | `targetRefs` |
| `RequestAuthentication` | Beta | `targetRefs` |
| `Telemetry` | Alpha | `targetRefs` |
| `WasmPlugin` | Alpha | `targetRefs` |
| `EnvoyFilter` | Alpha | `targetRefs` |

### Attach a L7 policy to the entire waypoint proxy

To attach a L7 policy to the entire waypoint, set `Gateway` as the `parentRefs` or `targetRefs` value, depending on your policy type.
The example below shows how to apply a `AuthorizationPolicy` policy to the waypoint named `waypoint` for the `default` namespace:

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

## Debug your waypoint proxies

The debugging guide below assume you have follow the ambient get started [guide](/docs/ambient/getting-started/) to install Istio with
the ambient profile and the sample application, added your application to the ambient mesh and followed all the commands in the [use a waypoint](#useawaypoint) and [attach L7 policies to waypoint proxies](#attachl7policies) sections earlier.

1. If your L7 policy isn't enforced, run `istioctl analyzer` first to check if your policy has any validation issue.

{{< text bash >}}
$ istioctl analyze
✔ No validation issues found when analyzing namespace: default.
{{< /text >}}

1. Determine which waypoint is enforcing the L7 policy for your service or pod.

If your source calls for the destination as its service's hostname or IP, use the `istioctl x ztunnel-config service` command to confirm your waypoint is used by the destination service. Following the example earlier, the `reviews` service should use the `reviews-svc-waypoint` while all other services in the `default` namespace should use the namespace `waypoint`.

{{< text bash >}}
$ istioctl x ztunnel-config service
NAMESPACE    SERVICE NAME            SERVICE VIP   WAYPOINT
default      bookinfo-gateway-istio  10.43.164.194 waypoint
default      bookinfo-gateway-istio  10.43.164.194 waypoint
default      bookinfo-gateway-istio  10.43.164.194 waypoint
default      bookinfo-gateway-istio  10.43.164.194 waypoint
default      details                 10.43.160.119 waypoint
default      kubernetes              10.43.0.1     waypoint
default      notsleep                10.43.156.147 waypoint
default      productpage             10.43.172.254 waypoint
default      ratings                 10.43.71.236  waypoint
default      reviews                 10.43.162.105 reviews-svc-waypoint
...
{{< /text >}}

If your source calls for the destination using pod IP , use the `istioctl x ztunnel-config workload` command to confirm your waypoint is used by the destination pod. Following the example earlier, the `reviews` `v2` pod should use the `reviews-v2-pod-waypoint` while all other pods in the `default` namespace should not have any waypoints as by default only services use the namespace `waypoint`.

{{< text bash >}}
$ istioctl x ztunnel-config workload
NAMESPACE    POD NAME                                    IP         NODE                     WAYPOINT                PROTOCOL
default      bookinfo-gateway-istio-7c57fc4647-wjqvm     10.42.2.8  k3d-k3s-default-server-0 None                    TCP
default      details-v1-698d88b-wwsnv                    10.42.2.4  k3d-k3s-default-server-0 None                    HBONE
default      notsleep-685df55c6c-nwhs6                   10.42.0.9  k3d-k3s-default-agent-0  None                    HBONE
default      productpage-v1-675fc69cf-fp65z              10.42.2.6  k3d-k3s-default-server-0 None                    HBONE
default      ratings-v1-6484c4d9bb-crjtt                 10.42.0.4  k3d-k3s-default-agent-0  None                    HBONE
default      reviews-svc-waypoint-c49f9f569-b492t        10.42.2.10 k3d-k3s-default-server-0 None                    TCP
default      reviews-v1-5b5d6494f4-nrvfx                 10.42.2.5  k3d-k3s-default-server-0 None                    HBONE
default      reviews-v2-5b667bcbf8-gj7nz                 10.42.0.5  k3d-k3s-default-agent-0  reviews-v2-pod-waypoint HBONE
...
{{< /text >}}

If the value for the pod's waypoint column isn't correct, verify your pod labeled with `istio.io/use-waypoint` is using a waypoint that can process
the traffic for your resource.  For example, if your `reviews` `v2` pod uses a waypoint that can only process service traffic, you will not see any waypoint used by that pod.

1. Check the waypoint's proxy status via the `istioctl proxy-status` command.

{{< text bash >}}
$ istioctl proxy-status
NAME                                                CLUSTER        CDS         LDS         EDS          RDS          ECDS         ISTIOD                      VERSION
bookinfo-gateway-istio-7c57fc4647-wjqvm.default     Kubernetes     SYNCED      SYNCED      SYNCED       SYNCED       NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
reviews-svc-waypoint-c49f9f569-b492t.default        Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
reviews-v2-pod-waypoint-7f5dbd597-7zzw7.default     Kubernetes     SYNCED      SYNCED      NOT SENT     NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
waypoint-6f7b665c89-6hppr.default                   Kubernetes     SYNCED      SYNCED      SYNCED       NOT SENT     NOT SENT     istiod-795d55fc6d-vqtjx     1.23-alpha.75c6eafc5bc8d160b5643c3ea18acb9785855564
...
{{< /text >}}

1. Enable Envoy's [access log](/docs/tasks/observability/logs/access-log/) and check the logs of the waypoint proxy after sending some requests:

{{< text bash >}}
$ kubectl logs deploy/waypoint
{{< /text >}}

If there is not enough information, you can enable the debug logs for the waypoint proxy:

{{< text bash >}}
$ istioctl pc log deploy/waypoint --level debug
{{< /text >}}

1. Check the envoy configuration for the waypoint via the `istioctl proxy-config` command, which shows all the information related to the waypoint such as clusters, endpoints, listeners, routes and secrets:

{{< text bash >}}
$ istioctl proxy-config all deploy/waypoint
{{< /text >}}

Refer to the [deep dive into Envoy configuration](/docs/ops/diagnostic-tools/proxy-cmd/#deep-dive-into-envoy-configuration) section for more
information regarding how to debug Envoy since waypoint proxies are based on Envoy.
