---
category: Concepts
title: Overview

parent: What is Istio?
order: 15

bodyclass: docs
layout: docs
type: markdown
---

This page introduces Istio, a polyglot service mesh.

As monolithic applications transition towards a distributed microservice architecture they become more difficult to manage and understand. These 
architectures need basic necessities such as discovery, load balancing, failure recovery, metrics and monitoring, and more complex operational requirements 
such as A/B testing, canary releases, rate limiting, access control, and end-to-end authentication. The term service mesh is used to describe the network of
microservices that make up applications and the interactions between them. As the service mesh grows in size and complexity, it becomes harder to understand
and manage.

Istio provides a complete solution to satisfy these diverse requirements of microservice applications, by providing developers and operators with 
behavioral insights and operational control over the service mesh as a whole. Istio does this by providing a number of key capabilities uniformly across the
network of services:

- **Traffic Management**. Control the flow of traffic and API calls between services, make calls more reliable and make the network more robust in the face
of adverse conditions.
 
- **Observability**. Gain understanding of the dependencies between services, the nature and flow of traffic between them and be able to quickly identify 
issues.

- **Policy Enforcement**. Apply organizational policy to the interaction between services, ensure access policies are enforced and resources are fairly 
distributed among consumers. Policy changes are made by configuring the mesh, not by changing application code.

- **Service Identity and Security**. Provide services in the mesh with a verifiable identity and provide the ability to protect service traffic
as it flows over networks of varying degrees of trustability.

In addition to these behaviors, Istio is designed for extensibility to meet diverse deployment needs:

- **Platform Support**. Istio is designed to run in a variety of environments including ones that span Cloud, on-premise, Kubernetes, Mesos etc. We’re 
initially focused on Kubernetes but are working to support other environments soon.

- **Integration and Customization**. The policy enforcement component can be extended and customized to integrate with existing solutions for 
ACLs, logging, monitoring, quotas, auditing and more.

These capabilities greatly decrease the coupling between application code, the underlying platform and policy. This decreased coupling not only makes 
services easier to implement but also makes it simpler for operators to move application deployments between environments or to new policy schemes. 
Applications become inherently more portable as a result.

Istio’s service mesh is logically split into a *data plane* and a *control plane*. The data plane is composed of a set of intelligent (HTTP, HTTP/2, gRPC, TCP or UDP) 
proxies deployed as sidecars that mediate and control all network communication between microservices. The control plane is responsible for managing and 
configuring proxies to route traffic, as well as enforce policies at runtime. 

## What's next

* Learn about Istio's [design goals](./goals.html).
* Explore Istio's [high-level architecture](./architecture.html).


