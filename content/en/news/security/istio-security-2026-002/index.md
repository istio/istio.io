---
title: ISTIO-SECURITY-2026-002
subtitle: Security Bulletin
description: Man-in-the-Middle Attack Through VirtualService.
cves: []
cvss: "5.9"
vector: "AV:N/AC:L/PR:H/UI:R/S:C/C:L/I:L/A:L"
releases: ["All releases since the introduction of the mesh gateway option in the `VirtualService` resource"]
publishdate: 2026-03-21
skip_seealso: true
---

{{< security_bulletin >}}

The Istio Security Committee wants to address a possible Man-in-the-Middle attack scenario in which a `VirtualService` can redirect or intercept traffic within the service mesh. It affects only namespace-based Multi-Tenant environments.

This attack allows an attacker with the `VirtualService` permission in one namespace to redirect traffic from any Pod in the Istio service mesh to an attacker-controlled service. The attack scenario abuses the ability to set arbitrary hostnames in the `spec.hosts.[]` field of the `VirtualService` resource when the ``mesh`` gateway is set. An attacker can intercept, redirect, and drop the traffic communicated between services. This affects traffic to other services in the mesh and to external services. However, the attacker cannot bypass the [Authorization Policies](/docs/reference/config/security/authorization-policy/) or the mutual TLS authentication configured on the destination service.

Please note that the issues even extend beyond the cluster scope in a [_"single mesh with multiple clusters"_ deployment](/docs/ops/deployment/deployment-models/#multiple-clusters).

The Istio maintainers consider this issue to be expected behavior in Istio. Several of their resources, like `VirtualService`, `DestinationRule`, and `ServiceEntry`, modify traffic to a particular hostname across the mesh, and even though these resources are namespaced, they affect the mesh's traffic patterns (within a given cluster). This is a purposeful user experience trade-off to avoid tedious admin controls for each hostname and namespace. In contrast to the newer [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/), these CRDs were created and effectively stabilized before namespace-based RBAC even made its way to Kubernetes, and changes would break existing functionality.

Therefore, operators running Istio in namespace-based multi-tenancy setups or operating a single mesh across multiple clusters should apply additional safeguards to maintain strong isolation. Without these controls, unintended cross-namespace traffic manipulation can occur at the data plane level.

The recommended mitigation is to migrate to the newer Gateway API in those setups. When such changes and restrictions aren’t feasible in legacy setups, [further hardening and restrictions should be applied](/blog/2026/security-considerations-on-namespace-based-multi-tenancy/#mitigation-and-best-practices) to reduce the impact of these weaknesses.

Further details about the issue and mitigation can be found in the [blog post](/blog/2026/security-considerations-on-namespace-based-multi-tenancy/).

The Istio Security Committee would like to thank Sven Nobis and Lorin Lehawany from ERNW Enno Rey Netzwerke GmbH for disclosing this issue.
