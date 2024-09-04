---
title: Configure waypoint proxies
description: Gain the full set of Istio features with optional Layer 7 proxies.
weight: 30
aliases:
  - /docs/ops/ambient/usage/waypoint
  - /latest/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: yes
---

A **waypoint proxy** is an optional deployment of the Envoy-based proxy to add Layer 7 (L7) processing to a defined set of workloads.

Waypoint proxies are installed, upgraded and scaled independently from applications; an application owner should be unaware of their existence. Compared to the sidecar {{< gloss >}}data plane{{< /gloss >}} mode, which runs an instance of the Envoy proxy alongside each workload, the number of proxies required can be substantially reduced.

A waypoint, or set of waypoints, can be shared between applications with a similar security boundary. This might be all the instances of a particular workload, or all the workloads in a namespace.

As opposed to {{< gloss >}}sidecar{{< /gloss >}} mode, in ambient mode policies are enforced by the **destination** waypoint. In many ways, the waypoint acts as a gateway to a resource (a namespace, service or pod). Istio enforces that all traffic coming into the resource goes through the waypoint, which then enforces all policies for that resource.

## Do you need a waypoint proxy?

The layered approach of ambient allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure L4 overlay, to full L7 processing.

Most of the features of ambient mode are provided by the ztunnel node proxy. Ztunnel is scoped to only process traffic at Layer 4 (L4), so that it can safely operate as a shared component.

When you configure redirection to a waypoint, traffic will be forwarded by ztunnel to that waypoint. If your applications require any of the following L7 mesh functions, you will need to use a waypoint proxy:

* **Traffic management**: HTTP routing & load balancing, circuit breaking, rate limiting, fault injection, retries, timeouts
* **Security**: Rich authorization policies based on L7 primitives such as request type or HTTP header
* **Observability**: HTTP metrics, access logging, tracing

## Deploy a waypoint proxy

Waypoint proxies are deployed using Kubernetes Gateway resources.

{{< boilerplate gateway-api-install-crds >}}

You can use istioctl waypoint subcommands to generate, apply or list these resources.

