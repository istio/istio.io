---
title: Virtual Services
description: Describes the architecture and behavior of virtual services and provides configuration examples.
weight: 3
keywords: [routing, request, traffic routing, requests routing, virtual service, subset, routing rules]
aliases:
---

A [virtual service](/docs/reference/config/istio.networking.v1alpha3/#VirtualService)
configures the rules controlling how **Pilot** routes requests for a service
within an Istio service mesh.

You can use virtual services for fine-grained traffic control. Istio can use
virtual services to configure ingress, canary, traffic rewrite, or traffic
policing. A virtual service is not required for simple connectivity. A service
can map one or more user-addressable destinations to the actual destination
workloads inside the mesh without a virtual service. The Istio virtual services
can configure traffic routes to:

-  Specific services or subsets in the mesh.
-  Other network configuration objects in the mesh.

{{< image width="60%"
    link="./virtual-services-1.svg"
    caption="Possible configurations between virtual services and workloads"
    >}}

As you can see, virtual services are very flexible and can accommodate a wide
variety of topologies. Virtual services configure the [traffic routes](../traffic-routing)
to your application services. The Istio virtual services can use any DNS names
with optional wildcard prefixes or CIDR prefixes to create a single rule for
all matching services. You can address one or more application services through
a single Istio virtual service. To eliminate redundant rules, you can add
[multiple match conditions](../routing-rules/#multi-condition) to a virtual
service configuration.

If your mesh uses Kubernetes, for example, you can configure a virtual service
to handle all services in a specific namespace. With the Istio virtual
services, you can configure routes for the [canary rollout](../traffic-routing/#canary)
and A/B testing for your application's services. You can configure each
application service version as a [virtual service subset](../traffic-routing)
and configure the corresponding Istio destination rule to determine the set of
pods or VMs belonging to these subsets.

You can use the Istio virtual services in a variety of ways, for example: to
route traffic following the rules to provide [load balancing](../load-balancing)
to the ingress and egress traffic of your mesh with [Istio gateways](../gateways),
and to address multiple application services through a single Istio virtual
service.

The following example shows an Istio virtual service configuration file with
descriptive value entries. You can use this example as a basis and modify it to
fit your needs. The example configures a route for traffic to reach
the `v1` subset of the `my-svc` service from the `my-vtl-svc` virtual service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-vtl-svc
spec:
  hosts:
    - *.my-co.org
      route:
      - destination:
        host: service
        subset: v1
{{< /text >}}

Virtual services can specify the DNS host name using the `hosts:` field under
`spec:`. As you can see in the `my-vtl-svc` example, you can use a wildcard for
the virtual service configurations to apply to multiple hosts. In the
`destination:` field of each route, you specify the `host:` of your service and
subset that the configuration targets. The following diagram shows the
configured rule:

{{< image width="50%"
    link="./virtual-services-2.svg"
    caption="A virtual service configurable traffic to a specific subset"
    >}}

Istio does not need virtual services to connect to services. More commonly, you
use virtual services to finely configure traffic. For example, to direct HTTP
traffic to use a different version of the service for a specific user. To
specify the user, the following example uses a regular expression to match the
user from the cookie and shows you how to add the condition for the protocol in
the `http:` field and a new `route:` and `destination:` configuration for the
traffic matching the condition. In short, the example configures the HTTP
traffic from the `jason` user to go to the `v2` subset of the `my-svc` service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-vtl-svc
spec:
  hosts:
    - *
    - route:
      - destination:
        host: my-svc
        subset: v1
  http:
    - match:
      - headers:
          cookie:
            regex: "^(.*?;)?(user=jason)(;.*)?$"
    route:
      - destination:
        host: my-svc
        subset: v2
{{< /text >}}

The following diagram shows the configured traffic rules for both the traffic
with the matched cookie and for all other traffic:

{{< image width="50%"
    link="./virtual-services-3.svg"
    caption="Configurable traffic rules for traffic with and without a matched cookie"
    >}}

You can configure virtual services to manage the traffic to your Kubernetes
namespaces. The following example shows the `my-namespace` virtual service to
configure traffic routes for the two services in the
`my-namespace.svc.cluster.local` Kubernetes namespace:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-namespace
spec:
  hosts:
    - *.my-namespace.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /svc-1
    route:
    - destination:
        host: svc-1
  - match:
    - uri:
        prefix: /svc-2
    route:
    - destination:
        host: svc-2
{{< /text >}}

The following diagram shows the configured traffic routes for services in a
Kubernetes namespace using a virtual service for two distinct application
services based on the URI prefixes:

{{< image width="50%"
    link="./virtual-services-4.svg"
    caption="Configurable traffic rules implementing a namespace for two  application services"
    >}}

Once you have identified and configured the virtual services suitable for your
mesh, you can add [gateways](../gateways) to route traffic in or out of your
mesh. The virtual services together with [destination rules](../destination-rules)
allow you to configure the behavior of the traffic to fulfill the needs of your
mesh. Together with a [service entry](../service-entries), you can use virtual
services to configure traffic routes to external dependencies.

Visit our [virtual services reference documentation](/docs/reference/config/istio.networking.v1alpha3/#VirtualService)
to review all the enabled keys and values.
