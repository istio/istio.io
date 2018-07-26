---
title: Using Istio to Improve End-to-End Security
description: Istio Auth 0.1 announcement
publishdate: 2017-05-25
subtitle: Secure by default service to service communications
attribution: The Istio Team
weight: 99
aliases:
    - /blog/0.1-auth.html
    - /blog/istio-auth-for-microservices.html
---

Conventional network security approaches fail to address security threats to distributed applications deployed in dynamic production environments. Today, we describe how Istio Auth enables enterprises to transform their security posture from just protecting the edge to consistently securing all inter-service communications deep within their applications. With Istio Auth, developers and operators can protect services with sensitive data against unauthorized insider access and they can achieve this without any changes to the application code!

Istio Auth is the security component of the broader [Istio platform](/). It incorporates the learnings of securing millions of microservice
endpoints in Google’s production environment.

## Background

Modern application architectures are increasingly based on shared services that are deployed and scaled dynamically on cloud platforms. Traditional network edge security (e.g. firewall) is too coarse-grained and allows access from unintended clients. An example of a security risk is stolen authentication tokens that can be replayed from another client. This is a major risk for companies with sensitive data that are concerned about insider threats. Other network security approaches like IP whitelists have to be statically defined, are hard to manage at scale, and are unsuitable for dynamic production environments.

Thus, security administrators need a tool that enables them to consistently, and by default, secure all communication between services across diverse production environments.

## Solution: strong service identity and authentication

Google has, over the years, developed architecture and technology to uniformly secure millions of microservice endpoints in its production environment against
external
attacks and insider threats. Key security principles include trusting the endpoints and not the network, strong mutual authentication based on service identity and service level authorization. Istio Auth is based on the same principles.

The version 0.1 release of Istio Auth runs on Kubernetes and provides the following features:

* Strong identity assertion between services

* Access control to limit the identities that can access a service (and its data)

* Automatic encryption of data in transit

* Management of keys and certificates at scale

Istio Auth is based on industry standards like mutual TLS and X.509. Furthermore, Google is actively contributing to an open, community-driven service security framework called [SPIFFE](https://spiffe.io/). As the [SPIFFE](https://spiffe.io/) specifications mature, we intend for Istio Auth to become a reference implementation of the same.

The diagram below provides an overview of the Istio Auth service authentication architecture on Kubernetes.

{{< image width="100%" ratio="56.25%"
    link="./istio_auth_overview.svg"
    caption="Istio Auth Overview"
    >}}

The above diagram illustrates three key security features:

### Strong identity

Istio Auth uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) to identify who the service runs as. The identity is used to establish trust and define service level access policies. The identity is assigned at service deployment time and encoded in the SAN (Subject Alternative Name) field of an X.509 certificate. Using a service account as the identity has the following advantages:

* Administrators can configure who has access to a Service Account by using the [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) feature introduced in Kubernetes 1.6

* Flexibility to identify a human user, a service, or a group of services

* Stability of the service identity for dynamically placed and auto-scaled workloads

### Communication security

Service-to-service communication is tunneled through high performance client side and server side [Envoy](https://envoyproxy.github.io/envoy/) proxies. The communication between the proxies is secured using mutual TLS. The benefit of using mutual TLS is that the service identity is not expressed as a bearer token that can be stolen or replayed from another source. Istio Auth also introduces the concept of Secure Naming to protect from a server spoofing attacks - the client side proxy verifies that the authenticated server's service account is allowed to run the named service.

### Key management and distribution

Istio Auth provides a per-cluster CA (Certificate Authority) and automated key & certificate management. In this context, Istio Auth:

* Generates a key and certificate pair for each service account.

* Distributes keys and certificates to the appropriate pods using [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

* Rotates keys and certificates periodically.

* Revokes a specific key and certificate pair when necessary (future).

The following diagram explains the end to end Istio Auth authentication workflow on Kubernetes:

{{< image width="100%" ratio="56.25%"
    link="./istio_auth_workflow.svg"
    caption="Istio Auth Workflow"
    >}}

Istio Auth is part of the broader security story for containers. Red Hat, a partner on the development of Kubernetes, has identified [10 Layers](https://www.redhat.com/en/resources/container-security-openshift-cloud-devops-whitepaper) of container security. Istio and Istio Auth addresses two of these layers: "Network Isolation" and "API and Service Endpoint Management". As cluster federation evolves on Kubernetes and other platforms, our intent is for Istio to secure communications across services spanning multiple federated clusters.

## Benefits of Istio Auth

**Defense in depth**: When used in conjunction with Kubernetes (or infrastructure) network policies, users achieve higher levels of confidence, knowing that pod-to-pod or service-to-service communication is secured both at network and application layers.

**Secure by default**: When used with Istio’s proxy and centralized policy engine, Istio Auth can be configured during deployment with minimal or no application change. Administrators and operators can thus ensure that service communications are secured by default and that they can enforce these policies consistently across diverse protocols and runtimes.

**Strong service authentication**: Istio Auth secures service communication using mutual TLS to ensure that the service identity is not expressed as a bearer token that can be stolen or replayed from another source. This ensures that services with sensitive data can only be accessed from strongly authenticated and authorized clients.

## Join us in this journey

Istio Auth is the first step towards providing a full stack of capabilities to protect services with sensitive data from external attacks and insider
threats. While the initial version runs on Kubernetes, our goal is to enable Istio Auth to secure services across diverse production environments. We encourage the
community to [join us]({{< github_tree >}}/security) in making robust service security easy and ubiquitous across different application
stacks and runtime platforms.
