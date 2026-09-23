---
title: Use Layer 4 security policy
description: Supported security features when only using the secure L4 overlay.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

The Layer 4 (L4) features of Istio's [security policies](/docs/concepts/security) are supported by {{< gloss >}}ztunnel{{< /gloss >}}, and are available in {{< gloss "ambient" >}}ambient mode{{< /gloss >}}. [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) also continue to work if your cluster has a {{< gloss >}}CNI{{< /gloss >}} plugin that supports them, and can be used to provide defense-in-depth.

The layering of ztunnel and {{< gloss "waypoint" >}}waypoint proxies{{< /gloss >}} gives you a choice as to whether or not you want to enable Layer 7 (L7) processing for a given workload. To use L7 policies, and Istio's traffic routing features, you can [deploy a waypoint](/docs/ambient/usage/waypoint) for your workloads. Because policy can now be enforced in two places, there are [considerations](#considerations) that need to be understood.

## Policy enforcement using ztunnel

The ztunnel proxy can perform authorization policy enforcement when a workload is enrolled in {{< gloss "Secure L4 Overlay" >}}secure overlay mode{{< /gloss >}}. The enforcement point is the receiving (server-side) ztunnel proxy in the path of a connection.

A basic L4 authorization policy looks like this:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-curl-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/curl
{{< /text >}}

This policy can be used in both {{< gloss "sidecar" >}}sidecar mode{{< /gloss >}} and ambient mode.

The L4 (TCP) features of the Istio `AuthorizationPolicy` API have the same functional behavior in ambient mode as in sidecar mode. When there is no authorization policy provisioned,  the default action is `ALLOW`. Once a policy is provisioned, pods targeted by the policy only permit traffic which is explicitly allowed. In the above example, pods with the label `app: httpbin` only permit traffic from sources with an identity principal of `cluster.local/ns/ambient-demo/sa/curl`. Traffic from all other sources will be denied.

## Targeting policies

Sidecar mode and L4 policies in ambient are *targeted* in the same fashion: they are scoped by the namespace in which the policy object resides, and an optional `selector` in the `spec`. If the policy is in the Istio root namespace (traditionally `istio-system`), then it will target all namespaces.  If it is in any other namespace, it will target only that namespace.

L7 policies in ambient mode are enforced by waypoints, which are configured with the {{< gloss "gateway api" >}}Kubernetes Gateway API{{< /gloss >}}. They are *attached* using the `targetRef` field.

## Allowed policy attributes

Authorization policy rules can contain [source](/docs/reference/config/security/authorization-policy/#Source) (`from`), [operation](/docs/reference/config/security/authorization-policy/#Operation) (`to`), and [condition](/docs/reference/config/security/authorization-policy/#Condition) (`when`) clauses.

This list of attributes determines whether a policy is considered L4-only:

| Type | Attribute | Positive match | Negative match |
| --- | --- | --- | --- |
| Source | Peer identity | `principals` | `notPrincipals` |
| Source | Namespace | `namespaces` | `notNamespaces` |
| Source | IP block | `ipBlocks` | `notIpBlocks` |
| Operation | Destination port | `ports` | `notPorts` |
| Condition | Source IP | `source.ip` | n/a |
| Condition | Source namespace | `source.namespace` | n/a |
| Condition | Source identity | `source.principal` | n/a |
| Condition | Remote IP | `destination.ip` | n/a |
| Condition | Remote port | `destination.port` | n/a |

### Policies with Layer 7 conditions

The ztunnel cannot enforce L7 policies. If a policy with rules matching L7 attributes (i.e. those not listed in the table above) is targeted such that it will be enforced by a receiving ztunnel, it will fail safe by becoming a `DENY` policy.

This example adds a check for the HTTP GET method:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-curl-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/curl
   to:
   - operation:
       methods: ["GET"]
{{< /text >}}

Even if the identity of the client pod is correct, the presence of a L7 attribute causes the ztunnel to deny the connection:

{{< text plain >}}
command terminated with exit code 56
{{< /text >}}

## Choosing enforcement points when waypoints are introduced {#considerations}

When a waypoint proxy is added to a workload, you now have two possible places where you can enforce L4 policy. (L7 policy can only be enforced at the waypoint proxy.)

With only the secure overlay, traffic appears at the destination ztunnel with the identity of the *source* workload.

Waypoint proxies do not impersonate the identity of the source workload. Once you have introduced a waypoint to the traffic path, the destination ztunnel will see traffic with the *waypoint's* identity, not the source identity.

This means that when you have a waypoint installed, **the ideal place to enforce policy shifts**. Even if you only wish to enforce policy against L4 attributes, if you are dependent on the source identity, you should attach your policy to your waypoint proxy. A second policy may be targeted at your workload to make its ztunnel enforce policies like "in-mesh traffic must come from my waypoint in order to reach my application".

## Peer authentication

Istio's [peer authentication policies](/docs/concepts/security/#peer-authentication), which configure mutual TLS (mTLS) modes, are supported by ztunnel.

The default policy for ambient mode is `PERMISSIVE`, which allows pods to accept both mTLS-encrypted traffic (from within the mesh) and plain text traffic (from without). Enabling `STRICT` mode means that pods will only accept mTLS-encrypted traffic.

As ztunnel and {{< gloss >}}HBONE{{< /gloss >}} implies the use of mTLS, it is not possible to use the `DISABLE` mode in a policy. Such policies will be ignored.
