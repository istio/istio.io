---
category: Concepts
title: Auth
overview: Architectural deep-dive into the design of Auth, which provides the secure communication channel and strong identity for Istio.
              
parent: Network and Auth
order: 20

bodyclass: docs
layout: docs
type: markdown
---

The page explains Auth's role and general architecture.


## Istio Auth Concept

*Status: Draft*

*Date: April, 2017*


[TOC]


### Overview {#overview}

Istio Auth aims at enhancing the security of microservices and their communication without requiring service code changes. It is responsible for:



*   Presenting a strong identity that represents the role of the service to enable interoperability across clusters and clouds.
*   Securing the service to service communication and the end-user to service communication.
*   Providing a key management system to automate key/cert generation, distribution, rotation, and revocation.
*   Upcoming features:
    *   fine-grained authorization and auditing to control and monitor who accesses your services, apis, or resources, 
    *   powerful authorization mechanisms: [ABAC](https://en.wikipedia.org/wiki/Attribute-Based_Access_Control), [RBAC](https://en.wikipedia.org/wiki/Role-based_access_control), Authorization hooks.

### Architecture {#architecture}

Figure 1 shows the Istio Auth architecture, which includes three important components: identity, key management, and communication security. This diagram describes how Istio Auth is used to secure the service-to-service communication between service A running as the service account "foo" and service B running as the service account "bar".

<img style="display:block;width:60%;margin:auto;" src="./img/auth/auth.svg"
alt="Flow of traffic." />

### Components {#components}

#### Identity {#identity}

Istio Auth uses [Kubernetes service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) to identify who runs the service:



*   Service account is **the identity (or role) the workload runs as**, which represents the privilege of the workload. For the system requiring strong security, the amount of privilege for a workload should not be identified by a random string (i.e., service name, label, etc), or by the binary that is deployed.
    *   For example, let's say we have a workload pulling data from a multi-tenant database. If Alice ran this workload, she will be able to pull a different set of data than if Bob ran this workload. 
*   Service account enables powerful security policy by offering the flexibility to identify a machine, a user, a workload, or a group of workloads (different workloads can run as the same service account).
*   The service account a workload runs as won't change during the lifetime of the workload.
*   Service account uniqueness can be ensured with domain name constraint

#### Communication Security {#communication-security}

Service-to-service communication is tunneled through the client side [Envoy](https://lyft.github.io/envoy/) and the server side Envoy. The end-to-end communication is secured by:



*   Local TCP connections between the service and Envoy
    *   We are looking into using unix domain socket for stronger security
*   Mutual TLS connections between proxies
*   Secure Naming: during the handshake process, the client side Envoy checks that the service account provided by the server side certificate is allowed to run the target service

#### Key Management {#key-management}

Istio Auth provides a per-cluster CA (Certificate Authority) to automate key & cert management. It mainly performs 4 key operations:



*   Generate a key/cert pair for each service account.
*   Distribute key/cert to each pod according to the service account.
*   Rotate key/cert periodically. 
*   Revoke a specific key/cert pair when necessary.

### Workflow 

Istio Auth workflow consists of two phases, deployment and runtime. We briefly cover each phase in this section and a more detailed version can be found [here](https://docs.google.com/a/google.com/document/d/1spoQ9MIb7ABFDdFzlFITczCbH_AHO3RXSgLLeXAYIJU/edit?usp=sharing).

#### Deployment Phase {#deployment-phase}



1.  Istio CA watches K8s API Server, creates a cert/key pair for each of the existing and new service accounts, and sends them to API Server. 
1.  When a pod is created, API Server mounts the cert/key according to the service account using [kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/).
1.  [Istio Manager](https://github.com/istio/manager/blob/master/doc/design.md) generates the config with proper cert/key and secure naming information, which defines what service account(s) can run a certain service, and passes it to Envoy. 

#### Runtime Phase {#runtime-phase}



1.  The outbound traffic from a client service is rerouted to its local Envoy. 
1.  The client side Envoy starts mutual TLS handshake with the server side Envoy. During the handshake, it also does secure naming check to verify that the service account presented in the server certificate can run the server service. 
1.  The traffic is forwarded to the server side Envoy after mTLS connection is established, which is then forwarded to the server service through local TCP connections.

### Service to Service Auth Best Practice {#service-to-service-auth-best-practice}

In this section, we provide a few deployment guidelines and then discuss a real-world scenario. 

#### Deployment Guidelines {#deployment-guidelines}



*   If there are multiple service operators (a.k.a. [SREs](https://en.wikipedia.org/wiki/Site_reliability_engineering)) deploying different services in a cluster (typically in a medium- or large-size cluster), we recommend to create a separate [namespace](https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/) for each SRE team to isolate their access. For example, we can create a "team1-ns" namespace for team1, and "team2-ns" namespace for team2, such that both teams won't be able to access each other's services.
*   If Istio CA is compromised, all its managed key & cert in the cluster may be exposed. We *strongly *recommend to run Istio CA on a dedicated namespace (e.g., istio-ca-ns) which only cluster admins have access to.
    *   We are looking into running Isito CA in the kubernetes master in the future releases.

#### Example {#example}

Let's consider a 3-tier application with three services: photo-frontend, photo-backend, and datastore. Photo-frontend and photo-backend services are managed by the photo SRE team while the datastore service is managed by the datastore SRE team. Photo-frontend can access photo-backend, and photo-backend can access datastore. However, photo-frontend cannot access datastore.

In this scenario, a cluster admin can creates 3 namespaces: istio-ca-ns, photo-ns, and datastore-ns. Admin has access to all namespaces, and each team only has access to its own namespace. The photo SRE team creates 2 service accounts to run photo-frontend and photo-backend respectively in namespace photo-ns. The datastore SRE team creates 1 service account to run the datastore service in namespace datastore-ns. Moreover, we need to enforce the service access control in [Istio Mixer](https://github.com/istio/mixer) such that photo-frontend cannot access datastore.

In this setup, Istio CA is able to provide key/cert management for all namespaces. And we successfully prevent the team from messing up services running by other teams.

### Future Work {#future-work}



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

