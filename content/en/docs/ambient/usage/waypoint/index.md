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
apiVersion: gateway.networking.k8s.io/v1
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

Note the Gateway resource has a `gatewayClassName` of `istio-waypoint`, which instantiates an Istio-managed waypoint. The Gateway resource is labeled with `istio.io/waypoint-for: service`, indicating the waypoint can process traffic for services, which is the default.

To deploy a waypoint proxy directly, use `apply` instead of `generate`:

{{< text syntax=bash snip_id=apply_waypoint >}}
$ istioctl waypoint apply -n default
waypoint default/waypoint applied
{{< /text >}}

Or, you can deploy the generated Gateway resource:

{{< text syntax=bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
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

### Ingress gateways and waypoints {#ingress-and-waypoints}

The `istio.io/use-waypoint` label governs **east-west** traffic: requests from other pods in the mesh to the labeled namespace, service, or workload are sent through the destination waypoint for Layer 7 policy and telemetry.

Traffic from an **Istio ingress gateway** to that `Service` is modeled separately. By default, ingress-originated traffic will **not** use the destination service waypoint, even when `istio.io/use-waypoint` is set on the service or namespace.

To direct ingress traffic through the same waypoint as mesh traffic, set **`istio.io/ingress-use-waypoint`** to `true` on the Kubernetes `Service`, or on the `Namespace` to apply to all services in that namespace (supported starting with Istio 1.25). See the [resource labels](/docs/reference/config/labels/#IoIstioIngressUseWaypoint) reference for supported resource types.

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/ingress-use-waypoint=true
service/reviews labeled
{{< /text >}}

{{< tip >}}
Enabling this path results in **Layer 7 processing at both the ingress gateway and the waypoint** (a two-tier gateway pattern). Consider authorization rules, latency, and metrics for both hops.
{{< /tip >}}

The control plane only applies this behavior when **`ENABLE_INGRESS_WAYPOINT_ROUTING`** is enabled for istiod; it defaults to `false`. See [`ENABLE_INGRESS_WAYPOINT_ROUTING`](/docs/reference/commands/pilot-discovery/#enable-ingress-waypoint-routing) in the pilot-discovery environment reference.

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

### Require traffic to traverse the waypoint {#require-waypoint}

The `istio.io/use-waypoint` label records your intent to send traffic through a waypoint, but on its own it does not guarantee that this happens. ztunnel routes traffic directly to the destination, rather than failing the request, when:

* the named waypoint does not exist or has no address; or
* the traffic type does not match the traffic the waypoint handles; for example, a request sent directly to a workload (a pod or VM IP) when the waypoint only handles service traffic, which is the [default](#waypoint-traffic-types).

In either case, any Layer 7 policy that the waypoint would have enforced never takes effect, and traffic flows as though no waypoint were configured.

If enforcing a waypoint's Layer 7 policies is a security requirement, make the waypoint mandatory with an `AuthorizationPolicy` that allows only the waypoint's identity. A waypoint uses the service account named after its `Gateway`, so a policy on the destination workloads that allows only that identity denies any client that reaches them without first passing through the waypoint. Continuing with the `reviews-svc-waypoint` waypoint from above:

{{< text syntax=yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: require-waypoint
  namespace: default
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/reviews-svc-waypoint
{{< /text >}}

This policy uses a workload `selector` rather than a `targetRef`, so it is enforced at Layer 4 by ztunnel. It therefore takes effect in both bypass cases: when the waypoint is unavailable, and when a client dials the workload directly.

### Shift traffic between waypoints {#waypoint-canary}

{{< warning >}}
Shifting traffic between waypoints is supported starting with Istio 1.31 and is considered [Alpha](https://github.com/istio/community/blob/master/FEATURE-LIFECYCLE.md). The labels, annotation, and behavior may change in future releases.
{{< /warning >}}

Changing the `istio.io/use-waypoint` label on a service moves all of its traffic to the new waypoint at once. To move a service between two waypoints gradually, for example to validate a new waypoint revision during an upgrade, name a second *canary* waypoint alongside the primary and give it a share of the service's traffic. The configuration lives entirely on the destination service: clients are unaware of it, and no second `Service` is required.

| Name | Kind | Purpose |
| --- | --- | --- |
| [`istio.io/use-waypoint-canary`](/docs/reference/config/labels/#IoIstioUseWaypointCanary) | label | Name of the canary waypoint `Gateway`. |
| [`istio.io/use-waypoint-canary-namespace`](/docs/reference/config/labels/#IoIstioUseWaypointCanaryNamespace) | label | Namespace of the canary waypoint, if it is not the namespace of the service. |
| [`istio.io/use-waypoint-canary-weight`](/docs/reference/config/annotations/#IoIstioUseWaypointCanaryWeight) | annotation | Share of traffic sent to the canary, as an integer from 0 to 100. The primary waypoint receives the remainder. Defaults to 0. |

Continuing with the `reviews` service from above, deploy a second waypoint and send 5% of the service's traffic to it, leaving the remaining 95% on `reviews-svc-waypoint`:

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-svc-waypoint-v2
waypoint default/reviews-svc-waypoint-v2 applied
{{< /text >}}

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint-canary=reviews-svc-waypoint-v2
$ kubectl annotate service reviews istio.io/use-waypoint-canary-weight=5
{{< /text >}}

Raise the weight as you gain confidence in the canary. Once the canary is carrying all of the traffic, promote it by making it the primary waypoint and removing the canary configuration:

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint-v2 --overwrite
$ kubectl label service reviews istio.io/use-waypoint-canary-
$ kubectl annotate service reviews istio.io/use-waypoint-canary-weight-
{{< /text >}}

To roll back at any point, remove the canary label. The service returns to sending all of its traffic through the primary waypoint.

#### Supported resources

The canary labels and annotation are supported on `Service`, `ServiceEntry`, and `Namespace`. Unlike `istio.io/use-waypoint`, they are **not** supported on `Pod` or `WorkloadEntry`: the split is defined at the service level so that it behaves the same for mesh and ingress traffic.

A canary configured on a namespace only applies to services that also inherit their primary waypoint from that namespace. If a service sets its own `istio.io/use-waypoint`, it must set its own canary configuration too; the namespace's canary labels are ignored for that service.

Both waypoints must be able to front the service. Each must be ready, must allow attachment from the service's namespace, and must handle `service` or `all` traffic.

#### What the weight applies to

* **Mesh traffic** is split by {{< gloss >}}ztunnel{{< /gloss >}} **per connection**: the weight is the share of *new* connections that select the canary. Established connections are never moved, so a service whose clients hold long-lived connections will approach the configured weight only as those clients reconnect. For the same reason, the observed split is approximate, and is only meaningful over a large number of connections.
* **Ingress traffic** is split by the ingress gateway **per request**, and only for services that opt in with `istio.io/ingress-use-waypoint` as described in [Ingress gateways and waypoints](#ingress-and-waypoints). Without that opt-in, ingress traffic continues to bypass both waypoints.

The mesh split requires a ztunnel from Istio 1.31 or later. While the data plane is being upgraded, nodes still running an older ztunnel send all of their connections to the primary waypoint, so the split across the mesh lags the configured weight until every node is upgraded. The ingress split does not depend on ztunnel.

#### Configuration attached to the waypoint

Both waypoints serve the same service, so any configuration that must remain in effect during the shift has to apply at both. Policies and routes that target the `Service`, such as an `AuthorizationPolicy` or an `HTTPRoute` with the service as its `parentRef`, are enforced by whichever waypoint handles the traffic and need no duplication.

Configuration attached to a waypoint `Gateway` itself is a different matter. A `WasmPlugin` selecting the waypoint, or a policy whose `targetRef` names the `Gateway`, applies only to that waypoint. Replicate it on the canary before shifting traffic, otherwise the share of traffic going through the canary is handled with a different set of policies.

#### Invalid configuration

An unusable canary is not fatal. The service keeps using its primary waypoint alone, and the reason is reported in the `istio.io/WaypointBound` condition on the service:

{{< text syntax=bash >}}
$ kubectl get service reviews -o jsonpath='{.status.conditions}'
{{< /text >}}

This fallback applies when the canary waypoint does not exist, is not ready, does not allow attachment from the service's namespace, or cannot handle service traffic; when the weight is not an integer between 0 and 100 (`CanaryInvalidWeight`); and when the canary names the same waypoint as the primary (`CanarySameAsPrimary`).

## Cross-namespace waypoint use {#usewaypointnamespace}

Straight out of the box, a waypoint proxy is usable by resources within the same namespace. Beginning with Istio 1.23, it is possible to use waypoints in different namespaces. In this section, we will examine
the gateway configuration required to enable cross-namespace use and how to configure your resources to use a waypoint from a different namespace.

### Configure a waypoint for cross-namespace use

In order to enable cross-namespace use of a waypoint, the `Gateway` should be configured to [allow routes](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io%2fv1.AllowedRoutes) from other namespaces.

{{< tip >}}
The keyword `All` may be specified as the value for `allowedRoutes.namespaces.from` in order to allow routes from any namespace.
{{< /tip >}}

The following `Gateway` would allow resources in a namespace called "cross-namespace-waypoint-consumer" to use this `egress-gateway`:

{{< text syntax=yaml >}}
apiVersion: gateway.networking.k8s.io/v1
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

By default, the Istio control plane will look for a waypoint specified using the `istio.io/use-waypoint` label in the same namespace as the resource which the label is applied to. It is possible to use
a waypoint in another namespace by adding a new label, `istio.io/use-waypoint-namespace`. `istio.io/use-waypoint-namespace` works for all resources which support the `istio.io/use-waypoint` label.
Together, the two labels specify the name and namespace of your waypoint respectively. For example, to configure a `ServiceEntry` named `istio-site` to use a waypoint named `egress-gateway` in the namespace
named `common-infrastructure`, you could use the following commands:

{{< text syntax=bash >}}
$ kubectl label serviceentries.networking.istio.io istio-site istio.io/use-waypoint=egress-gateway
serviceentries.networking.istio.io/istio-site labeled
$ kubectl label serviceentries.networking.istio.io istio-site istio.io/use-waypoint-namespace=common-infrastructure
serviceentries.networking.istio.io/istio-site labeled
{{< /text >}}

### Cleaning up

You can remove all waypoints from a namespace by doing the following:

{{< text syntax=bash snip_id=delete_waypoint >}}
$ istioctl waypoint delete --all -n default
$ kubectl label ns default istio.io/use-waypoint-
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
