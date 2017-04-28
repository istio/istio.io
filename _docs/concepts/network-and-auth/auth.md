---
title: Auth
overview: Architectural deep-dive into the design of Auth, which provides the secure communication channel and strong identity for Istio.
              
order: 10

bodyclass: docs
layout: docs
type: markdown
---

## Overview

Istio Auth's aim is to enhance the security of microservices and their communication without requiring service code changes. It is responsible for:



*   Providing each service with a strong identity that represents its role to enable interoperability across clusters and clouds

*   Securing both service to service communication and end-user to service communication

*   Providing a key management system to automate key/cert generation, distribution, rotation, and revocation

In future versions it will also provide:

*   Fine-grained authorization and auditing to control and monitor who accesses your services, apis, or resources

*   Powerful authorization mechanisms: [ABAC](https://en.wikipedia.org/wiki/Attribute-Based_Access_Control), [RBAC](https://en.wikipedia.org/wiki/Role-based_access_control), Authorization hooks

## Architecture

The figure below shows the Istio Auth architecture, which includes three important components: identity, key management, and communication security. This diagram describes how Istio Auth is used to secure the service-to-service communication between service A, running as the service account "foo", and service B, running as the service account "bar".

<img style="display:block;margin:auto" src="./img/auth/auth.svg" alt="Istio Auth Architecture." />

## Components

### Identity

Istio Auth uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) to identify who runs the service because of the following reasons:



*   A service account is **the identity (or role) a workload runs as**, which represents that workload's privileges. For the system requiring strong security, the amount of privilege for a workload should not be identified by a random string (i.e., service name, label, etc), or by the binary that is deployed.

    *   For example, let's say we have a workload pulling data from a multi-tenant database. If Alice ran this workload, she will be able to pull a different set of data than if Bob ran this workload.

*   Service accounts enable powerful security policies by offering the flexibility to identify a machine, a user, a workload, or a group of workloads (different workloads can run as the same service account).

*   The service account a workload runs as won't change during the lifetime of the workload.

*   Service account uniqueness can be ensured with domain name constraint

### Communication Security

Service-to-service communication is tunneled through the client side [Envoy](https://lyft.github.io/envoy/) and the server side Envoy. The end-to-end communication is secured by:



*   Local TCP connections between the service and Envoy

*   Mutual TLS connections between proxies

*   Secure Naming: during the handshake process, the client side Envoy checks that the service account provided by the server side certificate is allowed to run the target service

### Key Management

Istio Auth provides a per-cluster CA (Certificate Authority) to automate key & cert management. It performs four key operations:



*   Generate a key/cert pair for each service account

*   Distribute key/cert to each pod according to the service account

*   Rotate key/cert periodically

*   Revoke a specific key/cert pair when necessary

## Workflow

Istio Auth workflow consists of two phases, deployment and runtime. This section covers both of them.

### Deployment Phase



1.  Istio CA watches Kubernetes API Server, creates a cert/key pair for each of the existing and new service accounts, and sends them to API Server. 
1.  When a pod is created, API Server mounts the cert/key according to the service account using [kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

1.  [Istio Manager](https://istio.io/docs/concepts/traffic-management/manager.html) generates the config with proper cert/key and secure naming information, which defines what service account(s) can run a certain service, and passes it to Envoy. 

### Runtime Phase



1.  The outbound traffic from a client service is rerouted to its local Envoy. 

1.  The client side Envoy starts a mutual TLS handshake with the server side Envoy. During the handshake, it also does a secure naming check to verify that the service account presented in the server certificate can run the server service. 

1.  The traffic is forwarded to the server side Envoy after mTLS connection is established, which is then forwarded to the server service through local TCP connections.

## Service to Service Auth Best Practice

In this section, we provide a few deployment guidelines and then discuss a real-world scenario. 

### Deployment Guidelines



*   If there are multiple service operators (a.k.a. [SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering)) deploying different services in a cluster (typically in a medium- or large-size cluster), we recommend creating a separate [namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/) for each SRE team to isolate their access. For example, you could create a "team1-ns" namespace for team1, and "team2-ns" namespace for team2, such that both teams won't be able to access each other's services.

*   If Istio CA is compromised, all its managed keys & certs in the cluster may be exposed. We *strongly* recommend running Istio CA on a dedicated namespace (for example, istio-ca-ns), which only cluster admins have access to.

### Example

Let's consider a 3-tier application with three services: photo-frontend, photo-backend, and datastore. Photo-frontend and photo-backend services are managed by the photo SRE team while the datastore service is managed by the datastore SRE team. Photo-frontend can access photo-backend, and photo-backend can access datastore. However, photo-frontend cannot access datastore.

In this scenario, a cluster admin can creates 3 namespaces: istio-ca-ns, photo-ns, and datastore-ns. Admin has access to all namespaces, and each team only has access to its own namespace. The photo SRE team creates 2 service accounts to run photo-frontend and photo-backend respectively in namespace photo-ns. The datastore SRE team creates 1 service account to run the datastore service in namespace datastore-ns. Moreover, we need to enforce the service access control in [Istio Mixer](https://istio.io/docs/concepts/policy-and-control/mixer.html) such that photo-frontend cannot access datastore.

In this setup, Istio CA is able to provide key/cert management for all namespaces, and we successfully prevent any team from messing up services run by other teams.

## Future Work



*   Fine-grained authorization and auditing

*   key/cert rotation and revocation

*   Secure Istio components (mixer, discovery service, etc.)

*   Inter-cluster service-to-service authentication

*   End-user to service authentication

*   Support GCP service account and AWS service account

*   None-http traffic (MySql, Redis, etc.) support

*   Auth info propagation from Envoy to the service ([issue](https://github.com/lyft/envoy/issues/794))

*   Unix domain socket for local communication between service and Envoy

*   Middle proxy support

*   Pluggable key management component

*   Istio CA security improvement

