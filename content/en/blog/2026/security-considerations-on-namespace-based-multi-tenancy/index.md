---
title: "Security Considerations on Istio's CRDs with Namespace-based Multi-Tenancy"
description: Addressing Man-in-the-Middle weaknesses in Namespace-based Multi-Tenant Setups.
publishdate: 2026-03-19
attribution: "Lorin Lehawany (ERNW), Sven Nobis (ERNW)"
keywords: [Istio,Security,Multi-Tenancy,MITM,Man-in-the-Middle]
---

The Istio project was recently made aware of a possible Man-in-the-Middle (MITM) attack scenario in which a `VirtualService` can redirect or intercept traffic within the service mesh. This affects Namespace-based Multi-Tenancy clusters where tenants have the permissions to deploy Istio resources (``networking.istio.io/v1``).

This blog post highlights the risks of using Istio in multi-tenant clusters and explains how users can mitigate these risks and safely operate Istio in their deployments.

Please note that the issues even extend beyond the cluster scope in a [_"single mesh with multiple clusters"_ deployment](/docs/ops/deployment/deployment-models/#multiple-clusters).

The behavior described in this post applies to Istio version 1.29.0 and to all versions since the introduction of the mesh gateway option in the `VirtualService` resource.

## Background

### Namespace-based Multi-Tenancy

Namespaces in Kubernetes provide a mechanism for organizing groups of resources within a cluster. Namespaces provide a logical abstraction that allows teams, applications, or environments to share a single cluster while isolating their resources via controls such as Network Policies, RBAC, and so on.

In this blog post, we focus on running Istio in clusters where multiple tenants share the same cluster and service mesh, and can deploy Istio resources (``networking.istio.io/v1``) in their Namespaces while relying on Namespace boundaries for isolation.

### Traffic Routing in Istio

Istio provides traffic management capabilities by separating application logic from network routing behavior.
It introduces additional configuration resources through CRDs that allow operators to define how traffic should be routed between services in the mesh.

One of the central resources for this purpose is the `VirtualService`. A `VirtualService` defines a set of routing rules that determine how requests to hosts specified in `spec.hosts.[]` are handled. These rules can match requests based on properties such as HTTP headers, paths, or ports, and can then direct the traffic to one or more destination services.

Routing decisions defined in a `VirtualService` are not limited to a single workload or Namespace. Depending on how the resource is configured, these rules can affect traffic routing across the entire mesh.

In multi-tenant environments where multiple teams share the same service mesh, this behavior becomes particularly important from a security perspective and can bring security risks.

In the following section, we demonstrate how this mechanism can be abused to intercept traffic in a Namespace-based multi-tenant cluster.

## Man-in-the-Middle Attacks through VirtualService

In a Namespace-based multi-tenant environment, it is often assumed that Namespaces provide sufficient trust boundaries between resources across different Namespaces. However, Istio’s traffic routing configuration operates at the mesh level, meaning that routing rules defined in one Namespace will influence traffic originating from workloads in other Namespaces.

An attacker who has permission to create or modify `VirtualService` resources can abuse this behavior by defining routing rules for arbitrary hosts. When the mesh gateway is used, the routing rules are applied to all sidecar proxies in the service mesh, not just workloads within the Namespace where the `VirtualService` is defined.

This allows an attacker to create a malicious `VirtualService` that matches requests for specific hostnames and redirects them to an attacker-controlled service. As a result, traffic from other workloads in the mesh can be transparently routed through the attacker’s service before reaching its intended destination.

This behavior enables MITM attacks within the service mesh. The attacker-controlled service can:

- intercept, modify, and read the traffic communicated between services.
- redirect traffic to alternative destinations.
- drop requests to disrupt communication.

Depending on the targeted host, the attack can even affect both cluster-internal services and external services accessed by workloads in the mesh.

## Why does this behavior occur?

This behavior results from how Istio distributes and evaluates traffic routing configuration within the service mesh.

Istio service mesh is logically split into a data plane and a control plane. Istio’s control plane aggregates routing configuration from all `VirtualService` resources and distributes the resulting configuration to the Envoy sidecar proxies that make up the data plane. These proxies then enforce routing rules locally for the traffic they handle, see also [Istio Architecture](/docs/ops/deployment/architecture/).

When a `VirtualService` is configured as a mesh gateway, its routing rules apply to all sidecars in the mesh, including internal service-to-service traffic. Since the effects of this configuration are not limited to the Namespace in which the `VirtualService` resides, a configuration created in one Namespace can match requests originating from workloads in other Namespaces.

## Mitigation and Best Practices

Operators running Istio in Namespace-based Multi-Tenancy setups or operating a single mesh across multiple clusters should apply additional safeguards to maintain strong isolation. Without these controls, unintended Cross-Namespace traffic manipulation can occur at the data plane level.

Ideally, permissions to create or modify `VirtualService` resources should be limited to platform operators responsible for global routing. This can be enforced using Kubernetes RBAC policies to tightly control access to Istio networking resources.

When such restrictions aren’t feasible due to business or organizational requirements, routing configurations should be scoped to specific Services or Namespaces. Broad rules that affect the entire mesh should be avoided unless explicitly intended and their implications are well understood.

One way to mitigate this kind of attack is to restrict the [Egress listener in every namespace](/docs/reference/config/networking/sidecar/#IstioEgressListener) to trusted namespaces. However, this would only mitigate the issue in sidecar mode, but not [in ambient mode (using the per-node Layer 4 (L4) proxy)](/docs/ambient/overview/), and also not for hosts configured when an [Istio Gateway](/docs/reference/config/networking/gateway/) is used.

Another way to mitigate this kind of attack is to implement an [admission policy](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) that limits which hosts can be used in the ``host`` section for each tenant. This will also mitigate the issue in ambient mode.

## Conclusion

As shown in this post, Istio’s mesh gateway option allows rules defined in one Namespace to affect the traffic of other namespaces. In Namespace-based Multi-Tenancy setups or when running a single mesh across multiple clusters, this behavior may expose the service mesh to malicious actors, e.g., enabling MITM attacks, as explained in this blog post.

Istio does not claim (nor seek to claim) hard Namespace-based Multi-Tenancy as the project chose the tradeoff that eases adoption. Thus, operators who rely on this kind of Multi-Tenancy should assess the risks involved in their architecture and address the weaknesses, e.g., by removing unnecessary RBAC permissions and enforcing strict admission controls.

## References

- [Istio Documentation — Security Model](/docs/ops/deployment/security-model/#k8s-account-compromise)
- [Security Bulletin ISTIO-SECURITY-2026-002](/news/security/istio-security-2026-002/)
- [Istio Documentation — Traffic Management](/docs/concepts/traffic-management/)
- [Istio Documentation — VirtualService](/docs/reference/config/networking/virtual-service/)
