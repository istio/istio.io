---
title: What is Istio?
description: Introduces Istio, the problems it solves, its high-level architecture and design goals.
weight: 15
aliases:
    - /docs/concepts/what-is-istio/overview
    - /docs/concepts/what-is-istio/goals
    - /about/intro
---

This document introduces Istio: an open platform to connect, manage, and secure microservices.
Istio provides an easy way to create a network of deployed services with load balancing, service-to-service authentication,
monitoring, and more, without requiring any changes in service code. You add Istio support to services by deploying a
special sidecar proxy throughout your environment that intercepts all network communication between microservices, configured
and managed using Istio's control plane functionality.

- Automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic.

- Fine-grained control of traffic behavior with rich routing rules,
retries, failovers, and fault injection.

- A pluggable policy layer and configuration API supporting access controls,
rate limits and quotas.

- Automatic metrics, logs, and traces for all traffic within a cluster,
including cluster ingress and egress.

- Secure service-to-service communication in a cluster with strong
identity-based authentication and authorization.

Istio can be deployed on [Kubernetes](https://kubernetes.io),
[Nomad](https://nomadproject.io) with [Consul](https://www.consul.io/). We
plan to add support for additional platforms such as
[Cloud Foundry](https://www.cloudfoundry.org/),
and [Apache Mesos](https://mesos.apache.org/) in the near future.

## Why use Istio?

Istio addresses many of the challenges faced by developers and operators as monolithic applications transition towards a distributed microservice architecture. The term **service mesh** is often used to describe the network of
microservices that make up such applications and the interactions between them. As a service mesh grows in size and complexity, it can become harder to understand
and manage. Its requirements can include discovery, load balancing, failure recovery, metrics, and monitoring, and often more complex operational requirements
such as A/B testing, canary releases, rate limiting, access control, and end-to-end authentication.

Istio provides a complete solution to satisfy the diverse requirements of microservice applications by providing
behavioral insights and operational control over the service mesh as a whole. It provides a number of key capabilities uniformly across a
network of services:

- **Traffic Management**. Control the flow of traffic and API calls between services, make calls more reliable, and make the network more robust in the face
of adverse conditions.

- **Service Identity and Security**. Provide services in the mesh with a verifiable identity and provide the ability to protect service traffic
as it flows over networks of varying degrees of trustability.

- **Policy Enforcement**. Apply organizational policy to the interaction between services, ensure access policies are enforced and resources are fairly
distributed among consumers. Policy changes are made by configuring the mesh, not by changing application code.

- **Telemetry**. Gain understanding of the dependencies between services and the nature and flow of traffic between them, providing the ability to quickly identify issues.

In addition to these behaviors, Istio is designed for extensibility to meet diverse deployment needs:

- **Platform Support**. Istio is designed to run in a variety of environments including ones that span Cloud, on-premise, Kubernetes, Mesos etc. We’re
initially focused on Kubernetes but are working to support other environments soon.

- **Integration and Customization**. The policy enforcement component can be extended and customized to integrate with existing solutions for
ACLs, logging, monitoring, quotas, auditing and more.

These capabilities greatly decrease the coupling between application code, the underlying platform, and policy. This decreased coupling not only makes
services easier to implement, but also makes it simpler for operators to move application deployments between environments or to new policy schemes.
Applications become inherently more portable as a result.

## Architecture

An Istio service mesh is logically split into a **data plane** and a **control plane**.

- The **data plane** is composed of a set of intelligent
proxies (Envoy) deployed as sidecars that mediate and control all network communication between microservices,
along with a general-purpose policy and telemetry hub (Mixer).

- The **control plane** is responsible for managing and
configuring proxies to route traffic, and configuring Mixers to enforce policies and collect telemetry.

The following diagram shows the different components that make up each plane:

{{< image width="80%" ratio="56.25%"
    link="./arch.svg"
    alt="The overall architecture of an Istio-based application."
    caption="Istio Architecture"
    >}}

### Envoy

Istio uses an extended version of the [Envoy](https://envoyproxy.github.io/envoy/) proxy, a high-performance proxy developed in C++, to mediate all inbound and outbound traffic for all services in the service mesh.
Istio leverages Envoy’s many built-in features such as dynamic service discovery, load balancing, TLS termination, HTTP/2 & gRPC proxying, circuit breakers,
health checks, staged rollouts with %-based traffic split, fault injection, and rich metrics.

Envoy is deployed as a **sidecar** to the relevant service in the same Kubernetes pod. This allows Istio to extract a wealth of signals about traffic behavior as [attributes](/docs/concepts/policies-and-telemetry/#attributes), which in turn it can use in [Mixer](/docs/concepts/policies-and-telemetry/) to enforce policy decisions, and be sent to monitoring systems to provide information about the behavior of the entire mesh. The sidecar proxy model also allows you to add Istio capabilities to an existing deployment with no need to rearchitect or rewrite code. You can read more about why we chose this approach in our [Design Goals](/docs/concepts/what-is-istio/#design-goals).

### Mixer

[Mixer](/docs/concepts/policies-and-telemetry/) is a platform-independent component responsible for enforcing access control and usage policies across the service mesh and collecting telemetry data from the Envoy proxy and other
services. The proxy extracts request level [attributes](/docs/concepts/policies-and-telemetry/#attributes), which are sent to Mixer for evaluation. More information on this attribute extraction and policy
evaluation can be found in [Mixer Configuration](/docs/concepts/policies-and-telemetry/#configuration-model). Mixer includes a flexible plugin model enabling it to interface with a variety of host environments and infrastructure backends, abstracting the Envoy proxy and Istio-managed services from these details.

### Pilot

[Pilot](/docs/concepts/traffic-management/#pilot-and-envoy) provides
service discovery for the Envoy sidecars, traffic management capabilities
for intelligent routing (e.g., A/B tests, canary deployments, etc.),
and resiliency (timeouts, retries, circuit breakers, etc.). It converts
high level routing rules that control traffic behavior into Envoy-specific
configurations, and propagates them to the sidecars at runtime. Pilot
abstracts platform-specific service discovery mechanisms and synthesizes
them into a standard format consumable by any sidecar that conforms to the
[Envoy data plane APIs](https://github.com/envoyproxy/data-plane-api).
This loose coupling allows Istio to run on multiple environments
(e.g., Kubernetes, Consul/Nomad) while maintaining the same operator
interface for traffic management.

### Citadel

[Citadel](/docs/concepts/security/) provides strong service-to-service and end-user authentication, with built-in identity and
credential management. It can be used to upgrade unencrypted traffic in the service mesh, and provides operators the ability to enforce
policy based on service identity rather than network controls. Starting from release 0.5, Istio supports
[role-based access control](/docs/concepts/security/#role-based-access-control-rbac) to control who can access your services.

## Design Goals

Istio’s architecture is informed by a few key design goals that are essential to making the system capable of dealing with services at scale and with high
performance.

- **Maximize Transparency**.
To adopt Istio, an operator or developer should be required to do the minimum amount of work possible to get real value from the system. To this end, Istio
can automatically inject itself into all the network paths between services. Istio uses sidecar proxies to capture traffic, and where possible, automatically
program the networking layer to route traffic through those proxies without any changes to the deployed application code. In Kubernetes, the proxies are
injected into pods and traffic is captured by programming iptables rules. Once the sidecar proxies are injected and traffic routing is programmed, Istio is
able to mediate all traffic. This principle also applies to performance. When applying Istio to a deployment, operators should see a minimal increase in
resource costs for the
functionality being provided. Components and APIs must all be designed with performance and scale in mind.

- **Incrementality**.
As operators and developers become more dependent on the functionality that Istio provides, the system must grow with their needs. While we expect to
continue adding new features ourselves, we expect the greatest need will be the ability to extend the policy system, to integrate with other sources of policy and control and to propagate signals about mesh behavior to other systems for analysis. The policy runtime supports a standard extension mechanism for plugging in other services. In addition, it allows for the extension of its vocabulary to allow policies to be enforced based on new signals that the mesh produces.

- **Portability**.
The ecosystem in which Istio will be used varies along many dimensions. Istio must run on any cloud or on-prem environment with minimal effort. The task of
porting Istio-based services to new environments should be trivial, and it should be possible to operate a single service deployed into multiple
environments (on multiple clouds for redundancy for example) using Istio.

- **Policy Uniformity**.
The application of policy to API calls between services provides a great deal of control over mesh behavior, but it can be equally important to apply
policies to resources which are not necessarily expressed at the API level. For example, applying quota to the amount of CPU consumed by an ML training task
is more useful than applying quota to the call which initiated the work. To this end, the policy system is maintained as a distinct service with its own API
rather than being baked into the proxy/sidecar, allowing services to directly integrate with it as needed.
