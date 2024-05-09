---
title: Policy enforcement in ambient mode
description: The two enforcement points for policy in an ambient mesh.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Istio's ambient data plane splits the data plane into two different sets of components. This architecture allows users to only pay for application layer processing if they need it. The trade off made is the extra complexity of understanding how traffic flows through this architecture and where policy will be enforced. This guide will introduce a number of broad scenarios and explore the permutations therein and the details to understand for each scenario.

## TCP Enforcement

In the simplest enforcement scenario you simply want to enforce policy against TCP attributes and you have no waypoint proxies in your traffic's path. These policies can be enforced by the ztunnel proxies.

Once you introduce a waypoint proxy the ideal place to enforce policy shifts. Traffic arriving at the destination ztunnel will be coming from the waypoint's identity because waypoint proxies do not impersonate src identity on behalf of the client. This means that even if you only wish to enforce policy against TCP attributes you should bind that policy to your waypoint proxy. A futher TCP policy may be applied to your workload to request that ztunnel enforce things like, "in-mesh traffic needs to come from my waypoint in order to reach my application". This type of policy allows you to choose if "bypassing" the waypoint proxy is permissable in your scenario.

This table is based on the following invariants:

1. The source pod is a normal pod which has ztunnel enabled.
1. Redirection to the waypoint is configured correctly.
1. The waypoint is configured with an appropriate `istio.io/waypoint-for` label such that it can accept the type of traffic being sent to it.

|  Name  | Waypoint* | Attachment Style | Resources  | Source Identity | Enforced By |
| --- | --- | --- | --- | --- | --- |
| TCP Policy | no | Selector | Pod | client pod | destination ztunnel |
| TCP Policy | yes | Selector | Pod | waypoint | destination ztunnel |
| TCP Policy | yes | ParentRef | Service | client pod | waypoint |
| HTTP Policy | yes | ParentRef | Service | client pod | waypoint |

* Whether or not there is already a waypoint is in the traffic path.

// link to details? table? further clarification

## HTTP Enforcement

In a scenario where policy requires application layer aware attributes, such as HTTP verbs, a waypoint proxy is required.

// details

## Ingress and Policy Enforcement

If your application is exposed outside the cluster via and Istio ingress gateway there are additional considerations to be aware of expecially concerning enforcement of TCP layer policy in ztunnel.

// details

## Deny Policy

// details

