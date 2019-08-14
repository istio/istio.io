---
title: Traffic Management
description: Describes the various Istio features focused on traffic routing and control.
weight: 20
keywords: [traffic-management,pilot, envoy-proxies, service-discovery, load-balancing]
aliases:
    - /docs/concepts/traffic-management/pilot
    - /docs/concepts/traffic-management/rules-configuration
    - /docs/concepts/traffic-management/fault-injection
    - /docs/concepts/traffic-management/handling-failures
    - /docs/concepts/traffic-management/load-balancing
    - /docs/concepts/traffic-management/request-routing
    - /docs/concepts/traffic-management/pilot.html
---

- [Overview and terminology](/docs/concepts/traffic-management/#overview-and-terminology):
  Learn about Pilot, Istio's core traffic management component and Envoy
  proxies and how they enable service discovery and traffic control for services in the mesh.

- [Traffic routing and configuration](/docs/concepts/traffic-management/#traffic-routing-and-configuration):
  Learn about the Istio features and resources needed to configure routing and
  control the ingress and egress of traffic for the mesh.

- [Network resilience and testing](/docs/concepts/traffic-management/#network-resilience-and-testing):
  Learn about Istio's dynamic failure recovery features that you can configure
  to test and build tolerance for failing nodes, and to prevent cascading failures to
  other nodes.

## Overview and terminology

With Istio, you can manage service discovery, traffic routing, and load balancing
for your service mesh without having to update your services. Istio simplifies
configuration of service-level properties like timeouts and retries, and makes
it straightforward to set up tasks like staged rollouts with percentage-based
traffic splits.

Istio's traffic management model relies on the following two components:

- {{< gloss >}}Pilot{{</ gloss >}}, the core traffic management component.
- {{< gloss >}}Envoy{{</ gloss >}} proxies, which enforce configurations and policies set through Pilot.

These components enable the following Istio traffic management features:

- Service discovery
- Load balancing
- Traffic routing and control

### Pilot: Core traffic management {#pilot}

The following diagram shows the Pilot architecture:

{{< image width="40%"
    link="./pilot-arch.svg"
    caption="Pilot architecture"
    >}}

As the diagram illustrates, Pilot maintains an **abstract model** of all the
services in the mesh. **Platform-specific adapters** in Pilot translate the
abstract model appropriately for your platform.
For example, the Kubernetes adapter implements controllers to watch the
Kubernetes API server for changes to pod registration information and service
resources. The Kubernetes adapter translates this
data for the abstract model.

Pilot uses the abstract model to generate appropriate Envoy-specific configurations
to let Envoy proxies know about one another in the mesh through the **Envoy API.**

You can use Istio's **Traffic Management API** to instruct Pilot to refine
the Envoy configuration to exercise more granular control
over the traffic in your service mesh.

### Envoy proxies

Traffic in Istio is categorized as data plane traffic and control plane
traffic. Data plane traffic refers to the data that the business logic of the
workloads manipulate. Control plane traffic refers to configuration and control
data sent between Istio components to program the behavior of the mesh. Traffic
management in Istio refers exclusively to data plane traffic.

Envoy proxies are the only Istio components that interact with data plane
traffic. Envoy proxies route the data plane traffic across the mesh and enforce
the configurations and traffic rules without the services having to be aware of
them. Envoy proxies mediate all inbound and outbound traffic for all services
in the mesh. Envoy proxies are deployed as sidecars to services, logically
augmenting the services with traffic management features:

- [service discovery and load balancing](/docs/concepts/traffic-management/#discovery)
- [traffic routing and configuration](/docs/concepts/traffic-management/#traffic-routing-and-configuration)
- [network resilience and testing](/docs/concepts/traffic-management/#network-resilience-and-testing)

Some of the features and tasks enabled by Envoy proxies include:

- Traffic control features: enforce fine-grained traffic control with rich
   routing rules for HTTP, gRPC, WebSocket, and TCP traffic.

- Network resiliency features: setup retries, failovers, circuit breakers, and
   fault injection.

- Security and authentication features: enforce security policies and enforce
   access control and rate limiting defined through the configuration API.

#### Service discovery and load balancing {#discovery}

Istio service discovery leverages the service discovery features provided by
platforms like Kubernetes for container-based applications.
Service discovery works in a similar way regardless of what platform you're
using:

1. The platform starts a new instance of a service which notifies its platform
   adapter.

1. The platform adapter registers the instance with the Pilot abstract model.

1. **Pilot** distributes traffic rules and configurations to the Envoy proxies
   to account for the change.

The following diagram shows how the platform adapters and Envoy proxies
interact.

{{< image width="40%"
    link="./discovery.svg"
    caption="Service discovery"
    >}}

Because the service discovery feature is platform-independent,
a service mesh can include services across multiple platforms.

Using the abstract model, Pilot configures the Envoy proxies to perform
load balancing for service requests, replacing any underlying
platform-specific load balancing feature.
In the absence of more specific routing rules, Envoy will distribute the traffic
across the instances in the calling service's load balancing pool, according to
the Pilot abstract model and load balancer configuration.

Istio supports the following load balancing methods:

- Round robin: Requests are forwarded to instances in the pool in turn, and
   the algorithm instructs the load balancer to go back to the top of the pool
   and repeat.

- Random: Requests are forwarded at random to instances in the pool.

- Weighted: Requests are forwarded to instances in the pool according to a
   specific percentage.

- Least requests: Requests are forwarded to instances with the least number of
   requests. See the [Envoy load balancing documentation](https://www.envoyproxy.io/docs/envoy/v1.5.0/intro/arch_overview/load_balancing)
   for more information.

You can also choose to prioritize your load balancing pools based on geographic
location. Visit the [operations guide](/docs/ops/traffic-management/locality-load-balancing/)
for more information on the locality load balancing feature.

In addition to basic service discovery and load balancing, Istio provides a rich
set of traffic routing and control features, which are described in the following sections.

## Traffic routing and configuration

The Istio traffic routing and configuration model relies on the following
Istio [traffic management API](/docs/reference/config/networking/) resources:

- **Virtual services**

    Use a [virtual service](/docs/concepts/traffic-management/#virtual-services)
    to configure an ordered list of routing rules to control how Envoy proxies
    route requests for a service within an Istio service mesh.

- **Destination rules**

    Use [destination rules](/docs/concepts/traffic-management/#destination-rules)
    to configure the policies you want Istio to apply to a request after
    enforcing the routing rules in your virtual service.

- **Gateways**

    Use [gateways](/docs/concepts/traffic-management/#gateways)
    to configure how the Envoy proxies load balance HTTP, TCP, or gRPC traffic.

- **Service entries**

    Use a [service entry](/docs/concepts/traffic-management/#service-entries)
    to add an entry to Istio's **abstract model** that configures
    external dependencies of the mesh.

- **Sidecars**

    Use a [sidecar](/docs/concepts/traffic-management/#sidecars)
    to configure the scope of the Envoy proxies to enable certain features,
    like namespace isolation.

You can use these resources to configure
fine-grained traffic control for a range of use cases:

- Configure ingress traffic, enforce traffic policing, perform a traffic
   rewrite.

- Set up load balancers and define [service subsets](/docs/concepts/traffic-management/#service-subsets)
   as destinations in the mesh.

- Set up canary rollouts, circuit breakers, timeouts, and retries to test
   network resilience.

- Configure TLS settings and outlier detection.

The next section walks through some common use cases and describes how Istio
supports them. Following sections describe each of the traffic management API resources in
more detail.

### Traffic routing use cases

You might use all or only some of the Istio traffic management API resources,
depending on your use case. Istio handles basic traffic routing by default,
but configurations for advanced use cases might require the full range of Istio
traffic routing features.

#### Routing traffic to multiple versions of a service {#routing-versions}

Typically, requests sent to services use a service's hostname or IP address,
and clients sending requests don't distinguish between different versions of
the service.

With Istio, because the Envoy proxy intercepts and forwards all requests and
responses between the clients and the services, you can use routing rules with
[service subsets](/docs/concepts/traffic-management/#service-subsets)
in a virtual service to configure the [routing rules](/docs/concepts/traffic-management/#routing-rules)
for multiple versions of a service.

Service subsets are used to label all instances that correspond to a specific
version of a service.
Before you configure routing rules, the Envoy proxies use round-robin load
balancing across all service instances, regardless of their subset. After you
configure routing rules for traffic to reach specific subsets, the Envoy
proxies route traffic to the subset according to the rule but again use
round-robin to route traffic across the instances of each subset.

This configuration method provides the following advantages:

- Decouples the application code from the evolution of the application's dependent services.
- Provides monitoring benefits.
For details, see [Mixer policies and telemetry](/docs/reference/config/policy-and-telemetry/).

For example, in A/B testing we often want to configure traffic routes based on
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

#### Canary rollouts with autoscaling {#canary}

Canary rollouts allow you to test a new version of a service by sending a small
amount of traffic to the new version. If the test is successful, you can
gradually increase the percentage of traffic sent to the new version until all
the traffic is moved. If anything goes wrong along the way, you can abort the
rollout and return the traffic to the old version.

Container orchestration platforms like Docker or Kubernetes support canary
rollouts, but they use instance scaling to manage traffic distribution, which
quickly becomes complex, especially in a production environment that requires
autoscaling.

With Istio, you can configure traffic routing and instance deployment as
independent functions. The number of instances implementing the services can
scale up and down based on traffic load without referring to version traffic
routing at all. This makes managing a canary version that includes autoscaling
a much simpler problem. For details, see the [Canary Deployments](/blog/2017/0.1-canary/)
blog post.

## Virtual services

A [virtual service](/docs/reference/config/networking/v1alpha3/virtual-service/)
is a resource you can use to configure how Envoy proxies route requests
to a service within an Istio service mesh. Virtual services let you finely
configure traffic behavior. For example, you can use virtual services to direct
HTTP traffic to use a different version of the service for a specific user.

Istio and your platform provide basic connectivity and discovery for your
services. With virtual services, you can add a configuration layer to set up
complex traffic routing. You can map user-addressable destinations to real
workloads in the mesh, for example. Or, you can configure more advanced traffic
routes to specific services or subsets in the mesh.

Your mesh can require multiple virtual services or none depending on your use
case. You can add [gateways](/docs/concepts/traffic-management/#gateways)
to route traffic in or out of your mesh, or combine virtual services with
[destination rules](/docs/concepts/traffic-management/#destination-rules)
to configure the behavior of the traffic. You can use a [service entry](/docs/concepts/traffic-management/#service-entries)
to add external dependencies to the mesh and combine them with virtual services
to configure the traffic to these dependencies. The following diagrams
show some example virtual service configurations:

- 1:1 relationship: Virtual service A configures routing rules for traffic to
   reach service X.

   {{< image width="40%"
    link="./virtual-services-1.svg"
    caption="1 : 1 relationship"
    >}}

- 1:many relationship:

    - Virtual service B configures routing rules for traffic to reach services
      Y and Z.

       {{< image width="40%"
        link="./virtual-services-2.svg"
        caption="1 : multiple services"
        >}}

    - Virtual service C configures routing rules for traffic to reach different
      versions of service W.

         {{< image width="40%"
          link="./virtual-services-3.svg"
          caption="1 : multiple versions"
          >}}

You can use virtual services to perform the following types of tasks:

- Configure each application service version as a
   [subset](/docs/concepts/traffic-management/#service-subsets) and add
   a corresponding [destination
   rule](/docs/concepts/traffic-management/#destination-rules) to
   determine the set of pods or VMs belonging to these subsets.

- Configure traffic rules in combination with
   [gateways](/docs/concepts/traffic-management/#gateways)
   to control ingress and egress traffic

- Add [multiple match conditions](/docs/concepts/traffic-management/#multi-match)
   to a virtual service configuration to eliminate redundant rules.

- Configure [traffic routes](/docs/concepts/traffic-management/#routing-subset)
   to your application services using DNS names. These DNS names support
   wildcard prefixes or CIDR prefixes to create a single rule for all matching
   services.

- Address one or more application services through a single virtual service.
   If your mesh uses Kubernetes, for example, you can configure a virtual
   service to handle all services in a specific
   [namespace](/docs/concepts/traffic-management/#routing-namespace).

### Route requests to a subset {#routing-subset}

The following example configures the  `my-vtl-svc` virtual service to route
requests to the `v1` subset of the `my-svc` service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-vtl-svc
spec:
  hosts:
  - "*.my-co.org"
  http:
  - route:
    - destination:
        host: my-svc
        subset: v1
{{< /text >}}

In the example, under `spec`,
`hosts` lists the virtual service's hosts. In this case, the
hosts are `*.my-co.org`, where `*` is a wildcard prefix indicating that this
virtual service handles routing for any DNS name ending with `.my-co.org`.

You can specify user-addressable hosts by using any DNS name or an internal
mesh service name as long as the name resolves, implicitly or explicitly, to
one or more fully qualified domain names (FQDN). To specify multiple hosts, you
can use wildcards.

Also, note that under `route`, which specifies the routing rule's
configuration, and `destination`, which specifies the routing rule's
destination, `host: my-svc` specifies the destination's host. If you are
running on Kubernetes, then `my-svc` is the name of a Kubernetes service.

You use the destination's host to specify where you want the traffic to be
sent. The destination's host must exist in the service registry. To use
external services as destinations, use [service entries](/docs/concepts/traffic-management/#service-entries)
to add those services to the registry.

{{< warning >}}
Istio **doesn't** provide [DNS](https://hosting.review/web-hosting-glossary/#9)
resolution. Applications can try to resolve the FQDN by using the DNS service
present in their platform of choice, for example `kube-dns`.
{{< /warning >}}

The following diagram shows the configured rule:

{{< image width="40%"
  link="./virtual-services-4.svg"
  caption="Configurable traffic route to send traffic to a specific subset"
    >}}

### Route requests to services in a Kubernetes namespace {#routing-namespace}

When you specify the `host` field for the destination of a route in a virtual service
using a short name like `svc-1`, Istio expands the short name into a fully qualified domain name.
To perform the expansion, Istio adds a domain suffix based on the namespace of the virtual service that
contains the routing rule. For example, if the virtual service is defined in the `my-namespace` namespace,
Istio adds the `my-namespace.svc.cluster.local` suffix to the abbreviated destination resulting in
the actual destination: `svc-1.my-namespace.svc.cluster.local`.

While this approach is very convenient and commonly used to simplify examples, it can
easily lead to misconfigurations. Therefore we do
[not recommend it for production deployments](/docs/reference/config/networking/v1alpha3/virtual-service/#Destination).

The following example shows a virtual service configuration with fully qualified traffic routes
for two services in the `my-namespace` Kubernetes namespace.
The configuration relies on the URI prefixes of the two services to distinguish
them.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-namespace
spec:
  hosts:
  - my-namespace.com
  http:
  - match:
    - uri:
        prefix: /svc-1
    route:
    - destination:
        host: svc-1.my-namespace.svc.cluster.local
  - match:
    - uri:
        prefix: /svc-2
    route:
    - destination:
        host: svc-2.my-namespace.svc.cluster.local
{{< /text >}}

Using fully qualified hosts in the routing rules also provides more flexibility.
If you use short names, the destinations must be in the same namespace as the virtual service.
If you use fully qualified domain names, the destinations can be in any namespace.

### Routing rules

A virtual service consists of an ordered list of routing rules to define the
paths that requests follow within the mesh. You use virtual services to
configure the routing rules. A routing rule consists of a destination and zero
or more conditions, depending on your use case. You can also use routing rules
to perform some actions on the traffic, for example:

- Append or remove headers.

- Rewrite the URL.

- Set a retry policy.

To learn more about the actions available, see the [virtual service reference documentation](/docs/reference/config/networking/v1alpha3/virtual-service/#HTTPRoute).

#### Routing rule for HTTP traffic

The following example shows a virtual service that specifies
two HTTP traffic routing rules. The first rule includes a `match`
condition with a regular expression to check if the username "jason" is in the
request's cookie. If the request matches this condition, the rule sends
traffic to the `v2` subset of the `my-svc` service. Otherwise, the second rule
sends traffic to the `v1` subset of the `my-svc` service.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-vtl-svc
spec:
  hosts:
  - "*"
  http:
  - match:
    - headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
    route:
    - destination:
        host: my-svc
        subset: v2
  - route:
    - destination:
        host: my-svc
        subset: v1
{{< /text >}}

In the preceding example, there are two routing rules in the `http` section,
indicated by a leading `-` in front of the first field of each rule.

The first routing rule begins with the `match` field:

- `match` Lists the routing rule's matching conditions.

- `headers` Specifies to look for a match in the header of the request.

- `cookie` Specifies to look for a match in the header's cookie.

- `regex` Specifies the regular expression used to determine a match.

- `route` Specifies where to route the traffic
   matching the condition. In this case, that traffic is HTTP traffic with the
   username `jason` in the cookie of the request's header.

- `destination` Specifies the route destination for the traffic matching the rule conditions.

- `host` Specifies the destination's host, `my-svc`.

- `subset` Specifies the destination’s subset for the traffic matching the conditions, `v2` in this case.

The configuration of the second routing rule in the example begins with the
`route` field with a leading `-`. This rule applies to all traffic that doesn't match the
conditions specified in the first routing rule.

- `route` Specifies where to route all traffic except for HTTP traffic matching the condition of the previous rule.

- `destination` Specifies the routing rule's destination.

- `host` Specifies the destination's host, `my-svc`.

- `subset`  Specifies the destination’s subset, `v1` in this case.

The following diagram shows the configured traffic routes for the matched traffic and for all other traffic:

{{< image width="40%"
    link="./virtual-services-6.svg"
    caption="Configurable traffic route based on the namespace of two application services"
    >}}

Routing rules are evaluated in a specific order. For details, refer to
[Precedence](/docs/concepts/traffic-management/#precedence).

#### Match a condition

You can set routing rules that only apply to requests matching a specific
condition. For example, you can restrict traffic to specific client workloads
by using labels.

The following rule only applies to requests coming from instances of the
`reviews` service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
      sourceLabels:
        app: reviews
    route:
    ...
{{< /text >}}

The value of the `sourceLabels` key depends on the implementation of the
client workload. In Kubernetes, the value typically corresponds to the same labels you use in the
pod selector of the corresponding Kubernetes service.

The following example further refines the rule to apply only to requests from
an instance in the v2 subset:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    route:
    ...
{{< /text >}}

#### Conditions based on HTTP headers

You can also base conditions on HTTP headers. The following configuration sets
up a rule that only applies to an incoming request that includes a custom
`end-user` header containing the exact `jason` string:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    ...
{{< /text >}}

You can specify more than one header in a rule. All corresponding headers must
match.

#### Match request URI

The following routing rule is based on the request's URI: it only applies to a
request if the URI path starts with `/api/v1`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
spec:
  hosts:
  - productpage
  http:
  - match:
    - uri:
        prefix: /api/v1
    route:
    ...
{{< /text >}}

#### Multiple match conditions {#multi-match}

Conditions can have multiple matches simultaneously. In such cases, you use the
nesting of the conditions in the routing rule to specify whether AND or OR
semantics apply. To specify AND semantics, you nest multiple conditions in a
single section of `match.`

For example, the following rule applies only to requests that come from an
instance of the `reviews` service in the `v2` subset AND only if the requests
include the custom `end-user` header that contains the exact `jason` string:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
      headers:
        end-user:
          exact: jason
    route:
    ...
{{< /text >}}

To specify OR conditions, you place multiple conditions in separate sections of
`match.` Only one of the conditions applies. For example, the following rule
applies to requests from instances of the `reviews` service in the `v2` subset,
OR to requests with the custom `end-user` header containing the `jason` exact
string:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    - headers:
        end-user:
          exact: jason
    route:
    ...
{{< /text >}}

{{< warning >}}

In a YAML file, the difference between AND behavior and OR behavior in a
routing rule is a single dash. The dash indicates two separate matches as
opposed to one match with multiple conditions.

{{< /warning >}}

### Routing rule precedence {#precedence}

Multiple rules for a given destination in a configuration file are evaluated in
the order they appear. The first rule on the list has the highest priority.

Rules with no match condition that direct all or weighted percentages of
traffic to destination services are called **weight-based** rules to
distinguish them from other match-based rules. When routing for a particular
service is purely weight-based, you can specify it in a single rule.

When you use other conditions to route traffic, such as requests from a
specific user, you must use more than one rule to specify the routing.

It's important to ensure that your routing rules are evaluated in the right
order.

A best practice pattern to specify routing rules is as follows:

1. Provide one or more higher priority rules that match various conditions.

1. Provide a single weight-based rule with no match condition last. This rule
   provides the weighted distribution of traffic for all other cases.

#### Precedence example with 2 rules

The following virtual service configuration file includes two rules. The first
rule sends all requests for the `reviews` service that include the Foo header
with the bar value to the `v2` subset. The second rule sends all remaining
requests to the `v1` subset:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        Foo:
          exact: bar
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

In this example, the header-based rule has the higher priority because it comes
first in the configuration file. If the match-based rule came second, these
rules wouldn't work as expected. Istio would evaluate the weight-based rule
first and route all traffic to the instances in the `v1` subset, even requests
including the matching `Foo` header.

## Destination rules

You specify the path for traffic with routing rules, and then you use
[destination rules](/docs/reference/config/networking/v1alpha3/destination-rule/)
to configure the set of policies that Envoy proxies apply to a request at a
specific destination.

Destination rules are applied after the routing rules are evaluated.
Therefore, destination rules are matched against the destination in the routing rules,
not the host of the virtual service itself.
You can use wildcard prefixes in a
destination rule to specify a single rule for multiple services.

You can use destination rules to specify service subsets, that is, to group all
the instances of your service with a particular version together. You then
configure [routing rules](/docs/concepts/traffic-management/#routing-rules)
that route traffic to your subsets to send certain traffic to particular
service versions.

You specify explicit routing rules to service subsets. This model allows you
to:

- Cleanly refer to a specific service version across different
    [virtual services](/docs/concepts/traffic-management/#virtual-services).

- Simplify the stats that the Istio proxies emit.

- Encode subsets in Server Name Indication (SNI) headers.

### Load balancing 3 subsets

The following example destination rule configures three different subsets with
different load balancing policies for the `my-svc` destination service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-svc
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v3
    labels:
      version: v3
{{< /text >}}

As shown above, you can specify multiple policies in a single destination rule.
In this example, the default policy, defined above the subsets field,
sets a simple random load balancer for the `v1` and `v3` subsets. A `v2`
specific policy, a round robin load balancer, is defined in the corresponding subset's field.

See our [destination rules reference documentation](/docs/reference/config/networking/v1alpha3/destination-rule/)
to review all the enabled keys and values.

### Service subsets

Service subsets subdivide and label the instances of a service. To define the
divisions and labels, use the `subsets` section in [destination rules](/docs/reference/config/networking/v1alpha3/destination-rule/).
For example, you can use subsets to configure the following traffic routing
scenarios:

- Use subsets to route traffic to different versions of a service.

- Use subsets to route traffic to the same service in different environments.

You use service subsets in the routing rules of [virtual services](/docs/concepts/traffic-management/#virtual-services)
to control the traffic to your services.
You can also use subsets to customize Envoy's traffic policies when calling particular versions of a service.

Understanding service subsets in Istio allows you to configure the
communication to services with multiple versions within your mesh and configure
the following common use cases:

- [Splitting traffic between versions for A/B testing](/docs/concepts/traffic-management/#routing-subset)

- [Canary rollout](/docs/concepts/traffic-management/#canary)

To learn how you can use service subsets to configure failure handling use
cases, visit our [Network resilience and testing concept](/docs/concepts/traffic-management/#network-resilience-and-testing).

## Gateways

You use a [gateway](/docs/reference/config/networking/v1alpha3/gateway/) to
manage inbound and outbound traffic for your mesh. You can manage
[multiple types of traffic](/docs/reference/config/networking/v1alpha3/gateway/#Port)
with a gateway.

Gateway configurations apply to Envoy proxies that are running at the edge
of the mesh, which means that the Envoy proxies are not running as service sidecars.
To configure a gateway means configuring an Envoy
proxy to allow or block certain traffic from entering or leaving the mesh.

Your mesh can have any number of gateway configurations, and multiple gateway
workload implementations can co-exist within your mesh. You might use multiple
gateways to have one gateway for private traffic and another for public
traffic, so you can keep all private traffic inside a firewall, for example.

You can use a gateway to configure workload labels for your existing network
tasks, including:

- Firewall functions
- Caching
- Authentication
- Network address translation
- IP address management

Gateways are primarily used to manage ingress traffic, but you can also use a
gateway to configure an egress gateway. You can use egress gateways to
configure a dedicated exit node for the traffic leaving the mesh and configure
each egress gateway to use its own policies and telemetry.

You can use egress gateways to limit which services can or should access
external networks, or to enable [secure control of egress
traffic](/blog/2019/egress-traffic-control-in-istio-part-1/) to add security to
your mesh, for example. The following diagram shows the basic model of a
request flowing through a service mesh with an ingress gateway and an egress
gateway.

{{< image width="70%"
    link="./gateways-1.svg"
    caption="Request flow"
    >}}

All traffic enters the mesh through an ingress gateway workload. To configure
the traffic, use an Istio gateway and a virtual service. You bind the virtual
service to the gateway to use standard Istio [routing rules](/docs/concepts/traffic-management/#routing-rules)
to control HTTP requests and TCP traffic entering the mesh.

### Configure a gateway for external HTTPS traffic

The following example shows a possible gateway configuration for external HTTPS
ingress traffic:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ext-host-gwy
spec:
  selector:
    app: my-gateway-controller
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - ext-host
    tls:
      mode: SIMPLE
      serverCertificate: /tmp/tls.crt
      privateKey: /tmp/tls.key
{{< /text >}}

This gateway configuration lets HTTPS traffic from `ext-host` into the mesh on
port 443, but doesn't specify any routing for the traffic.

#### Bind a gateway to a virtual service

To specify routing and for the gateway to work as intended, you must also bind
the gateway to a virtual service. You do this using the virtual service's
`gateways` field, as shown in the following example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: virtual-svc
spec:
  hosts:
  - ext-svc
  gateways:
    - ext-host-gwy
{{< /text >}}

You can then configure the virtual service with routing rules for the external
traffic.

For more information:

- Refer to the [gateways reference documentation](/docs/reference/config/networking/v1alpha3/gateway/)
   to review all the enabled keys and values.

- Refer to the [Ingress task topic](/docs/tasks/traffic-management/ingress/) for instructions on how to configure
   an Istio gateway for ingress traffic.

- Refer to the [Egress gateway task](/docs/tasks/traffic-management/egress/egress-gateway/) to learn how to configure egress traffic
   using a gateway resource.

## Service entries

A [service entry](/docs/reference/config/networking/v1alpha3/service-entry)
is used to add an entry to Istio's abstract model, or
service registry, that Istio maintains internally. After you add the service
entry, the Envoy proxies can send traffic to the service as if it was
a service in your mesh.
Configuring service entries allows you to manage traffic for services running
outside of the mesh:

- Redirect and forward traffic for external destinations, such as APIs
   consumed from the web, or traffic to services in legacy infrastructure.

- Define
   [retry](/docs/concepts/traffic-management/#timeouts-and-retries),
   [timeout](/docs/concepts/traffic-management/#timeouts-and-retries),
   and [fault injection](/docs/concepts/traffic-management/#fault-injection)
   policies for external destinations.

- Add a service running in a Virtual Machine (VM) to the mesh to [expand your mesh](/docs/examples/mesh-expansion/).

- Logically add services from a different cluster to the mesh to configure a
  [multicluster Istio mesh](/docs/setup/install/multicluster/gateways/#configure-the-example-services)
  on Kubernetes.

You don’t need to add a service entry for every external service that you
want your mesh services to use. By default, Istio configures the Envoy proxies
to passthrough requests to unknown services, although you can't use Istio features
to control the traffic to destinations that are not registered in the mesh.

You can use service entries to perform the following configurations:

- Access secure external services over plain text ports,
  to configure Envoy to perform {{< gloss >}}TLS Origination{{</ gloss >}}.
- Ensure, together with an egress gateway, that all external services are
  accessed through a single exit point.

Refer to the [Egress task topic](/docs/tasks/traffic-management/egress/) for details.

## Add an external dependency securely

The following example mesh-external service entry adds the `ext-resource`
external dependency to Istio's service registry:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc-entry
spec:
  hosts:
  - ext-resource.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
  resolution: DNS
{{< /text >}}

You must specify the external resource using the `hosts` key. You can qualify
it fully or use a wildcard domain name. The value represents the set of one or
more services outside the mesh that services in the mesh can access.

Configuring a service entry can be enough to call an external service, but
typically you configure either, or both, a virtual service or destination rule
to control traffic in a more granular way. You can configure traffic for a
service entry in the same way you configure traffic for a service in the mesh.

### Secure the connection with mutual TLS

The following destination rule configures the traffic route to use mutual TLS
to secure the connection to the `ext-resource` external service we
configured using the service entry:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ext-res-dr
spec:
  host: ext-resource.com
  trafficPolicy:
    tls:
      mode: MUTUAL
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      caCertificates: /etc/certs/rootcacerts.pem
{{< /text >}}

Together, the `svc-entry` service entry and the `ext-res-dr` destination rule
configure a connection for traffic to the `ext-resource` external
dependency using port 443 and mutual TLS.

See the [service entries reference documentation](/docs/reference/config/networking/v1alpha3/service-entry)
to review all the enabled keys and values.

## Sidecars

By default, Istio configures every Envoy proxy to accept traffic on all the
ports of its associated workload, and to reach every workload in the mesh when
forwarding traffic. You can use a sidecar configuration to do the following:

- Fine-tune the set of ports and protocols that an Envoy proxy accepts.

- Limit the set of services that the Envoy proxy can reach.

Limiting sidecar reachability reduces memory usage, which can become a problem
for large applications in which every sidecar is configured to reach every
other service in the mesh.

A [Sidecar](/docs/reference/config/networking/v1alpha3/sidecar/) resource can be used to configure one or more sidecar proxies
selected using workload labels, or to configure all sidecars in a particular
namespace.

### Enable namespace isolation

For example, the following `Sidecar` configures all services in the `bookinfo`
namespace to only reach services running in the same namespace thanks to the
`./*` value of the `hosts:` field:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
  namespace: bookinfo
spec:
  egress:
  - hosts:
    - "./*"
{{< /text >}}

Sidecars have many uses. Refer to the [sidecar reference](/docs/reference/config/networking/v1alpha3/sidecar/)
for details.

## Network resilience and testing

Istio provides opt-in failure recovery features that you can configure
dynamically at runtime through the [Istio traffic management rules](/docs/concepts/traffic-management/#routing-rules).
With these features, the service mesh can tolerate failing nodes and Istio can
prevent localized failures from cascading to other nodes:

- **Timeouts and retries**

    A timeout is the amount of time that Istio waits for a response to a
    request. A retry is an attempt to complete an operation multiple times if
    it fails. You can set defaults and specify request-level overrides for both
    timeouts and retries or for one or the other.

- **Circuit breakers**

    Circuit breakers prevent your application from stalling as it waits for an
    upstream service to respond. You can configure a circuit breaker based on a
    number of conditions, such as connection and request limits.

- **Fault injection**

    Fault injection is a testing method that introduces errors into a system to
    ensure that it can withstand and recover from error conditions. You can
    inject faults at the application layer, rather than the network layer, to
    get more relevant results.

- **Fault tolerance**

    You can use Istio failure recovery features to complement application-level
    fault tolerance libraries in situations where their behaviors don’t
    conflict.

{{< warning >}}
While Istio failure recovery features improve the reliability and availability
of services in the mesh, applications must handle the failure or errors and
take appropriate fallback actions. For example, when all instances in a load
balancing pool have failed, Envoy returns an `HTTP 503` code. The application
must implement any fallback logic needed to handle the `HTTP 503` error code
from an upstream service.
{{< /warning >}}

## Timeouts and retries

You can use Istio's traffic management resources to set defaults for timeouts
and retries per service and subset that apply to all callers.

### Override default timeout setting

The default timeout for HTTP requests is 15 seconds. You can configure a
virtual service with a routing rule to override the default, for example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    timeout: 10s
{{< /text >}}

### Set number and timeouts for retries

You can specify the maximum number of retries for an HTTP request in a virtual
service, and you can provide specific timeouts for the retries to ensure that
the calling service gets a response, either success or failure, within a
predictable time frame.

Envoy proxies automatically add variable jitter between your retries to
minimize the potential impact of retries on an overloaded upstream service.

The following virtual service configures three attempts with a 2-second
timeout:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
    retries:
      attempts: 3
      perTryTimeout: 2s
{{< /text >}}

Consumers of a service can also override timeout and retry defaults with
request-level overrides through special HTTP headers. The Envoy proxy
implementation makes the following headers available:

- Timeouts: `x-envoy-upstream-rq-timeout-ms`

- Retries: `X-envoy-max-retries`

## Circuit breakers

As with timeouts and retries, you can configure a circuit breaker pattern
without changing your services. While retries let your application recover from
transient errors, a circuit breaker pattern prevents your application from
stalling as it waits for an upstream service to respond. By configuring a
circuit breaker pattern, you allow your application to fail fast and handle the
error appropriately, for example, by triggering an alert. You can configure a
simple circuit breaker pattern based on a number of conditions such as
connection and request limits.

### Limit connections to 100

The following destination rule sets a limit of 100 connections for the
`reviews` service workloads of the v1 subset:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
{{< /text >}}

See the [circuit-breaking task](/docs/tasks/traffic-management/circuit-breaking/)
for detailed instructions on how to configure a circuit breaker pattern.

## Fault injection

You can use fault injection to test the end-to-end failure recovery capability
of the application as a whole. An incorrect configuration of the failure
recovery policies could result in unavailability of critical services. Examples
of incorrect configurations include incompatible or restrictive timeouts across
service calls.

With Istio, you can use application-layer fault injection instead of killing
pods, delaying packets, or corrupting packets at the TCP layer. You can inject
more relevant failures at the application layer, such as HTTP error codes, to
test the resilience of an application.

You can inject faults into requests that match specific conditions, and you can
restrict the percentage of requests Istio subjects to faults.

You can inject two types of faults:

- **Delays:** Delays are timing failures. They mimic increased network latency
   or an overloaded upstream service.

- **Aborts:** Aborts are crash failures. They mimic failures in upstream
   services. Aborts usually manifest in the form of HTTP error codes or TCP
   connection failures.

You can configure a virtual service to inject one or more faults while
forwarding HTTP requests to the rule's corresponding request destination. The
faults can be either delays or aborts.

### Introduce a 5 second delay in 10% of requests

You can configure a virtual service to introduce a 5 second delay for 10% of
the requests to the `ratings` service.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

### Return an HTTP 400 error code for 10% of requests

You can configure an abort instead to terminate a request and simulate a
failure.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      abort:
        percentage:
          value: 0.1
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

### Combine delay and abort faults

You can use delay and abort faults together. The following configuration
introduces a delay of 5 seconds for all requests from the `v2` subset of the
`reviews` service to the `v1` subset of the `ratings` service and an abort for
10% of them:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    fault:
      delay:
        fixedDelay: 5s
      abort:
        percentage:
          value: 0.1
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

For detailed instructions on how to configure delays and aborts, visit our
[fault injection task](/docs/tasks/traffic-management/fault-injection/).

## Compatibility with application-level fault handling

Istio failure recovery features are completely transparent to the application.
Applications don't know if an Envoy sidecar proxy is handling
failures for a called upstream service, before returning a response.

When you use application-level fault tolerance libraries and Envoy proxy
failure recovery policies at the same time, you need to keep in mind that
both work independently, and therefore might conflict.

For example: Suppose you can have two timeouts, one configured in a virtual
service and another in the application. The application sets a
2 second timeout for an API call to a service. However, you configured a
3 second timeout with 1 retry in your virtual service. In this case,
the application's timeout kicks in first, so your Envoy timeout and retry
attempt has no affect.
