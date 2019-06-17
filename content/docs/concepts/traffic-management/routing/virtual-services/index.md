---
title: Virtual Services
description: Learn about using a virtual service to configure an ordered list of routing rules to control how Envoy proxies route requests for a service within an Istio service mesh.
weight: 1
keywords: [traffic-management, virtual-service, routing-rule, precedence, match-condition]
---

A [virtual service](/docs/reference/config/networking/v1alpha3/virtual-service/)
is a network resource you can use to configure how Envoy proxies route requests
to a service within an Istio service mesh. Virtual services let you finely
configure traffic behavior. For example, you can use virtual services to direct
HTTP traffic to use a different version of the service for a specific user.

Istio and your platform provide basic connectivity and discovery for your
services. With virtual services, you can add a configuration layer to set up
complex traffic routing. You can map user-addressable destinations to real
workloads in the mesh, for example. Or, you can configure more advanced traffic
routes:

-  To specific services or subsets in the mesh.

-  To other network resources in the mesh.

Your mesh can require multiple virtual services or none depending on your use
case. You can add [gateways](/docs/concepts/traffic-management/routing/gateways/)
to route traffic in or out of your mesh, or combine virtual services with
[destination rules](/docs/concepts/traffic-management/routing/destination-rules/)
to configure the behavior of the traffic. You can use a [service entry](/docs/concepts/traffic-management/routing/service-entries/)
to add external dependencies to the mesh and combine them with virtual services
to configure the traffic to and from these dependencies. The following diagrams
show some example virtual service configurations:

-  1:1 relationship: Virtual service A configures routing rules for traffic to
   reach service X.

   {{< image width="40%"
    link="./virtual-services-1.svg"
    caption="1 : 1 relationship"
    >}}

-  1:many relationship:

    -  Virtual service B configures routing rules for traffic to reach services
      Y and Z.

       {{< image width="40%"
        link="./virtual-services-2.svg"
        caption="1 : multiple services"
        >}}

    -  Virtual service C configures routing rules for traffic to reach different
      versions of service W.

         {{< image width="40%"
          link="./virtual-services-3.svg"
          caption="1 : multiple versions"
          >}}

You can use virtual services to perform the following types of tasks:

-  Add [multiple match conditions](/docs/concepts/traffic-management/routing/virtual-services/#multi-match)
   to a virtual service configuration to eliminate redundant rules.

-  Configure each application service version as a
   [subset](/docs/concepts/traffic-management/routing/destination-rules/#service-subsets) and add
   a corresponding [destination
   rule](/docs/concepts/traffic-management/routing/destination-rules/) to
   determine the set of pods or VMs belonging to these subsets.

-  Configure traffic rules to provide [load balancing](/docs/concepts/traffic-management/overview/#load-balancing)
   for ingress and egress traffic in combination with
   [gateways](/docs/concepts/traffic-management/routing/gateways/).

-  Configure [traffic routes](/docs/concepts/traffic-management/routing/virtual-services/#routing-subset)
   to your application services using DNS names. These DNS names support
   wildcard prefixes or CIDR prefixes to create a single rule for all matching
   services.

-  Address one or more application services through a single virtual service.
   If your mesh uses Kubernetes, for example, you can configure a virtual
   service to handle all services in a specific
   [namespace](/docs/concepts/traffic-management/routing/virtual-services/#routing-namespace).

## Route requests to a subset {#routing-subset}

The following example configures the  `my-vtl-svc` virtual service to route
requests to the `v1` subset of the `my-svc` service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-vtl-svc
spec:
  hosts:
    - *.my-co.org
    http:
      - route:
        - destination:
            host: my-svc
            subset: v1
{{< /text >}}

In the example, note that under `spec,` which lists the specifications of the
network resource, `hosts` lists the virtual service's hosts. In this case, the
hosts are `*.my-co.org`, where `*` is a wildcard prefix indicating that this
virtual service handles routing for any DNS name ending with `.my-co.org`.

You can specify user-addressable hosts by using any DNS name or an internal
mesh service name as long as the name resolves, implicitly or explicitly, to
one or more fully qualified domain names (FQDN). To specify multiple hosts, you
can use wildcards.

Also, note that under `route:`, which specifies the routing rule's
configuration, and `destination:`, which specifies the routing rule's
destination, `host: my-svc` specifies the destination's host. If you are
running on Kubernetes, then `my-svc` is the name of a Kubernetes service.

You use the destination's host to specify where you want the traffic to be
sent. The destination's host must exist in the service registry. To use
external services as destinations, use [service entries](/docs/concepts/traffic-management/routing/service-entries/)
to add those services to the registry.

{{< warning >}}
Istio **doesn't** provide DNS resolution. Applications can try
to resolve the FQDN by using the DNS service present in their platform of
choice, for example `kube-dns`.
{{< /warning >}}

The following diagram shows the configured rule:

{{< image width="40%"
  link="./virtual-services-4.svg"
  caption="Configurable traffic route to send traffic to a specific subset"
    >}}

## Route requests to services in a Kubernetes namespace {#routing-namespace}

The following example shows a virtual service configuration with traffic routes
for two services in the `my-namespace.svc.cluster.local` Kubernetes namespace.
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

The following diagram shows the configured rule:

{{< image width="40%"
    link="./virtual-services-5.svg"
    caption="Configurable traffic route based on the namespace of two application services"
    >}}

## Routing rules

A virtual service consists of an ordered list of routing rules to define the
paths that requests follow within the mesh. You use virtual services to
configure the routing rules. A routing rule consists of a destination and zero
or more conditions, depending on your use case. You can also use routing rules
to perform some actions on the traffic, for example:

- Append or remove headers.

- Rewrite the URL.

- Set a retry policy.

To learn more about the actions available, visit the [virtual service reference documentation](/docs/reference/config/networking/v1alpha3/virtual-service/#HTTPRoute).

### Routing rule for HTTP traffic

The following example shows a virtual service that specifies a specific routing
rule for HTTP traffic in the `http:` section. The rule includes a `match:`
condition with a regular expression to check if the username "jason" is in the
request's cookie. If the request matches this condition, the routing rule sends
traffic to the `v2` subset of the `my-svc` service. Otherwise, the routing rule
sends traffic to the `v1` subset of the `my-svc` service.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-vtl-svc
spec:
  hosts:
    -*
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

In the preceding example, there are two routing rules. The configuration of the
first routing rule in the virtual service begins with the `http:` field:

-  `http:` Specifies the type of traffic that follows the the routing rule. In
   this case, the routing rule applies to HTTP traffic.

-  `- match:` Lists the routing rule's matching conditions.

-  `- headers:` Specifies to look for a match in the header of the request.

-  `cookie:` Specifies to look for a match in the header's cookie.

-  `regex:` Specifies the regular expression used to determine a match.

-  `route:` Specifies the routing rule's configurations for the traffic
   matching the condition. In this case, that traffic is HTTP traffic with the
   username `jason` in the cookie of the request's header.

-  `- destination:` Specifies the destination for the traffic matching the
   conditions.

-  `host: my-svc` Specifies the destination's host.

-  `subset: v2` Specifies the destination’s subset for the traffic matching the conditions.

The configuration of the second routing rule in the example begins with the `-
route:` field. This rule applies to all traffic that doesn't match the
conditions specified in the first routing rule.

-  `- route:` Specifies the routing rule's configurations for all traffic
   except for HTTP traffic matching the condition of the previous rule.

-  `- destination:` Specifies the routing rule's destination.

-  `host: my-svc` Specifies the destination's host.

-  `subset: v1`  Specifies the destination’s subset.

The following diagram shows the configured traffic routes for the matched traffic and for all other traffic:

{{< image width="40%"
    link="./virtual-services-6.svg"
    caption="Configurable traffic route based on the namespace of two application services"
    >}}

Configurable traffic rules for traffic with and without a matched cookie

Routing rules are evaluated in a specific order. For details, refer to
[Precedence](/docs/concepts/traffic-management/routing/virtual-services/#precedence).

### Match a condition

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
    …
{{< /text >}}

The value of the `sourceLabels:` key depends on the implementation of the
service. In Kubernetes, the value corresponds to the same labels you use in the
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

### Conditions based on HTTP headers

You can also base conditions on HTTP headers. The following configuration sets
up a rule that only applies to an incoming request that includes a custom
`end-user:` header containing the exact `jason` string:

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

### Match request URI

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

### Multiple match conditions {#multi-match}

Conditions can have multiple matches simultaneously. In such cases, you use the
nesting of the conditions in the routing rule to specify whether AND or OR
semantics apply. To specify AND semantics, you nest multiple conditions in a
single section of `match.`

For example, the following rule applies only to requests that come from an
instance of the `reviews` service in the `v2` subset AND only if the requests
include the custom `end-user:` header that contains the exact `jason` string:

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

## Routing rule precedence {#precedence}

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

### Precedence example with 2 rules

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