After the waypoint is deployed, the entire namespace (or whichever services or pods you choose) must be [enrolled](#useawaypoint) to use it.

Before you deploy a waypoint proxy for a specific namespace, confirm the namespace is labeled with `istio.io/dataplane-mode: ambient`:

{{< text syntax=bash snip_id=check_ns_label >}}
$ kubectl get ns -L istio.io/dataplane-mode
NAME              STATUS   AGE   DATAPLANE-MODE
istio-system      Active   24h
default           Active   24h   ambient
{{< /text >}}

`istioctl` can generate a Kubernetes Gateway resource for a waypoint proxy. For example, to generate a waypoint proxy named `waypoint` for the `default` namespace that can process traffic for services in the namespace:

{{< text syntax=bash snip_id=gen_waypoint_resource >}}
$ istioctl waypoint generate --for service -n default
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

Note the Gateway resource has the `istio-waypoint` label set to `gatewayClassName` which indicates it is a waypoint provided by Istio. The Gateway resource is labeled with `istio.io/waypoint-for: service`, indicating the waypoint can process traffic for services, which is the default.

To deploy a waypoint proxy directly, use `apply` instead of `generate`:

{{< text syntax=bash snip_id=apply_waypoint >}}
$ istioctl waypoint apply -n default
waypoint default/waypoint applied
{{< /text >}}

Or, you can deploy the generated Gateway resource:

{{< text syntax=bash >}}
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

After the Gateway resource is applied, Istiod will monitor the resource, deploy and manage the corresponding waypoint deployment and service for users automatically.

### Waypoint traffic types

By default, a waypoint will only handle traffic destined for **services** in its namespaces. This choice was made because traffic directed at a pod alone is rare, and often used for internal purposes such as Prometheus scraping, and the extra overhead of L7 processing may not be desired.

It is also possible for the waypoint to handle all traffic, only handle traffic sent directly to **workloads** (pods or VMs) in the cluster, or no traffic at all. The types of traffic that will be redirected to the waypoint are determined by the `istio.io/waypoint-for` label on the `Gateway` object.

Use the `--for` argument to `istioctl waypoint apply` to change the types of traffic that can be redirected to the waypoint:

| `waypoint-for` value | Original destination type |
| -------------------- | ------------ |
| `service`            | Kubernetes services |
| `workload`           | Pod IPs or VM IPs |
| `all`                | Both service and workload traffic |
| `none`               | No traffic (useful for testing) |

Waypoint selection occurs based on the destination type, `service` or `workload`, to which traffic was _originally addressed_. If traffic is addressed to a service which does not have a waypoint, a waypoint will not be transited: even if the eventual workload it reaches _does_ have an attached waypoint.

## Use a waypoint proxy {#useawaypoint}

When a waypoint proxy is deployed, it is not used by any resources until you explicitly configure those resources to use it.

To enable a namespace, service or Pod to use a waypoint, add the `istio.io/use-waypoint` label with a value of the waypoint name.

{{< tip >}}
Most users will want to apply a waypoint to an entire namespace, and we recommend you start with this approach.
{{< /tip >}}

If you use `istioctl` to deploy your namespace waypoint, you can use the `--enroll-namespace` parameter to automatically label a namespace:

{{< text syntax=bash snip_id=enroll_ns_waypoint >}}
$ istioctl waypoint apply -n default --enroll-namespace
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Alternatively, you may add the `istio.io/use-waypoint: waypoint` label to the `default` namespace using `kubectl`:

{{< text syntax=bash >}}
$ kubectl label ns default istio.io/use-waypoint=waypoint
namespace/default labeled
{{< /text >}}

After a namespace is enrolled to use a waypoint, any requests from any pods using the ambient data plane mode, to any service running in that namespace, will be routed through the waypoint for L7 processing and policy enforcement.

If you prefer more granularity than using a waypoint for an entire namespace, you can enroll only a specific service or pod to use a waypoint. This may be useful if you only need L7 features for some services in a namespace, if you only want an extension like a `WasmPlugin` to apply to a specific service, or if you are calling a Kubernetes
[headless service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) by its pod IP address.

{{< tip >}}
If the `istio.io/use-waypoint` label exists on both a namespace and a service, the service waypoint takes precedence over the namespace waypoint as long as the service waypoint can handle `service` or `all` traffic. Similarly, a label on a pod will take precedence over a namespace label.
{{< /tip >}}

### Configure a service to use a specific waypoint

Using the services from the sample [bookinfo application](/docs/examples/bookinfo/), we can deploy a waypoint called `reviews-svc-waypoint` for the `reviews` service:

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-svc-waypoint
waypoint default/reviews-svc-waypoint applied
{{< /text >}}

Label the `reviews` service to use the `reviews-svc-waypoint` waypoint:

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint
service/reviews labeled
{{< /text >}}

Any requests from pods in the mesh to the `reviews` service will now be routed through the `reviews-svc-waypoint` waypoint.

### Configure a pod to use a specific waypoint

Deploy a waypoint called `reviews-v2-pod-waypoint` for the `reviews-v2` pod.

{{< tip >}}
Recall the default for waypoints is to target services; as we explicitly want to target a pod, we need to use the `istio.io/waypoint-for: workload` label, which we can generate by using the `--for workload` parameter to istioctl.
{{< /tip >}}

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-v2-pod-waypoint --for workload
waypoint default/reviews-v2-pod-waypoint applied
{{< /text >}}

Label the `reviews-v2` pod to use the `reviews-v2-pod-waypoint` waypoint:

{{< text syntax=bash >}}
$ kubectl label pod -l version=v2,app=reviews istio.io/use-waypoint=reviews-v2-pod-waypoint
pod/reviews-v2-5b667bcbf8-spnnh labeled
{{< /text >}}

Any requests from pods in the ambient mesh to the `reviews-v2` pod IP will now be routed through the `reviews-v2-pod-waypoint` waypoint for L7 processing and policy enforcement.

{{< tip >}}
The original destination type of the traffic is used to determine if a service or workload waypoint will be used. By using the original destination type the ambient mesh avoids having traffic transit waypoint twice, even if both service and workload have attached waypoints.
For instance, traffic which is addressed to a service, even though ultimately resolved to a pod IP, is always treated by the ambient mesh as to-service and would use a service-attached waypoint.
{{< /tip >}}

## Cross-namespace waypoint use {#usewaypointnamespace}

Straight our of the box a waypoint proxy is usable by resources within the same namespace. Beginning with Istio 1.23 it is possible to use waypoints in different namespaces. In this section we will examine the gateway configuration required to enable cross-namespace use as well as how to configure your resources to use a waypoint from a different namespace.

### Configure a waypoint for cross-namespace use

In order to enable cross-namespace use of a waypoint the Gateway.gateway.networking.k8s.io should be configured to [allow routes](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.AllowedRoutes) from other namespaces. 

{{< tip >}}
The keyword, `All`, may be specified as the value for `allowedRoutes.namespaces.from` in order to allow routes from any namespace.
{{< /tip >}}

The following Gateway would allow resources in a namespace called "cross-namespace-waypoint-consumer" to use this egress-gateway:

{{< text syntax=yaml >}}
kind: Gateway
metadata:
  name: egress-gateway
  namespace: common-infrastructure
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: cross-namespace-waypoint-consumer
{{< /text >}}


### Configure resources to use a cross-namespace waypoint proxy

By default the Istio control plane will look for a waypoint specified using the `istio.io/use-waypoint` label in the same namespace as the resource which the label is applied to. It is possible to use a waypoint in another namespace by adding a new label, `istio.io/use-waypoint-namespace`. These two labels are used together to specify the name and namespace of your waypoint respectively. For example, to configure a ServiceEntry called "istio-io" to use a waypoint called "egress-gateway" in the namespace called "common-infrastructure" you could use the following commands:

{{< text syntax=bash >}}
$ kubectl label serviceentries.networking.istio.io istio-io istio.io/use-waypoint=egress-gateway
serviceentries.networking.istio.io/istio-io labeled
$ kubectl label serviceentries.networking.istio.io istio-io istio.io/use-waypoint-namespace=common-infrastructure
serviceentries.networking.istio.io/istio-io labeled
{{< /text >}}


### Cleaning up

You can remove all waypoints from a namespace by doing the following:

{{< text syntax=bash snip_id=delete_waypoint >}}
$ istioctl waypoint delete --all -n default
$ kubectl label ns default istio.io/use-waypoint-
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
