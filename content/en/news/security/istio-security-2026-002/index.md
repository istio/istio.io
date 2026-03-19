---
title: ISTIO-SECURITY-2026-002
subtitle: Security Bulletin
description: Man-in-the-Middle Attack Through VirtualService
cves: []
cvss: "5.9"
vector: "AV:N/AC:L/PR:H/UI:R/S:C/C:L/I:L/A:L"
publishdate: 2026-03-19
skip_seealso: true
---

{{< security_bulletin >}}

The Istio Security Committee was recently made aware of a possible Man-in-the-Middle attack scenario in which a `VirtualService` can redirect or intercept traffic within the service mesh.

This attack allows an attacker with the `VirtualService` permission in one Namespace to redirect traffic from any Pod in the Istio service mesh to an attacker-controlled service. The attack scenario abuses the ability to set arbitrary hostnames in the `spec.hosts.[]` field of the `VirtualService` resource when the ``mesh`` gateway is set. This affects traffic to both external services and cluster-internal services. An attacker can intercept, modify, and read the traffic communicated between services.

This issue is critical in multi-tenant clusters relying on Namespace isolation between tenants. An attacker can redirect traffic from arbitrary Namespaces, thereby breaking the trust boundary between them. Therefore, the Istio Security Committee considers Namespace-based Multi-Tenancy to be soft Multi-Tenancy and does not recommend this setup when strict tenant isolation is crucial. Please note that the issues even extend beyond the cluster scope in a [_"single mesh with multiple clusters"_ deployment](https://istio.io/latest/docs/ops/deployment/deployment-models/#multiple-clusters).

The Istio maintainers consider this issue to be expected behavior in Istio. Several of their resources, like `VirtualService`, `DestinationRule`, and `ServiceEntry`, modify traffic to a particular hostname across the mesh, and even though these resources are namespaced, they affect the mesh's traffic patterns (within a given cluster). This is a purposeful user experience trade-off to avoid tedious admin controls per hostname per Namespace.

Istio does not claim (nor seek to claim) hard Namespace-based Multi-Tenancy (a pattern that has become more common since these APIs were created); the project chose the tradeoff that eases adoption.

One way to mitigate potential attacks of this specific behavior is to restrict the [Egress listener in every namespace](https://istio.io/latest/docs/reference/config/networking/sidecar/#IstioEgressListener) to trusted Namespaces. However, this would only mitigate the issue in sidecar mode but not [in ambient mode (using the per-node Layer 4 (L4) proxy)](https://istio.io/latest/docs/ambient/overview/) and also not for Gateways.

Another way to mitigate this kind of attack is to implement an [admission policy](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/) that limits which hosts can be used in the ``host`` section for each tenant. This will also mitigate the issue in ambient mode.

Further details about the issue can be found in the [blog post](https://istio.io/latest/blog/2026/security-considerations-on-namespace-based-multi-tenancy/).

The Istio Security Committee would like to thank Sven Nobis and Lorin Lehawany from ERNW Enno Rey Netzwerke GmbH for disclosing this issue.