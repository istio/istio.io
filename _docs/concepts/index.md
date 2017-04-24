---
category: Concepts
title: Concepts
index: true

order: 10

bodyclass: docs
layout: docs
type: markdown

---

# Concepts

Concepts help you learn about the different parts
of the Istio system and the abstractions it uses.

- What Is Istio?

    - [Overview](./overview.html). Provides a broad overview of what
problems Istio is designed to solve.

    - [Design Goals](./goals.html). Describes the core principles that
    Istio's design adheres to.

    - [Architecture](./architecture.html). Highlights Istio's core
    architectural structure and components.

- Traffic Management

    - [Overview](./traffic-management-overview.html). Provides a conceptual overview of
      traffic management principles in Istio and the kind of features
      enabled by these principles.
      
    - [Istio-Manager](./manager.html). Introduces the Istio-Manager, the
    component responsible for managing a distributed deployment of Envoy
    proxies in the service mesh.

    - [Service Model](./service-model.html). Describes how services are
    modeled within the Istio mesh, the notion of multiple versions of a
    service, and the communiction model between services.

    - [Handling Failures](./handling-failures.html). An overview of failure
      recovery capabilities in Envoy that can be leveraged by unmodified
      applications to improve robustness and prevent cascading failures.

    - [Fault Injection](./fault-injection.html). Introduces the idea of
      systematic fault injection that can be used to unconver conflicting
      failure recovery policies across services.
      
    - [Rules Configuration](./rules-configuration.html). Provides a high-level
      overview of the domain-specific language used by Istio to configure
      traffic management rules in the service mesh.
      
- Policies and Control

    - [Attributes](./attributes.html). Explains the important notion of attributes, which
    is a central mechanism for how policies and control are applied to services within the
    mesh.

    - [Mixer](./mixer.html). Architectural deep-dive into the design of Mixer, which provides
    the policy and control mechanisms within the service mesh.

    - [Mixer Configuration](./mixer-config.html). An overview of the key concepts used to configure
    Mixer.
