---
title: Security Model
description: Describes Istio's security model.
weight: 10
owner: istio/wg-security-maintainers
test: n/a
---

This document aims to describe the security posture of Istio's various components, and how possible attacks can impact the system.

## Components

Istio comes with a variety of optional components that will be covered here.
For a high level overview, see [Istio Architecture](/docs/ops/deployment/architecture/).
Note that Istio deployments are highly flexible; below, we will primarily assume the worst case scenarios.

### Istiod

Istiod serves as the core control plane component of Istio, often serving the role of the [XDS serving component](/docs/concepts/traffic-management/) as well
as the mesh [mTLS Certificate Authority](/docs/concepts/security/).

Istiod is considered a highly privileged component, similar to that of the Kubernetes API server itself.
* It has high Kubernetes RBAC privileges, typically including `Secret` read access and webhook write access.
* When acting as the CA, it can provision arbitrary certificates.
* When acting as the XDS control plane, it can program proxies to perform arbitrary behavior.

As such, the security of the cluster is tightly coupled to the security of Istiod.
Following [Kubernetes security best practices](https://kubernetes.io/docs/concepts/security/) around Istiod access is paramount.

### Istio CNI plugin

Istio can optionally be deployed with the [Istio CNI Plugin `DaemonSet`](docs/setup/additional-setup/cni/).
This `DaemonSet` is responsible for setting up networking rules in Istio to ensure traffic is transparently redirected as needed.
This is an alternative to the `istio-init` container discussed [below](#sidecar-proxies).

Because the CNI `DaemonSet` modifies networking rules on the node, it requires an elevated `securityContext`.
However, unlike [Istiod](#istiod), this is a **node-local** privilege.
The implications of this are discussed [below](#node-compromise).

Because this consolidates the elevated privileges required to setup networking into a single pod, rather than *every* pod,
this option is generally recommended.

### Sidecar Proxies

Istio may [optionally](docs/overview/dataplane-modes/) deploy a sidecar proxy next to an application.

The sidecar proxy needs the network to be programmed to direct all traffic through the proxy.
This can be done with the [Istio CNI plugin](#istio-cni-plugin) or by deploying an `initContainer` (`istio-init`) on the pod (this is done automatically if the CNI plugin is not deployed).
The `istio-init` container requires `NET_ADMIN` and `NET_RAW` capabilities.
However, these capabilities are only present during the initialization - the primary sidecar container is completely unprivileged.

Additionally, the sidecar proxy does not require any associated Kubernetes RBAC privileges at all.

Each sidecar proxy is authorized to request a certificate for the associated Pod Service Account.

### Gateways and Waypoints

{{< gloss "gateway" >}}Gateways{{< /gloss >}} and {{< gloss "waypoint">}}Waypoints{{< /gloss >}} act as standalone proxy deployments.
Unlike [sidecars](#sidecar-proxies), they do not require any networking modifications, and thus don't require any privilege.

These components run with their own service accounts, distinct from application identities.

### Ztunnel

{{< gloss "ztunnel" >}}Ztunnel{{< /gloss >}} acts as a node-level proxy.
This task requires the `NET_ADMIN`, `SYS_ADMIN`, and `NET_RAW` capabilities.
Like the [Istio CNI Plugin](#istio-cni-plugin), these are **node-local** privileges only.
The Ztunnel does not have any associated Kubernetes RBAC privileges.

Ztunnel is authorized to request certificates for any Service Accounts of pods running on the same node.
Similar to [kubelet](https://kubernetes.io/docs/reference/access-authn-authz/node/), this explicitly does not allow requesting arbitrary
certificates.
This, again, ensures these privileges are **node-local** only.

## Traffic Capture Properties

When a pod is enrolled in the mesh, all incoming TCP traffic will be redirected to the proxy.
This includes both mTLS/{{< gloss >}}HBONE{{< /gloss >}} traffic and plaintext traffic.
Any applicable [policies](/docs/tasks/security/authorization/) for the workload will be enforced before forwarding the traffic to the workload.

However, Istio does not currently guarantee that _outgoing_ traffic is redirect to the proxy.
See [traffic capture limitations](/docs/ops/best-practices/security/#understand-traffic-capture-limitations).
As such, care must be taken to follow the [securing egress traffic](/docs/ops/best-practices/security/#securing-egress-traffic) steps if outbound policies are required.

## Mutual TLS Properties

[Mutual TLS](/docs/concepts/security/#mutual-tls-authentication) provides the basis for much of Istio's security posture.
Below explains various properties mutual TLS provides for the security posture of Istio.

### Certificate Authority

Istio comes out of the box with its own Certificate Authority.

By default, the CA allows authenticating clients based on either of the options below:
* A Kubernetes JWT token, with an audience of `istio-ca`, verified with a Kubernetes `TokenReview`. This is the default method in Kubernetes Pods.
* An existing mutual TLS certificate.
* Custom JWT tokens, verified using OIDC (requires configuration).

The CA will only issue certificates that are requested for identities that a client is authenticated for.

Istio can also integrate with a variety of third party CAs; please refer to any of their security documentation for more information on how they behave.

### Client mTLS

{{< tabset category-name="dataplane" >}}
{{< tab name="Sidecar mode" category-value="sidecar" >}}
In sidecar mode, the client sidecar will [automatically use TLS](/docs/ops/configuration/traffic-management/tls-configuration/#auto-mtls) when connecting to a service
that is detected to support mTLS. This can also be [explicitly configured](/docs/ops/configuration/traffic-management/tls-configuration/#sidecars).
Note that this automatic detection relies on Istio associating the traffic to a Service.
[Unsupported traffic types](/docs/ops/configuration/traffic-management/traffic-routing/#unmatched-traffic) or [configuration scoping](/docs/ops/configuration/mesh/configuration-scoping/) can prevent this.

When [connecting to a backend](/docs/concepts/security/#secure-naming), the set of allowed identities is computed, at the Service level, based on the union of all backend's identities.
{{< /tab >}}

{{< tab name="Ambient mode" category-value="ambient" >}}
In ambient mode, Istio will automatically use mTLS when connecting to any backend that supports mTLS, and verify the identity of the destination matches the identity the workload is expected to be running as.

These properties differ from sidecar mode in that they are properties of individual workloads, rather than of the service.
This enables more fine-grained authentication checks, as well as supporting a wider variety of workloads.
{{< /tab >}}
{{< /tabset >}}

### Server mTLS

By default, Istio will accept mTLS and non-mTLS traffic (often called "permissive mode").
Users can opt-in to strict enforcement by writing `PeerAuthentication` or `AuthorizationPolicy` rules requiring mTLS.

When mTLS connections are established, the peer certificate is verified.
Additionally, the peer identity is verified to be within the same trust domain.
To verify only specific identities are allowed, an `AuthorizationPolicy` can be used.

## Compromise types explored

Based on the above overview, we will consider the impact on the cluster if various parts of the system are compromised.
In the real world, there are a variety of different variables around any security attack:

* How easy it is to execute
* What prior privileges are required
* How often it can exploited
* What the impact is (total remote execution, denial of service, etc).

In this document, we will primarily consider the worst case scenario: a compromised component means an attacker has complete remote code execution capabilities.

### Workload compromise

In this scenario, an application workload (pod) is compromised.

A pod [*may* have access](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#opt-out-of-api-credential-automounting) to its service account token.
If so, a workload compromise can move laterally from a single pod to compromising the entire service account.

{{< tabset category-name="dataplane" >}}
{{< tab name="Sidecar mode" category-value="sidecar" >}}
In the sidecar model, the proxy is co-located with the pod, and runs within the same trust boundary.
A compromised application can tamper with the proxy through the admin API or other surfaces, including exfiltration of private key material, allowing another agent to impersonate the workload.
It should be assumed that a compromised workload also includes a compromise of the sidecar proxy.

Given this, a compromised workload may:
* Send arbitrary traffic, with or without mutual TLS.
  These may bypass any proxy configuration, or even the proxy entirely.
  Note that Istio does not offer egress-based authorization policies, so there is no egress authorization policy bypass occurring.
* Accept traffic that was already destined to the application. It may bypass policies that were configured in the sidecar proxy.

The key takeaway here is that while the compromised workload may behave maliciously, this does not give them the ability to bypass policies in _other_ workloads.
{{< /tab >}}

{{< tab name="Ambient mode" category-value="ambient" >}}
In ambient mode, the node proxy is not co-located within the pod, and runs in another trust boundary as part of an independent pod.

A compromised application may send arbitrary traffic.
However, they do not have control over the node proxy, which will chose how to handle incoming and outbound traffic.

Additionally, as the pod itself doesn't have access to a service account token to request a mutual TLS certificate, lateral movement possibilities are reduced.
{{< /tab >}}
{{< /tabset >}}

Istio offers a variety of features that can limit the impact of such a compromise:
* [Observability](/docs/tasks/observability/) features can be used to identify the attack.
* [Policies](/docs/tasks/security/authorization/) can be used to restrict what type of traffic a workload can send or receive.

### Proxy compromise - Sidecars

In this scenario, a sidecar proxy is compromised.
Because the sidecar and application reside in the same trust domain, this is functionally equivalent to the [Workload compromise](#workload-compromise).

### Proxy compromise - Waypoint

In this scenario, a [waypoint proxy](#gateways-and-waypoints) is compromised.
While waypoints do not have any privileges for a hacker to exploit, they do serve (potentially) many different services and workloads.
A compromised waypoint will receive all traffic for these, which it can view, modify, or drop.

Istio offers the flexibility of [configuring the granularity of a waypoint deployment](/docs/ambient/usage/waypoint/#useawaypoint).
Users may consider deploying more isolated waypoints if they require stronger isolation.

Because waypoints run with a distinct identity from the applications they serve, a compromised waypoint does not imply the user's applications can be impersonated.

### Proxy compromise - Ztunnel

In this scenario, a [ztunnel](#ztunnel) proxy is compromised.

A compromised ztunnel gives the attacker control of the networking of the node.

Ztunnel has access to private key material for each application running on it's node.
A compromised ztunnel could have these exfiltrated and used elsewhere.
However, lateral movement to identities beyond co-located workloads is not possible; each ztunnel is only authorized to access certificates for workloads running on its node, scoping the blast radius of a compromised ztunnel.

### Node compromise

In this scenario, the Kubernetes Node is compromised.
Both [Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/node/) and Istio are designed to limit the blast radius of a single node compromise, such that
the compromise of a single node does not lead to a [cluster-wide compromise](#cluster-api-server-compromise).

However, the attack does have complete control over any workloads running on that node.
For instance, it can compromise any co-located [waypoints](#proxy-compromise---waypoint), the local [ztunnel](#proxy-compromise---ztunnel), any [sidecars](#proxy-compromise---sidecars), any co-located [Istiod instances](#istiod-compromise), etc.

### Cluster (API Server) compromise

A compromise of the Kubernetes API Server effectively means the entire cluster and mesh are compromised.
Unlike most other attack vectors, there isn't much Istio can do to control the blast radius of such an attack.
A compromised API Server gives a hacker complete control over the cluster, including actions such as running `kubectl exec` on arbitrary pods,
removing any Istio `AuthorizationPolicies`, or even uninstalling Istio entirely.

### Istiod compromise

A compromise of Istiod generally leads to the same result as an [API Server compromise](#cluster-api-server-compromise).
Istiod is a highly privileged component that should be strongly protected.
Following the [security best practices](/docs/ops/best-practices/security) is crucial to maintaining a secure cluster.
