---
title: Overview
description: Describes traffic management in general and introduces the other sections.
weight: 1
keywords: [Pilot, traffic management, traffic, routing, virtual services, service entries, destination rules, gateways]
---

This concept provides an overview on how traffic management works in Istio and
the benefits of Istio's traffic management principles.

To understand this concept, you need the information in the [What is Istio? concept](/docs/concepts/what-is-istio/)
and familiarity with Istio's high-level architecture.

The core component used for traffic management in Istio is [Pilot](../pilot),
which manages and configures all the Envoy proxy instances deployed in a
particular Istio service mesh. The Istio network configuration objects allow
you to configure [traffic routing rules](../routing-rules) to and from services
and to secure the traffic between them. Istio provides
[service discovery and load balancing](../load-balancing) features.

Istio provides other configuration objects for telemetry and monitoring
configuration options. Visit our [policies and telemetry concept](/docs/concepts/policies-and-telemetry/)
to learn more.

The Istio [traffic routing APIs](/docs/reference/config/istio.networking.v1alpha3/)
define four network configuration objects in Istio:

* [Virtual services](../virtual-services)

* [Destination rules](../destination-rules)

* [Service entries](../service-entries)

* [Gateways](../gateways)

> **The diagrams on this concept don't show data plane traffic.** Unless
> otherwise indicated, the arrows in the diagrams portray the configurable
> traffic routing rules. Because of this, the diagrams show the possible
> control plane connections between the Envoy proxies and the configuration
> objects.

The following diagram shows an example overview of the **configurable traffic
routing rules** that the network configuration objects allow for a basic mesh
with two different versions of a service:

{{< image width="60%"
    link="./configuration-overview.svg"
    caption="Istio network configuration objects overview"
    >}}

Istio's traffic management model decouples traffic flow and infrastructure
scaling. You can specify the rules you want traffic to follow via **Pilot**
rather than specifying which pods or VMs should receive traffic. **Pilot** and
intelligent **Envoy** proxies ensure the rules are enforced.

The following example diagram shows how you can specify that 5% of the traffic
for a particular service go to a canary version irrespective of the size of
the canary deployment.

{{< image width="60%"
  link="./percentage-based-steering.svg"
  caption="Traffic splitting is decoupled from the infrastructure scaling: Route a portion of traffic to a specific service version independently of the number of instances supporting said version"
  >}}

The next example shows how you can direct traffic to a particular version
depending on the content of the request.

{{< image width="60%"
link="./content-based-steering.svg"
caption="Content based steering: You can use the content of a request to determine its destination"
>}}

Decoupling the traffic flow from the infrastructure scaling allows Istio
to provide a variety of traffic management features that live outside the
application code:

* [Dynamic request routing](../routing-rules) for A/B testing.

* Gradual [canary rollouts](../traffic-routing/#canary) and releases.

* [Failure recovery](../failures) using [timeouts](../failures/#timeouts),
  [retries](../failures/#retries), and [circuit breakers](../failures/#circuit).

* [Fault injection](../failures/#fault-injection) to test the compatibility
  of failure recovery policies across services.

These capabilities are all realized through the Envoy proxies deployed
across the service mesh.
