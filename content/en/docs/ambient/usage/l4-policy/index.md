---
title: Use Layer 4 security policy
description: Supported security features when only using the secure L4 overlay.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

The layering of {{< gloss >}}ztunnel{{< /gloss >}} and {{< gloss >}}waypoint{{< /gloss >}} proxies in Istio's ambient mode gives you a choice on whether or not you want to enable Layer 7 (L7) processing for a given workload.

The Layer 4 (L4) features of Istio's [security policies](/docs/concepts/security) are supported by ztunnel, and are available in ambient mode. [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) also continue to work if your cluster has a {{< gloss >}}CNI{{< /gloss >}} plugin that supports them, and can be used to provide defense-in-depth.

To use L7 policies, and Istio's traffic routing features, you can [deploy a waypoint](/docs/ambient/usage/waypoint) for your workloads. Because policy can be enforced in two places, there are [considerations](#considerations) that need to be understood.

## Layer 4 authorization policies

The ztunnel proxy performs authorization policy enforcement when a workload is enrolled in secure overlay mode. The enforcement point is at the receiving (server-side) ztunnel proxy in the path of a connection.

A basic L4 authorization policy looks like this:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
EOF
{{< /text >}}

The behavior of the L4 `AuthorizationPolicy` API has the same functional behavior in Istio ambient mode as in sidecar mode. When there is no authorization policy provisioned, then the default action is `ALLOW`. Once a policy is provisioned, pods matching the selector in the policy only allow traffic which is explicitly allowed. In this example, pods with the label `app: httpbin` only allow traffic from sources with an identity principal of `cluster.local/ns/ambient-demo/sa/sleep`. Traffic from all other sources will be denied.

### Layer 7 authorization policies without waypoints installed

If an authorization policy has been configured that requires any traffic processing beyond L4, and if no waypoint proxies are configured for the destination of the traffic, then **the ztunnel proxy will DENY all traffic** as a defensive move. Hence, check to ensure that either all rules involve L4 processing only or else if non-L4 rules are unavoidable, that waypoint proxies are configured.

This example adds a check for the HTTP GET method:

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

Even though the identity of the pod is otherwise correct, the presence of a L7 policy, and the traffic not originating from a waypoint proxy, causes the ztunnel to deny the connection:

{{< text plain >}}
command terminated with exit code 56
{{< /text >}}

### Considerations when waypoints are introduced {#considerations}

In L4-only mode, traffic appears at the destination ztunnel with the identity of the *source* workload. 

Waypoint proxies do not impersonate the identity of the source workload. Once you have introduced a waypoint to the traffic path, the destination ztunnel will see traffic with the *waypoint's* identity, not the source identity.

This means that when you have a waypoint installed, the ideal place to enforce policy shifts. Even if you only wish to enforce policy against TCP attributes, if you are dependent on the source identity, you should bind your policy to your waypoint proxy. A second policy may be applied to your workload to request that ztunnel enforce policies like "in-mesh traffic must come from my waypoint in order to reach my application".

When the following conditions are true:

1. The policy only enforces [conditions](/docs/reference/config/security/conditions/) for TCP
1. The source pod is a normal pod which has ztunnel enabled
1. The waypoint is configured with the `istio.io/waypoint-for` label set to `service`

Policy enforcement will be applied as follows:

| Attachment Style | Scope | Waypoint present? | | Enforced by | Source identity 
| --- | --- | --- | --- | --- | --- |
| _empty †_ | Namespace | no | ⇒ | destination ztunnel | client pod |
| _empty †_ | Namespace | yes | ⇒ | destination ztunnel | waypoint |
| Selector | Pod | no | ⇒ | destination ztunnel | client pod |
| Selector | Pod | yes | ⇒ | destination ztunnel | waypoint |
| `targetRefs` | Service | yes | ⇒ | waypoint | client pod |
| `targetRefs` | Gateway | yes | ⇒ | waypoint | client pod |

*† If no Selector or `targetRef` is specified, the policy is namespace-scoped.*

## Peer authentication

Istio's [peer authentication policies](/docs/concepts/security/#peer-authentication), which configure mutual TLS (mTLS) modes, are supported by ztunnel.

As ztunnel and {{< gloss >}}HBONE{{< /gloss >}} implies the use of mTLS, it is not possible to use the `DISABLE` mode in a policy. Such policies will be ignored.

If you need to disable mTLS for an entire namespace, you will have to disable ambient mode:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}
