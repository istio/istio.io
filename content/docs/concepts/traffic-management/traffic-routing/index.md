---
title: Traffic Routing
description: Describes traffic routing on Istio using service subsets and provides the most common uses.
weight: 8
keywords: [routing, request, traffic routing, requests routing, A/B testing, splitting, circuit breakers, subsets, subset]
aliases:
    - /docs/concepts/traffic-management/pilot
---

As described in [Pilot's architecture](../pilot), Pilot maintains an
`Abstract Model` with the canonical representation of the services in a mesh.
Istio's model of a service is independent of its representation in the
underlying platform: Kubernetes, Mesos, Cloud Foundry, etc. The
platform-specific adapters populate the `Abstract Model` representation with
various fields from the metadata in the platform.

To cover common configuration scenarios, Istio introduces the concept of a
**service subset**, to subdivide service instances by versions, say `v1` and
`v2`, or environment, say `staging` and `prod`. These variants are not
necessarily different API versions: they can be iterative changes to the same
service, deployed in different environments like prod, staging, dev, etc.
Together with Istio's network configuration objects, you can use subsets to
configure [routing rules](routing-rules.md) that refer to service versions to
provide additional control over the traffic between services.

This concept covers the common configuration scenarios for services subsets,
like:

- [Canary rollout](#canary)
- [Splitting traffic between versions](#splitting) for A/B testing
- [Circuit breakers](../failures/#circuit)

## Communication between services

Clients calling a service have no knowledge of the different versions of the
service. Clients access the services using the hostname or IP address of the
service. The Envoy proxy intercepts and forwards all requests and responses
between the client and the service. The following diagram shows a possible
configuration for a service with multiple versions.

{{< image width="60%"
    link="./service-versions.svg"
    alt="Showing how service versions are handled."
    caption="Handling of service versions with subsets"
    >}}

Envoy determines the service version dynamically based on the [routing rules](../routing-rules).
You specify the routing rules using the [network configuration objects](../pilot/#net-objects)
defined in the Istio [traffic routing APIs](/docs/reference/config/istio.networking.v1alpha3/).

This model decouples the application code from the evolution
of its dependent services. The model provides other benefits in terms of
monitoring and telemetry. To learn more about these benefits, visit our
[Mixer policies and telemetry concept](/docs/concepts/policies-and-telemetry/).

The routing rules allow Envoy to select a version [based on conditions](../routing-rules/#conditional),
for example:

- Headers

- Tags associated with source or destination

- By weights assigned to each version

Istio provides load balancing for traffic to multiple instances of the same
service version. To learn more about load balancing, visit our [Discovery and Load Balancing concept](../load-balancing).

> {{< warning_icon >}} Istio **does not** provide a DNS. Applications can try
> to resolve the FQDN using the DNS service present in their platform of
> choice: `kube-dns`, `mesos-dns`, etc.

## Canary rollout {#canary}

Use a canary rollout to introduce a new version of a service while testing it
using a small percentage of user traffic. If the test is successful, you can
gradually increase the percentage until all the traffic is moved to the new
version. If anything goes wrong along the way, you can abort the rollout and
return the traffic to the old version.

Although container orchestration platforms like Docker, Mesos, Marathon, or
Kubernetes provide features that support canary rollout, they use instance
scaling to manage the traffic distribution, which limits them.

For example, to send 10% of traffic to a canary version requires 9 instances of
the old version to be running for every 1 instance of the canary. This becomes
particularly difficult in production deployments where autoscaling is needed.
When traffic load increases, the autoscaler needs to scale instances of both
versions concurrently, making sure to keep the instance ratio the same.

Additionally, the instance deployment approach only supports a simple, random
percentage, canary rollout. You can't limit the visibility of the canary to
requests based on some specific criteria.

With Istio, traffic routing and instance deployment are completely independent
functions. The number of instances implementing the services can scale up and
down based on traffic load completely orthogonal to the version traffic
routing. This model makes managing a canary version in the presence of
autoscaling a much simpler problem. To learn more about canary deployments
and the interoperability of canary deployments and autoscaling when using
Istio visit our blog post on [Canary Deployments](/blog/2017/0.1-canary/).

## Splitting traffic between versions {#splitting}

Each route rule identifies one or more weighted workloads to call when the rule
is activated. Each workload corresponds to a specific version of the
destination service. You use subsets to express the versions. If there are
multiple registered instances with the specified subset, **Pilot** routes them
based on the load balancing policy configured for the service or using
round-robin by default.

For example, the following rule routes 25% of traffic for the `reviews` service
to instances with the `v2` subset and the remaining 75% of traffic to `v1`:

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

To learn more about configuring destination rules, visit our [Destination Rules concept](../destination-rules).

