---
title: Destination Rules
description: Describes the architecture and behavior of destination rules and how Istio enforces them.
weight: 4
keywords: [destination, request, route, policy, subset, destination rule, TLS, evaluation, failure handling, fault injection, traffic routing, gateway]
---

A [destination rule](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule)
configures the set of policies **Pilot** applies to a request **after** the
[virtual service](../virtual-services) routing.

Service owners typically author destination rules to configure, among other
things:

- [Circuit breakers](../failures/#circuit)
- TLS settings
- Outlier detection
- [Load balancer](../load-balancing) settings
- Definition of [subsets](../traffic-routing) of destination hosts in the mesh

Use wild card prefixes in a destination rule to specify a single rule for
multiple services. Istio uses the defined subsets of the destination hosts in
the virtual services  `route:` specification to send traffic to specific
versions of the service. This naming of versions allows you to:

-  Cleanly refer to a specific service version across different virtual
   services.
-  Simplify the stats that the Istio proxies emit.
-  Encode subsets in SNI headers.

The following example destination rule configures three different subsets with
different load balancing policies for the `vtl-svc` virtual service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-vtl-svc
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

Notice the multiple `trafficPolicy` entries. You can specify multiple policies
in a single `DestinationRule` configuration file. In this example, the default
policy is defined above the `subsets:` key and the `v2` specific policy withing
the appropriate subset.

The following diagram shows how the different configurations in the
`my-destination-rule` destination rule affect the traffic to and from the
`my-vtl-svc` virtual service:

{{< image width="50%"
    link="./destination-rule.svg"
    caption="Configurable route examples defined in the destination rule"
    >}}

Visit our [destination rules reference documentation](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule)
to review all the enabled keys and values.

## Destination rules routing evaluation

Similar to route rules in virtual services, **Pilot** associates policies
defined in a destination rule with a particular `host:` service. If the
policies are subset specific, the activation depends on the route rule
evaluation results.

The rule evaluation process is as follows:

1. **Pilot** evaluates if the route rules in the virtual service configuration
   files correspond to the requested `host:`.

1. **Pilot** determines if there are any rules defining a specific subset of
   the destination service to route the current request to the specific subset
   workload.

1. **Pilot** evaluates the set of policies and route rules in the destination
   rules corresponding to the selected subset, if any, to determine if they
   apply.

1. **Pilot** routes the request to the specific version of the service defined
   by the subset following the configured routing rules in the destination
   rules.

> {{< idea_icon >}} Pilot only applies policies defined for specific subsets if
> there is an explicit route to the corresponding subset.

### Rule evaluation considerations

Consider the following configuration as the one and only rule defined for the
`reviews` service. There are no route rules in the corresponding `VirtualService` definition only the following destination rule:

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

Without a specific route rule defined for the `reviews` service, **Pilot**
applies the default round-robin routing behavior and calls instances in the
`v1` subset on occasion. **Pilot** always calls instances in the `v1` subset if
they are the only running version.

**Pilot** never invokes the policy above since the default routing is done at a
lower level. The rule evaluation engine is unaware of the final destination and
therefore unable to match the subset policy to the request.

You can fix the example in one of two ways:

- You can move the traffic policy up a level in the `DestinationRule`
  configuration file to make it apply to any version:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: reviews
    spec:
      host: reviews
      trafficPolicy:
        connectionPool:
          tcp:
            maxConnections: 100
      subsets:
      - name: v1
        labels:
          version: v1
    {{< /text >}}

- Define the proper route rules for the service in a virtual service
  configuration file. To fix our example, add a simple route rule for the
  `reviews` host in the `v1` subset:

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
    {{< /text >}}

Istio's default behavior conveniently sends traffic from any source to all
versions of a destination service when no rules are set. As soon as you desire
version discrimination, you must define destination rules.

The best practice in Istio is to set a default rule for every service, right
from the start to avoid this type of issues.
