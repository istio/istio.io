---
title: Routing Rules
description: Describes the behavior of routing rules in Istio for all configuration objects.
weight: 3
keywords: [routing,request, traffic routing, requests routing, virtual service, condition matching, precedence, match]
aliases:
---

This concept describes how Istio handles routing rules. Istio's simple
configuration model allows you to control how API calls and layer-4 traffic can
flow across the various services in your application deployment.

Specifically, the model allows you to configure service-level properties:

- [Circuit breakers](../failures/#circuit)

- [Timeouts](../failures/#timeouts)

- [Retries](../failures/#retries)

You can also set up common continuous deployment tasks such as:

- [Canary rollouts](../traffic-routing/#canary)

- Staged rollouts with percentage-based [traffic splitting](../traffic-routing/#splitting)

The behaviors described in the following sections apply to all routing rules
regardless of the configuration object where you configure them. If you use the
examples provided, you must adapt them to your application and apply the
configuration in the appropriate configuration object. For simplicity, all
examples use [virtual services](../virtual-services).

## Rule destinations

Routing rules destinations correspond to one or more request destination hosts
specified in a virtual service configuration file.

{{< warning_icon >}} These hosts are not necessarily the same as the actual
destination workloads. Additionally, these hosts do not even necessarily
correspond to an actual routable service in the mesh.

For example, to configure routing rules for requests to the `reviews` service
using its internal mesh name `reviews` or via its `bookinfo.com` host, you can
configure a virtual service with the `hosts:` key as follows:

{{< text yaml >}}
hosts:
  - reviews
  - bookinfo.com
{{< /text >}}

The `hosts:` key specifies, implicitly or explicitly, one or more fully
qualified domain names (FQDN).

The short name `reviews`, can implicitly expand to an implementation specific
FQDN. In a Kubernetes environment, the full name is derived from the cluster
and namespace of the virtual service, for example,
`reviews.default.svc.cluster.local`.

## Precedence

When there are multiple rules for a given destination, they are evaluated in
the order they appear in the virtual service. The first rule on the list has
the highest priority.

### Why is precedence important?

Whenever the routing story of a particular service is purely weight based, you can specify it in a single rule.

When you use other conditions to route traffic, such as requests from a
specific user, you need more than one rule to specify the routing. These cases
require careful consideration of priorities to ensure **Pilot** evaluates the
rules in the right order.

A common pattern for generalized route specification is:

1. Provide one or more higher priority rules that match the various conditions.

1. Provide a single weight-based rule with no match condition last to provide
   the weighted distribution of traffic for all other cases.

The following virtual service contains two rules to specify that **Pilot**
sends all requests for the `reviews` service including the `Foo` header with
the `bar` value to the instances in the `v2` subset and send all remaining
requests to the instances in the `v1` subset:

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

The header-based rule has the higher priority because it comes first in the
configuration file. If the header-based rule was lower, these rules wouldn't
work as expected. **Pilot** would evaluate the weight-based rule first in that
case and route all traffic to the instances in the `v1` subset, even requests
including the matching `Foo` header.

Once **Pilot** finds a rule that applies to the incoming request, the rule is
executed and the rule-evaluation process terminates.

{{< warning_icon >}} Consider the priorities of each rule in a configuration file when there is more than one.

## Multiple match conditions {#multi-condition}

You can set multiple match conditions simultaneously. In such a case, `AND` or
`OR` semantics apply, depending on the nesting.

Multiple conditions nested in a single match clause are `ANDed`. For example,
the following rule only applies if the client workload of the request is the
`reviews` service in the `v2` subset **AND** the request has a custom
`end-user` header containing the exact string `jason`:

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

Multiple conditions in separate match keys are `ORed`. Only one
of the conditions applies, for example:

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

This rule applies if the client workload of the request is the `reviews`
service in the `v2` subset **OR** the request has a custom `end-user` header
containing the exact string `jason`.

{{< warning_icon >}} The difference between **AND** behavior and **OR**
behavior is a single dash in the configuration file.

## Conditional rules {#conditional}

You can set rules that only apply to requests matching some specific condition,
for example:

1. **Restrict traffic to specific client workloads using labels:** For example,
   a rule can apply only to calls from workloads implementing the `reviews`
   service:

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

    The value of the `sourceLabels:` key depends on the implementation of the
    service. In Kubernetes, the value corresponds to the same labels you use in
    the pod selector of the corresponding Kubernetes service.

    You can refine the example above further apply only to calls from a
    workload instance in the `v2` subset:

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

1. **Select rule based on HTTP headers:** For example, **Pilot** only applies
   the following rule to an incoming request including a custom `end-user`
   header containing the exact string `jason`:

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

    If you specify more than one header in the rule, then all of the
    corresponding headers must match for the rule to apply.

1. **Select rule based on request URI:** For example, **Pilot** only applies
   the following rule to a request if the URI path starts with `/api/v1`:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: productpage
    spec:
      hosts:
        + productpage
      http:
      + match:
        + uri:
            prefix: /api/v1
        route:
        ...
    {{< /text >}}
