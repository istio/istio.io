---
title: Concepts
headline: Concepts
sidenav: doc-side-nav.html
bodyclass: docs
layout: docs
type: markdown

index: true
category: Concepts
order: 10
---

# Concepts

Concepts help you learn about the different parts
of the Istio system and the abstractions it uses.

- What Is Istio?

    - [Context and Overview](./context-and-overview). Provides a broad overview of what
problems Istio is designed to solve.

    - [Design Goals](./design-goals.html). Describes the core principles that
    Istio's design adheres to.

    - [High-Level Architecture](./high-level-architecture.html). Highlights Istio's core
    architectural structure and components.

- Traffic Management

    - [Service Model](./service-model.html). Describes how services are
    modeled within the Istio mesh, the notion of multiple versions of a
    service, and the communiction model between services.

    - [Request Routing](./request-routing.html). Introduces the idea of
      application layer routing rules, that can be used to manipulate
      how API calls are routed to different versions of a service.
      
    - [Resiliency](./resiliency.html). An overview of failure recovery
      capabilities in Envoy that can be leveraged by unmodified
      applications to improve robustness and prevent cascading failures.

- Policies and Control

    - [Attributes](./attributes.html). Explains the important notion of attributes, which
    is a central mechanism for how policies and control are applied to services within the
    mesh.

    - [Mixer](./mixer.html). Architectural deep-dive into the design of Mixer, which provides
    the policy and control mechanisms within the service mesh.

    - [Mixer Configuration](./mixer-config.html). An overview of the key concepts used to configure
    Mixer.
