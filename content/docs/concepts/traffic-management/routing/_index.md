---
title: Traffic Routing and Configuration
description: Learn about the Istio features and components needed to implement routing and control the ingress and egress of traffic for the mesh.
weight: 2
content_above: true
keywords: [traffic-management, virtual-service, routing-rule, destination-rule, ingress, egress, gateway, service-entry, sidecar]
---

The Istio traffic routing and configuration model relies on the following
network resources of the Istio API:

-  **Virtual services**

    Use a [virtual service](/docs/concepts/traffic-management/routing/virtual-services/)
    to configure an ordered list of routing rules to control how Envoy proxies
    route requests for a service within an Istio service mesh.

-  **Destination rules**

    Use [destination rules](/docs/concepts/traffic-management/routing/destination-rules/)
    to configure the policies you want Istio to apply to a request after
    enforcing the routing rules in your virtual service.

-  **Gateways**

    Use [gateways](/docs/concepts/traffic-management/routing/gateways/)
    to configure how the Envoy proxies load balance HTTP, TCP, or gRPC traffic.

-  **Service entries**

    Use a [service entry](/docs/concepts/traffic-management/routing/service-entries/)
    to add an entry to Istio's **abstract model** that configures routing rules
    for external dependencies of the mesh.

-  **Sidecars**

    Use a [sidecar](/docs/concepts/traffic-management/routing/sidecars/)
    to configure the scope of the Envoy proxies to enable certain features,
    like namespace isolation.

You configure these features using the Istio Networking API to configure
fine-grained traffic control for a range of use cases:

-  Configure ingress traffic, enforce traffic policing, perform a traffic
   rewrite.

-  Set up load balancers and define [service subsets](/docs/concepts/traffic-management/routing/destination-rules//#service-subsets)
   as destinations in the mesh.

-  Set up canary rollouts, circuit breakers, timeouts, and retries to test
   network resilience.

-  Configure TLS settings and outlier detection.

The next section walks through some common use cases and describes how Istio
supports them. Following sections describe each of the network resources in
more detail.

## Traffic routing use cases

You might use all or only some of the Istio network resources, depending on
your platform and your use case. Your platform handles basic traffic routing,
but configurations for advanced use cases might require the full range of Istio
traffic routing features.

### Routing traffic to multiple versions of a service {#routing-versions}

Typically, requests sent to services use a service's hostname or IP address,
and clients sending requests don't distinguish between different versions of
the service.

With Istio, because the Envoy proxy intercepts and forwards all requests and
responses between the clients and the services, you can use routing rules with
service subsets in a virtual service to configure the traffic routes for
multiple versions of a service.

The following diagram shows a configuration that relies on routing rules to
handle the communication between a client and a service that has multiple
versions.

Envoy proxies dynamically determine where to send the traffic based on the
routing rules you configure in the [ingress gateway](/docs/concepts/traffic-management/routing/gateways/)
and [virtual service](/docs/concepts/traffic-management/routing/virtual-services).
In this example, those rules route the incoming request to v1, v2, or v3 of
your application's service.

You use the Istio [networking APIs](/docs/reference/config/networking/)
to configure [network resources](/docs/concepts/traffic-management/routing/)
and specify the [routing rules](/docs/concepts/traffic-management/routing/virtual-services/#routing-rules).

The advantage of this configuration method is that it decouples the application
code from the evolution of its dependent services. This in turn provides
monitoring benefits. For details, see [Mixer policies and telemetry](/docs/concepts/policies-and-telemetry/).

### Canary rollouts with autoscaling {#canary}

Canary rollouts allow you to test a new version of a service by sending a small
amount of traffic to the new version. If the test is successful, you can
gradually increase the percentage of traffic sent to the new version until all
the traffic is moved. If anything goes wrong along the way, you can abort the
rollout and return the traffic to the old version.

Container orchestration platforms like Docker, or Kubernetes support canary
rollouts, but they use instance scaling to manage traffic distribution, which
quickly becomes complex, especially in a production environment that requires
autoscaling.

With Istio, you can configure traffic routing and instance deployment as
independent functions. The number of instances implementing the services can
scale up and down based on traffic load without referring to version traffic
routing at all. This makes managing a canary version that includes autoscaling
a much simpler problem. For details, see the [Canary Deployments](/blog/2017/0.1-canary/)
blog post.

### Splitting traffic for A/B testing {#splitting}

With [service subsets](/docs/concepts/traffic-management/routing/destination-rules/#service-subsets),
you can label all instances that correspond to a specific version of a service.
Before you configure routing rules, the Envoy proxies use round-robin load
balancing across all service instances, regardless of their subset. Once you
configure routing rules for traffic to reach specific subsets, the Envoy
proxies route traffic to the subset according to the rule but again use
round-robin to route traffic across the instances of each subset. You can
change this default load balancing behavior of the Envoy proxies. To learn
more, visit the [Envoy load balancing documentation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/load_balancing/load_balancing).

In this example for A/B testing, we configure traffic routes based on
percentages. With Istio, you can use a virtual service to specify a routing
rule that sends 25% of requests to instances in the `v2` subset, and sends the
remaining 75% of requests to instances in the `v1` subset. The following
configuration accomplishes our example for the `reviews` service.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 75
    - destination:
        host: reviews
        subset: v2
      weight: 25
{{< /text >}}
