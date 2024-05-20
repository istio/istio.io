---
title: Creating authorization policy
description: Understanding and leveraging the two enforcement points for policy in an ambient mesh.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Istio's ambient mode splits the data plane into two different sets of components. The architecture allows users to only pay for application layer processing if they need it. When leveraging the optional application layer processing it is important to understand how traffic flows through this architecture and where policy will be enforced. This guide will introduce a number of broad scenarios exploring the permutations therein and the details to understand for each scenario.

## TCP Enforcement

In the simplest enforcement scenario, you enforce policy against TCP attributes which can be handled entirely by ztunnel.

Once you introduce a waypoint proxy, the ideal place to enforce policy shifts. Traffic arriving at the destination ztunnel will have the waypoint's identity because waypoint proxies do not impersonate `src` identity on behalf of the client. This means that even if you only wish to enforce policy against only TCP attributes, if you are dependent on `src` identity you should bind your policy to your waypoint proxy. A second policy may be applied to your workload to request that ztunnel enforce things like, "in-mesh traffic needs to come from my waypoint in order to reach my application".

The following table is based on these invariants:

1. The source pod is a normal pod which has ztunnel enabled.
1. The waypoint is configured with the `istio.io/waypoint-for` label set to `service`.

| Waypoint † | Attachment Style | Scope | Source Identity | Enforced By |
| --- | --- | --- | --- | --- |
| no | Selector | Pod | client pod | destination ztunnel |
| yes | Selector | Pod | waypoint | destination ztunnel |
| no | _empty ‡_ | Namespace | client pod | destination ztunnel |
| yes | _empty ‡_ | Namespace | waypoint | destination ztunnel |
| yes | `targetRefs` | Service | client pod | waypoint |
| yes | `targetRefs` | Gateway | client pod | waypoint |

† Whether or not there is a waypoint in the traffic path.

‡ If no Selector or `targetRef` is specified, the policy is namespace scoped.

## HTTP Enforcement

In a scenario where policy requires application layer aware attributes, such as HTTP verbs, a waypoint proxy is required. Attempting to enforce any policy with application layer attributes at ztunnel will result in a DENY policy being enforced because ztunnel cannot meaningfully enforce the policy otherwise.

The following table is based on these invariants:

1. The source pod is a normal pod which has ztunnel enabled.
1. The waypoint is configured with the `istio.io/waypoint-for` label set to `service`.

| Waypoint † | Attachment Style | Scope | Source Identity | Enforced By |
| --- | --- | --- | --- | --- |
| no | Selector | Pod | client pod | destination ztunnel |
| yes | Selector | Pod | waypoint | destination ztunnel |
| no | _empty ‡_ | Namespace | client pod | destination ztunnel |
| yes | _empty ‡_ | Namespace | waypoint | destination ztunnel |
| yes | `targetRefs` | Service | client pod | waypoint |
| yes | `targetRefs` | Gateway | client pod | waypoint |

† Whether or not there is a waypoint in the traffic path.

‡ If no Selector or `targetRef` is specified, the policy is namespace scoped.

## Ingress and Policy Enforcement

If your application is exposed outside the cluster via an Istio ingress gateway, there are additional considerations to be aware of especially concerning enforcement of TCP layer policy in ztunnel.

## Diagram

{{< mermaid >}}
flowchart TD
    A{Policy Attachment} -->|TargetRef| B{Resource}
    A -->|Selector| C[desination ztunnel enforced*]
    A -->|None| C
    B -->|Service| D[waypoint enforced]
    B -->|Gateway| D
    C --> E{HTTP Policy?}
    E -->|Yes| F[Allow/Deny]
    E -->|No| G[Always DENY]
{{< /mermaid >}}
