---
title: "Security Considerations on Istio's CRDs with Namespace-based Multi-Tenancy"
description: Addressing man-in-the-middle weaknesses in namespace-based multi-tenant setups.
publishdate: 2026-03-21
attribution: "Lorin Lehawany - ERNW, Sven Nobis - ERNW"
keywords: [Istio,Security,Multi-Tenancy,MITM,Man-in-the-Middle]
---

The Istio project wants to address a possible Man-in-the-Middle (MITM) attack scenario in which a `VirtualService` can redirect or intercept traffic within the service mesh. This affects namespace-based multi-tenancy clusters where tenants have the permissions to deploy Istio resources (``networking.istio.io/v1``).

This blog post highlights the risks of using Istio in multi-tenant clusters and explains how users can mitigate these risks and safely operate Istio in their deployments.

Please note that the issues even extend beyond the cluster scope in a [_"single mesh with multiple clusters"_ deployment](/docs/ops/deployment/deployment-models/#multiple-clusters).

The behavior described in this post applies to Istio version 1.29.0 and to all versions since the introduction of the mesh gateway option in the `VirtualService` resource.

## Background

### Namespace-based Multi-Tenancy

Namespaces in Kubernetes provide a mechanism for organizing groups of resources within a cluster. Namespaces provide a logical abstraction that allows teams, applications, or environments to share a single cluster while isolating their resources via controls such as Network Policies, RBAC, and so on.

In this blog post, we focus on running Istio in clusters where multiple tenants share the same cluster and service mesh, and can deploy Istio resources (``networking.istio.io/v1``) in their namespaces while relying on namespace boundaries for isolation.

### Traffic Routing in Istio

Istio provides traffic management capabilities by separating application logic from network routing behavior.
It introduces additional configuration resources through CRDs that allow operators to define how traffic should be routed between services in the mesh.

One of the central resources for this purpose is the `VirtualService`. A `VirtualService` defines a set of routing rules that determine how requests to hosts specified in `spec.hosts.[]` are handled. These rules can match requests based on properties such as HTTP headers, paths, or ports, and can then direct the traffic to one or more destination services.

Routing decisions defined in a `VirtualService` are not limited to a single workload or namespace. Depending on how the resource is configured, these rules can affect traffic routing across the entire mesh.

In contrast to the newer [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/), these CRDs were created and effectively stabilized before namespace-based RBAC even made its way to Kubernetes. Thus, namespace-based multi-tenancy that shares the same service mesh was not part of the threat model at the time. With the introduction of RBAC, such multi-tenant environments emerged. It is therefore important to highlight and address the security risks associated with those architectures.

In the following section, we demonstrate those risks and show that this mechanism can be abused to intercept traffic in a namespace-based multi-tenant cluster. Later, we introduce ways to mitigate those risks.

## Man-in-the-Middle Attacks through VirtualService

In a namespace-based multi-tenant environment, it is often assumed that namespaces provide sufficient trust boundaries between resources across different namespaces. However, Istio’s traffic routing configuration operates at the mesh level, meaning that routing rules defined in one namespace will influence traffic originating from workloads in other namespaces.

An attacker who has permission to create or modify `VirtualService` resources can abuse this behavior by defining routing rules for arbitrary hosts. When the service mesh parameter ``mesh`` is set in the `gateways` section of the spec, the routing rules are applied to all sidecar proxies in the mesh (independent of their namespace).

This allows an attacker to create a malicious `VirtualService` that matches requests for specific hostnames and redirects them to an attacker-controlled service. As a result, traffic from other workloads in the mesh can be transparently routed through the attacker’s service before reaching its intended destination.

This behavior enables MITM attacks within the service mesh. The attacker-controlled service can intercept traffic from services in the mesh. This includes traffic to other services in the mesh as well as traffic to the external services. This allows the attacker to:

* act as the destination service.
* redirect traffic to alternative destinations.
* drop requests to disrupt the communication (denial-of-service).

The source service will send the request to the attacker-controlled service instead of the destination service as the `VirtualService` overrides the default behavior. Istio's mutual TLS authentication does not help here, because the proxy identifies the attacker-controlled service as the legitimate destination of the overwritten hostname. However, forwarding this traffic to the destination service to read or modify communication between the two services is more challenging for the attacker, as they cannot bypass Istio's [Layer 4 and Layer 7 security features](/docs/overview/dataplane-modes/#layer-4-vs-layer-7-features). As the attacker intercepts the communication, the end-to-end encryption and authentication between the source and the destination service are broken. Thus, the request forwarded from the attacker-controlled service to the destination service is authenticated as a request from the attacker-controlled service. As a result, [Authorization Policies](/docs/reference/config/security/authorization-policy/) configured on the destination service may deny the request. In addition, destination service will see the attacker-controlled service identity in the ``X-Forwarded-Client-Cert`` header, and the authentication from the source service is lost.

## Why does this behavior occur?

This behavior results from how Istio distributes and evaluates traffic routing configuration within the service mesh.

Istio service mesh is logically split into a data plane and a control plane. Istio’s control plane aggregates routing configuration from all `VirtualService` resources and distributes the resulting configuration to the Envoy sidecar proxies that make up the data plane. These proxies then enforce routing rules locally for the traffic they handle, see also [Istio Architecture](/docs/ops/deployment/architecture/).

When a `VirtualService` is configured as a mesh gateway, its routing rules apply to all sidecars in the mesh, including internal service-to-service traffic. Since the effects of this configuration are not limited to the namespace in which the `VirtualService` resides, a configuration created in one namespace can match requests originating from workloads in other namespaces.

## Mitigation and Best Practices

Operators running Istio in namespace-based multi-tenancy setups or operating a single mesh across multiple clusters should apply additional safeguards to maintain strong isolation. Without these controls, unintended cross-namespace traffic manipulation can occur at the data plane level.

### Recommended Mitigation: Migrate to the Newer Gateway API

Ideally, permissions to create or modify Istio networking resources (``networking.istio.io/v1`` as well as ``security.istio.io/v1``) should be limited to platform operators responsible for global routing.

As an alternative, operators can offer tenants access to the newer [Gateway API](https://gateway-api.sigs.k8s.io/), which was designed with safe cross-namespace support in mind. However, the platform operators still need to control access to shared resources such as gateways.

[Configuration Scoping](/docs/ops/configuration/mesh/configuration-scoping/#scoping-mechanisms) can be implemented as an additional control.

### Mitigation in Legacy Setups

When such changes and restrictions aren’t feasible due to business or organizational requirements, routing configurations should be scoped to specific services or namespaces. Broad rules that affect the entire mesh should be avoided unless explicitly intended, and their implications are well understood.

One way to mitigate this kind of attack is to configure [Scoping](/docs/ops/configuration/mesh/configuration-scoping/#scoping-mechanisms). For instance, to restrict the [Egress listener in every namespace](/docs/reference/config/networking/sidecar/#IstioEgressListener) to trusted namespaces. However, this would only mitigate the issue in sidecar mode and ambient mode with waypoints, but not [in L4-only ambient mode](/docs/ambient/overview/), and also not for hosts configured when an [Istio Gateway](/docs/reference/config/networking/gateway/) is used.

Another way to mitigate this kind of attack is to implement an [admission policy](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) that limits which hosts can be used in the ``host`` section for each tenant. This will also mitigate the issue in ambient mode.

## Conclusion

As shown in this post, Istio’s mesh gateway option allows rules defined in one namespace to affect the traffic of other namespaces. In namespace-based multi-tenancy setups or when running a single mesh across multiple clusters, this behavior may expose the service mesh to malicious actors, e.g., enabling MITM attacks, as explained in this blog post.

Istio does not claim (nor seek to claim) hard namespace-based multi-tenancy as the project chose the tradeoff that eases adoption. Thus, operators who rely on this kind of multi-tenancy should assess the risks involved in their architecture and address the weaknesses, e.g., by removing unnecessary RBAC permissions and enforcing strict admission controls.

## References

* [Istio Documentation — Security Model](/docs/ops/deployment/security-model/#k8s-account-compromise)
* [Security Bulletin ISTIO-SECURITY-2026-002](/news/security/istio-security-2026-002/)
* [Istio Documentation — Traffic Management](/docs/concepts/traffic-management/)
* [Istio Documentation — VirtualService](/docs/reference/config/networking/virtual-service/)
