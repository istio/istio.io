---
title: What is Istio?
description: Find out what Istio can do for you.
weight: 10
keywords: [introduction]
owner: istio/wg-docs-maintainers-english
test: n/a
---

Istio is an open source service mesh that layers transparently onto existing distributed applications. Istio’s powerful features provide a uniform and more efficient way to secure, connect, and monitor services. Istio is the path to load balancing, service-to-service authentication, and monitoring – with few or no service code changes. It gives you:

* Secure service-to-service communication in a cluster with mutual TLS encryption, strong identity-based authentication and authorization
* Automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic
* Fine-grained control of traffic behavior with rich routing rules, retries, failovers, and fault injection
* A pluggable policy layer and configuration API supporting access controls, rate limits and quotas
* Automatic metrics, logs, and traces for all traffic within a cluster, including cluster ingress and egress

Istio is designed for extensibility and can handle a diverse range of deployment needs. Istio’s {{< gloss >}}control plane{{< /gloss >}} runs on Kubernetes, and you can add applications deployed in that cluster to your mesh, [extend the mesh to other clusters](/es/docs/ops/deployment/deployment-models/), or even [connect VMs or other endpoints](/es/docs/ops/deployment/vm-architecture/) running outside of Kubernetes.

A large ecosystem of contributors, partners, integrations, and distributors extend and leverage Istio for a wide variety of scenarios. You can install Istio yourself, or a [large number of vendors](/about/ecosystem) have products that integrate Istio and manage it for you.

## How it works

Istio uses a proxy to intercept all your network traffic, allowing a broad set of application-aware features based on configuration you set.

The control plane takes your desired configuration, and its view of the services, and dynamically programs the proxy servers, updating them as the rules or the environment changes.

The data plane is the communication between services. Without a service mesh, the network doesn’t understand the traffic being sent over, and can’t make any decisions based on what type of traffic it is, or who it is from or to.

Istio supports two data plane modes:

* **sidecar mode**, which deploys an Envoy proxy along with each pod that you start in your cluster, or running alongside services running on VMs.
* **ambient mode**, which uses a per-node capa 4 proxy, and optionally a per-namespace Envoy proxy for capa 7 features.

[Learn how to choose which mode is right for you](/es/docs/overview/data plane-modes/).
