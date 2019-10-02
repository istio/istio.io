---
title: What is Istio?
description: Introduces Istio, the problems it solves, its high-level architecture and design goals.
weight: 15
aliases:
    - /docs/concepts/what-is-istio/overview
    - /docs/concepts/what-is-istio/goals
    - /about/intro
---

Cloud platforms provide a wealth of benefits for the organizations that use them. However, there’s no denying that adopting the cloud can put strains on DevOps teams. Developers must use microservices to architect for portability, meanwhile operators are managing extremely large hybrid and multi-cloud deployments.
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
 monitoring. A service mesh also often has more complex operational requirements, like A/B testing, canary rollouts, rate limiting, access control, and
 end-to-end authentication.

Istio provides behavioral insights and operational control over the service mesh as a whole, offering a complete solution to satisfy the diverse requirements of
 microservice applications.

## Why use Istio?

Istio makes it easy to create a network of deployed services with load balancing, service-to-service authentication, monitoring, and more, with [few](/docs/tasks/observability/distributed-tracing/overview/#trace-context-propagation) or no code changes
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
secure {{<gloss>}}pod{{</gloss>}}-to-pod or service-to-service communication at the network and application layers.

### Observability

Istio’s robust tracing, monitoring, and logging features give you deep insights into your service mesh deployment. Gain a real understanding of how service performance
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
