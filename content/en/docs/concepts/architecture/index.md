---
title: Architecture
description: Describes Istio's high-level architecture and design goals.
weight: 70
---

An Istio service mesh is logically split into a **data plane** and a **control
plane**.

* The **data plane** is composed of a set of intelligent proxies
  ([Envoy](https://www.envoyproxy.io/)) deployed as sidecars. These proxies
  mediate and control all network communication between microservices along
  with [Mixer](/docs/reference/config/policy-and-telemetry/), a general-purpose
  policy and telemetry hub.

* The **control plane** manages and configures the proxies to route traffic.
  Additionally, the control plane configures Mixers to enforce policies and
  collect telemetry.

The following diagram shows the different components that make up each plane:

{{< image width="80%"
    link="./arch.svg"
    alt="The overall architecture of an Istio-based application."
    caption="Istio Architecture"
    >}}

Traffic in Istio is categorized as data plane traffic and control plane traffic.
Data plane traffic refers to the messages that the business logic of the workloads
send and receive. Control plane traffic refers to configuration and control messages sent
between Istio components to program the behavior of the mesh. Traffic management
in Istio refers exclusively to data plane traffic.

## Components

The following sections provide a brief overview of each of Istio's core components.

### Envoy

Istio uses an extended version of the
[Envoy](https://envoyproxy.github.io/envoy/) proxy. Envoy is a high-performance
proxy developed in C++ to mediate all inbound and outbound traffic for all
services in the service mesh.
Envoy proxies are the only Istio components that interact with data plane
traffic.

Envoy proxies are deployed as sidecars to services, logically
augmenting the services with Envoy’s many built-in features,
for example:

* Dynamic service discovery
* Load balancing
* TLS termination
* HTTP/2 and gRPC proxies
* Circuit breakers
* Health checks
* Staged rollouts with %-based traffic split
* Fault injection
* Rich metrics

This sidecar deployment allows Istio to extract a wealth of signals about traffic behavior as
[attributes](/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes).
Istio can, in turn, use these attributes in [Mixer](/docs/reference/config/policy-and-telemetry/)
to enforce policy decisions, and send them to monitoring systems to provide
information about the behavior of the entire mesh.

The sidecar proxy model also allows you to add Istio capabilities to an
existing deployment with no need to rearchitect or rewrite code. You can read
more about why we chose this approach in our
[Design Goals](#design-goals).

Some of the Istio features and tasks enabled by Envoy proxies include:

* Traffic control features: enforce fine-grained traffic control with rich
  routing rules for HTTP, gRPC, WebSocket, and TCP traffic.

* Network resiliency features: setup retries, failovers, circuit breakers, and
  fault injection.

* Security and authentication features: enforce security policies and enforce
  access control and rate limiting defined through the configuration API.

### Mixer

[Mixer](/docs/reference/config/policy-and-telemetry/) is a platform-independent
component. Mixer enforces access control and usage policies across the service
mesh, and collects telemetry data from the Envoy proxy and other services. The
proxy extracts request level
[attributes](/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes), and sends them
to Mixer for evaluation. You can find more information on this attribute
extraction and policy evaluation in our [Mixer Configuration
documentation](/docs/reference/config/policy-and-telemetry/mixer-overview/#configuration-model).

Mixer includes a flexible plugin model. This model enables Istio to interface
with a variety of host environments and infrastructure backends. Thus, Istio
abstracts the Envoy proxy and Istio-managed services from these details.

### Pilot

Pilot provides
service discovery for the Envoy sidecars, traffic management capabilities
for intelligent routing (e.g., A/B tests, canary rollouts, etc.),
and resiliency (timeouts, retries, circuit breakers, etc.).

Pilot converts high level routing rules that control traffic behavior into
Envoy-specific configurations, and propagates them to the sidecars at runtime.
Pilot abstracts platform-specific service discovery mechanisms and synthesizes
them into a standard format that any sidecar conforming with the
[Envoy API](https://www.envoyproxy.io/docs/envoy/latest/api/api) can consume.

The following diagram shows how the platform adapters and Envoy proxies
interact.

{{< image width="40%" link="./discovery.svg" caption="Service discovery" >}}

1.  The platform starts a new instance of a service which notifies its platform
    adapter.

1.  The platform adapter registers the instance with the Pilot abstract model.

1.  **Pilot** distributes traffic rules and configurations to the Envoy proxies
    to account for the change.

This loose coupling allows Istio to run on multiple environments such as Kubernetes,
Consul, or Nomad, while maintaining the same operator interface for traffic
management.

You can use Istio's
[Traffic Management API](/docs/concepts/traffic-management/#introducing-istio-traffic-management)
to instruct Pilot to refine the Envoy configuration to exercise more granular control
over the traffic in your service mesh.

### Citadel

[Citadel](/docs/concepts/security/) enables strong service-to-service and
end-user authentication with built-in identity and credential management. You
can use Citadel to upgrade unencrypted traffic in the service mesh. Using
Citadel, operators can enforce policies based on service identity rather than
on relatively unstable layer 3 or layer 4 network identifiers. Starting from
release 0.5, you can use [Istio's authorization feature](/docs/concepts/security/#authorization)
to control who can access your services.

### Galley

Galley is Istio's configuration validation, ingestion, processing and
distribution component. It is responsible for insulating
the rest of the Istio components from the details of obtaining user
configuration from the underlying platform (e.g. Kubernetes).

## Design goals

A few key design goals informed Istio’s architecture. These goals are essential
to making the system capable of dealing with services at scale and with high
performance.

* **Maximize Transparency**: To adopt Istio, an operator or developer is
  required to do the minimum amount of work possible to get real value from the
  system. To this end, Istio can automatically inject itself into all the
  network paths between services. Istio uses sidecar proxies to capture traffic
  and, where possible, automatically program the networking layer to route
  traffic through those proxies without any changes to the deployed application
  code. In Kubernetes, the proxies are injected into {{<gloss pod>}}pods{{</gloss>}} and traffic is
  captured by programming ``iptables`` rules. Once the sidecar proxies are
  injected and traffic routing is programmed, Istio can mediate all traffic.
  This principle also applies to performance. When applying Istio to a
  deployment, operators see a minimal increase in resource costs for the
  functionality being provided. Components and APIs must all be designed with
  performance and scale in mind.

* **Extensibility**: As operators and developers become more dependent on the
  functionality that Istio provides, the system must grow with their needs.
  While we continue to add new features, the greatest need is the ability to
  extend the policy system, to integrate with other sources of policy and
  control, and to propagate signals about mesh behavior to other systems for
  analysis. The policy runtime supports a standard extension mechanism for
  plugging in other services. In addition, it allows for the extension of its
  vocabulary to allow policies to be enforced based on new signals that the
  mesh produces.

* **Portability**: The ecosystem in which Istio is used varies along many
  dimensions. Istio must run on any cloud or on-premises environment with
  minimal effort. The task of porting Istio-based services to new environments
  must be trivial. Using Istio, you are able to operate a single service
  deployed into multiple environments. For example, you can deploy on multiple
  clouds for redundancy.

* **Policy Uniformity**: The application of policy to API calls between
  services provides a great deal of control over mesh behavior. However, it can
  be equally important to apply policies to resources which are not necessarily
  expressed at the API level. For example, applying a quota to the amount of
  CPU consumed by an ML training task is more useful than applying a quota to
  the call which initiated the work. To this end, Istio maintains the policy
  system as a distinct service with its own API rather than the policy system
  being baked into the proxy sidecar, allowing services to directly integrate
  with it as needed.
