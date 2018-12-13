---
title: What is Istio?
description: Introduces Istio, the problems it solves, its high-level architecture and design goals.
weight: 15
aliases:
    - /docs/concepts/what-is-istio/overview
    - /docs/concepts/what-is-istio/goals
    - /about/intro
---

Cloud platforms provide a wealth of benefits for the organizations that use them. There’s no denying, however, that adopting the cloud can put strains on DevOps
teams. Developers must use microservices to architect for portability, meanwhile operators are managing extremely large hybrid and multi-cloud deployments.
Istio lets you connect, secure, control, and observe services.

At a high level, Istio helps reduce the complexity of these deployments, and eases the strain on your development teams. It is a completely open source service
mesh that layers transparently onto existing distributed applications. It is also a platform, including APIs that let it integrate into any logging platform, or
telemetry or policy system. Istio’s diverse feature set lets you successfully, and efficiently, run a distributed microservice architecture, and provides a
uniform way to secure, connect, and monitor microservices.

## What is a service mesh?

Istio addresses the challenges developers and operators face as monolithic applications transition towards a distributed microservice architecture. To see how,
it helps to take a more detailed look at Istio’s service mesh.

The term service mesh is used to describe the network of microservices that make up such applications and the interactions between them. As a service mesh grows
 in size and complexity, it can become harder to understand and manage. Its requirements can include discovery, load balancing, failure recovery, metrics, and
 monitoring. A service mesh also often has more complex operational requirements, like A/B testing, canary releases, rate limiting, access control, and
 end-to-end authentication.

Istio provides behavioral insights and operational control over the service mesh as a whole, offering a complete solution to satisfy the diverse requirements of
 microservice applications.

## Why use Istio?

