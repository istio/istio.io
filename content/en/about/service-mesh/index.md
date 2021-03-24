---
title: The Istio service mesh
description: Service mesh.
subtitle: Istio addresses the challenges developers and operators face with a distributed microservice architecture. Whether you're building from scratch or migrating existing applications to cloud native, Istio can help
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
    - /service-mesh.html
doc_type: about
---
[comment]: <> (TODO: Replace Service mesh graphic placeholder)

{{< figure src="/img/service-mesh.svg" alt="Service mesh" title="By adding a proxy 'sidecar' along with every application deployed, Istio lets you program application-aware traffic management, incredible observability, and robust security capabilities into your network." >}}

{{< centered_block >}}

## What is a Service Mesh?

Modern applications are typically designed as distributed collections of microservices, with each service performing some discrete business function. A service mesh is the dedicated infrastructure layer encompassing the network of microservices that make up this type of architecture. A service mesh describes not only this network, but also the interactions between distributed application components. All data passed between services is controlled and routed by the service mesh.

As the deployment of distributed services — such as in a Kubernetes-based system — grows in size and complexity, it can become harder to understand and manage. Requirements can include discovery, load balancing, failure recovery, metrics, and monitoring. A microservices architecture also often has more complex operational requirements, like A/B testing, canary deployments, rate limiting, access control, encryption and end-to-end authentication.

Service-to-service communication is what makes a distributed application possible. Routing this communication, both within and across application clusters becomes increasingly complex. Istio helps reduce this complexity while easing the strain on development teams
{{< /centered_block >}}

{{< centered_block >}}

## What is Istio?

Istio is an open source service mesh that layers transparently onto existing distributed applications. Istio’s powerful features provide a uniform and more efficient way to secure, connect, and monitor services  Istio is the path to load balancing, service-to-service authentication, and monitoring – with few or no service code changes. Its powerful control plane brings vital features, including:

- Secure service-to-service communication in a cluster with TLS encryption, strong identity-based authentication and authorization
- Automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic
- Fine-grained control of traffic behavior with rich routing rules, retries, failovers, and fault injection
- A pluggable policy layer and configuration API supporting access controls, rate limits and quotas
- Automatic metrics, logs, and traces for all traffic within a cluster, including cluster ingress and egress

Istio is designed for extensibility and can handle a diverse range of deployment needs. Istio's control plane runs on Kubernetes, and you can add applications deployed in that cluster to your mesh, extend the mesh to other clusters, or even connect VMs or other endpoints running outside of Kubernetes.

A large ecosystem of contributors, partners, integrations, and distributors extend and leverage Istio for a wide variety of scenarios.

You can install Istio yourself, or a number of vendors have products that integrate Istio and manage it for you.
{{< /centered_block >}}

{{< centered_block >}}

## How it works

Istio has two components: the control plane and the data plane.

The data plane is the communication between services. Without a service mesh, the network doesn't understand the traffic being sent over, and can't make any decisions based on what type of traffic it is, or who it is from or to.

Service mesh uses a proxy to intercept all your network traffic, allowing a broad set of application-aware features based on configuration you set.

A proxy is deployed along with each service that you start in your cluster, or runs alongside services running on VMs.

The control plane takes your desired configuration, and its view of the services, and dynamically programs the proxy servers, updating them as the rules or the environment changes.
{{< /centered_block >}}

{{< figure src="/img/service-mesh-before.svg" alt="Before utilizing Istio" title="Before utilizing Istio" >}}
{{< figure src="/img/service-mesh.svg" alt="After utilizing Istio" title="After utilizing Istio" >}}

# Concepts

{{< feature_block header="Traffic management" image="management.svg" >}}
Istio’s traffic routing rules let you easily control the flow of traffic and API calls between services. Istio simplifies configuration of service-level properties like circuit breakers, timeouts, and retries, and makes it easy to set up important tasks like A/B testing, canary deployments, and staged rollouts with percentage-based traffic splits. It also provides out-of-box failure recovery features that help make your application more robust against failures of dependent services or the network.
{{< /feature_block>}}

{{< feature_block header="Observability" image="observability.svg" >}}
Istio generates detailed telemetry for all communications within a service mesh. This telemetry provides observability of service behavior, empowering operators to troubleshoot, maintain, and optimize their applications. Even better, it does not  impose any additional burdens on service developers. Through Istio, operators gain a thorough understanding of how monitored services are interacting, both with other services and with the Istio components themselves.

Istio's telemetry includes detailed metrics, distributed traces, and full access logs. With Istio, you get thorough and comprehensive service mesh observability.

{{< /feature_block>}}

{{< feature_block header="Security capabilities" image="security.svg" >}}
Microservices have particular security needs, including protection against man-in-the-middle attacks, flexible access controls, auditing tools, and mutual TLS. Istio includes a comprehensive security solution to give operators the ability to address all of these issues. It provides strong identity, powerful policy, transparent TLS encryption, and authentication, authorization and audit (AAA) tools to protect your services and data.

Istio's security model is based on security-by-default, aiming to provide in-depth defense to allow you to deploy security-minded applications even across distrusted networks.
{{< /feature_block>}}

# Solutions

{{< solutions_carousel >}}