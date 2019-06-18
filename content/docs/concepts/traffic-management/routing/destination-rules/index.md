---
title: Destination Rules
description: Learn about using destination rules to configure the policies you want Istio to apply to a request after enforcing the routing rules in your virtual service.
weight: 2
keywords: [traffic-management, destination-rule, service-subset, load-balancing]
---

You specify the path for traffic with routing rules, and then you use
[destination rules](/docs/reference/config/networking/v1alpha3/destination-rule/) to configure the set of policies that Envoy proxies apply
to a request at a specific destination. Destination rules are applied after the
routing rules are evaluated.

Configurations you set in destination rules apply to traffic that you route
through your platform's basic connectivity. You can use wildcard prefixes in a
destination rule to specify a single rule for multiple services.

You can use destination rules to specify service subsets, that is, to group all
the instances of your service with a particular version together. You then
configure [routing rules](/docs/concepts/traffic-management/routing/virtual-services/#routing-rules)
that route traffic to your subsets to send certain traffic to particular
service versions.

You specify explicit routing rules to service subsets. This model allows you
to:

- Cleanly refer to a specific service version across different [virtual services](/docs/concepts/traffic-management/routing/virtual-services/).

- Simplify the stats that the Istio proxies emit.

- Encode subsets in Server Name Indication (SNI) headers.

## Load balancing 3 subsets

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
In this example, the default policy is defined above the `subsets` field. The
`v2` specific policy is defined in the corresponding subset's field. The
following diagram shows how the different configurations in the
`my-destination-rule` destination rule and in the routing rules in `my-vtl-svc`
virtual service would apply to the traffic to and from the `my-svc` service:

{{< image width="40%"
    link="./destination-rules-1.svg"
    caption="Configurable route examples defined in the destination rule"
    >}}

Visit our [destination rules reference documentation](/docs/reference/config/networking/v1alpha3/destination-rule/) to review all the enabled keys and values.

## Service subsets

Service subsets subdivide and label the instances of a service. To define the
divisions and labels, use the `subsets` section in [destination rules](/docs/reference/config/networking/v1alpha3/destination-rule/).
For example, you can use subsets to configure the following traffic routing
scenarios:

- Use subsets to [route traffic to different versions of a service](/docs/concepts/traffic-management/routing/virtual-services/#routing-subset).

- Use subsets to route traffic to the same service in different environments.

You use service subsets in the routing rules of [virtual services](/docs/concepts/traffic-management/routing/virtual-services/),
[gateways](/docs/concepts/traffic-management/routing/gateways/)
and [service entries](/docs/concepts/traffic-management/routing/service-entries/)
to control the traffic to your services.

Understanding service subsets in Istio allows you to configure the
communication to services with multiple versions within your mesh and configure
the following common use cases:

- [Canary rollout](/docs/concepts/traffic-management/routing/#canary)

- [Splitting traffic between versions for A/B testing](/docs/concepts/traffic-management/routing/#splitting)

To learn how you can use service subsets to configure failure handling use
cases, visit our [Network resilience and testing concept](/docs/concepts/traffic-management/network/).