Istio makes it easy to create a network of deployed services with load balancing, service-to-service authentication, monitoring, and more, with [few](/docs/tasks/telemetry/distributed-tracing/#understanding-what-happened) or no code changes
in service code. You add Istio support to services by deploying a special sidecar proxy throughout your environment that intercepts all network communication
between microservices, then configure and manage Istio using its control plane functionality, which includes:

* Automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic.

* Fine-grained control of traffic behavior with rich routing rules, retries, failovers, and fault injection.

* A pluggable policy layer and configuration API supporting access controls, rate limits and quotas.

* Automatic metrics, logs, and traces for all traffic within a cluster, including cluster ingress and egress.

* Secure service-to-service communication in a cluster with strong identity-based authentication and authorization.

Istio is designed for extensibility and meets diverse deployment needs.

## Core features

Istio provides a number of key capabilities uniformly across a network of
services:

### Traffic management

Istio’s easy rules configuration and traffic routing lets you control the flow of traffic and API calls between services. Istio simplifies configuration of
service-level properties like circuit breakers, timeouts, and retries, and makes it a breeze to set up important tasks like A/B testing, canary rollouts, and
staged rollouts with percentage-based traffic splits.

With better visibility into your traffic, and out-of-box failure recovery features, you can catch issues before they cause problems, making calls more reliable,
and your network more robust -- no matter what conditions you face.

### Security

Istio’s security capabilities free developers to focus on security at the application level. Istio provides the underlying secure communication channel, and
manages authentication, authorization, and encryption of service communication at scale. With Istio, service communications are secured by default,
letting you enforce policies consistently across diverse protocols and runtimes -- all with little or no application changes.

While Istio is platform independent, using it with Kubernetes (or infrastructure) network policies, the benefits are even greater, including the ability to
secure pod-to-pod or service-to-service communication at the network and application layers.

### Observability

Istio’s robust tracing, monitoring, and logging give you deep insights into your service mesh deployment. Gain a real understanding of how service performance
impacts things upstream and downstream with Istio’s monitoring features, while its custom dashboards provide visibility into the performance of all your
services and let you see how that performance is affecting your other processes.

Istio’s Mixer component is responsible for policy controls and telemetry collection. It provides backend abstraction and intermediation, insulating the rest of
Istio from the implementation details of individual infrastructure backends, and giving operators fine-grained control over all interactions between the mesh
and infrastructure backends.

All these features let you more effectively set, monitor, and enforce SLOs on services. Of course, the bottom line is that you can detect and fix issues quickly
and efficiently.

### Platform support

Istio is platform-independent and designed to run in a variety of environments, including those spanning Cloud, on-premise, Kubernetes, Mesos, and more. You can
 deploy Istio on Kubernetes, or on Nomad with Consul. Istio currently supports:

* Service deployment on Kubernetes

* Services registered with Consul

* Services running on individual virtual machines

### Integration and customization

The policy enforcement component of Istio can be extended and customized to integrate with existing solutions for ACLs, logging, monitoring, quotas, auditing,
and more.

## Architecture

An Istio service mesh is logically split into a **data plane** and a **control
plane**.

* The **data plane** is composed of a set of intelligent proxies
  ([Envoy](https://www.envoyproxy.io/)) deployed as sidecars. These proxies
  mediate and control all network communication between microservices along
  with [Mixer](/docs/concepts/policies-and-telemetry/), a general-purpose
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

### Envoy

Istio uses an extended version of the
[Envoy](https://envoyproxy.github.io/envoy/) proxy. Envoy is a high-performance
proxy developed in C++ to mediate all inbound and outbound traffic for all
services in the service mesh. Istio leverages Envoy’s many built-in features,
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

Envoy is deployed as a **sidecar** to the relevant service in the same
Kubernetes pod. This deployment allows Istio to extract a wealth of signals
about traffic behavior as
[attributes](/docs/concepts/policies-and-telemetry/#attributes). Istio can, in
turn, use these attributes in [Mixer](/docs/concepts/policies-and-telemetry/)
to enforce policy decisions, and send them to monitoring systems to provide
information about the behavior of the entire mesh.

The sidecar proxy model also allows you to add Istio capabilities to an
existing deployment with no need to rearchitect or rewrite code. You can read
more about why we chose this approach in our [Design
Goals](/docs/concepts/what-is-istio/#design-goals).

### Mixer

[Mixer](/docs/concepts/policies-and-telemetry/) is a platform-independent
component. Mixer enforces access control and usage policies across the service
mesh, and collects telemetry data from the Envoy proxy and other services. The
proxy extracts request level
[attributes](/docs/concepts/policies-and-telemetry/#attributes), and sends them
to Mixer for evaluation. You can find more information on this attribute
extraction and policy evaluation in our [Mixer Configuration
documentation](/docs/concepts/policies-and-telemetry/#configuration-model).

Mixer includes a flexible plugin model. This model enables Istio to interface
with a variety of host environments and infrastructure backends. Thus, Istio
abstracts the Envoy proxy and Istio-managed services from these details.

### Pilot

[Pilot](/docs/concepts/traffic-management/#pilot-and-envoy) provides
service discovery for the Envoy sidecars, traffic management capabilities
for intelligent routing (e.g., A/B tests, canary deployments, etc.),
and resiliency (timeouts, retries, circuit breakers, etc.).

Pilot converts high level routing rules that control traffic behavior into
Envoy-specific configurations, and propagates them to the sidecars at runtime.
Pilot abstracts platform-specific service discovery mechanisms and synthesizes
them into a standard format that any sidecar conforming with the [Envoy data
plane APIs](https://github.com/envoyproxy/data-plane-api) can consume. This
loose coupling allows Istio to run on multiple environments such as Kubernetes,
Consul, or Nomad, while maintaining the same operator interface for traffic
management.

### Citadel

[Citadel](/docs/concepts/security/) enables strong service-to-service and
end-user authentication with built-in identity and credential management. You
can use Citadel to upgrade unencrypted traffic in the service mesh. Using
Citadel, operators can enforce policies based on service identity rather than
on relatively unstable layer 3 or layer 4 network identifiers. Starting from
release 0.5, you can use [Istio's authorization feature](/docs/concepts/security/#authorization) 
to control who can access your services.

### Galley

Galley validates user authored Istio API configuration on behalf of
the other Istio control plane components. Over time, Galley will take
over responsibility as the top-level configuration ingestion, processing and
distribution component of Istio. It will be responsible for insulating
the rest of the Istio components from the details of obtaining user
configuration from the underlying platform (e.g. Kubernetes).

## Design Goals

A few key design goals informed Istio’s architecture. These goals are essential
to making the system capable of dealing with services at scale and with high
performance.

* **Maximize Transparency**: To adopt Istio, an operator or developer is
  required to do the minimum amount of work possible to get real value from the
  system. To this end, Istio can automatically inject itself into all the
  network paths between services. Istio uses sidecar proxies to capture traffic
  and, where possible, automatically program the networking layer to route
  traffic through those proxies without any changes to the deployed application
  code. In Kubernetes, the proxies are injected into pods and traffic is
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
