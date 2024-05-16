---
title: Use Layer 4 security policy
description: Supported security features when only using the secure L4 overlay.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

The layering of {{< gloss >}}ztunnel{{< /gloss >}} and {{< gloss >}}waypoint{{< /gloss >}} proxies in Istio's ambient mode gives you a choice on whether or not you want to enable Layer 7 (L7) processing for a given workload.

The Layer 4 (L4) features of Istio's [security policies](/docs/concepts/security) are supported by ztunnel, and are available in ambient mode. [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) also continue to work if your cluster has a {{< gloss >}}CNI{{< /gloss >}} plugin that supports them, and can be used to provide defense-in-depth.

To use L7 policies, and Istio's traffic routing features, you can [deploy a waypoint](/docs/ambient/usage/waypoint) for your workloads.

## Layer 4 authorization policies

The ztunnel proxy performs authorization policy enforcement when a workload is enrolled in secure overlay mode.

The actual enforcement point is at the receiving (server-side) ztunnel proxy in the path of a connection.

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

The behavior of the L4 `AuthorizationPolicy` API has the same functional behavior in Istio ambient mode as in sidecar mode. When there is no `AuthorizationPolicy` provisioned, then the default action is `ALLOW`. Once a policy is provisioned, pods matching the selector in the policy only allow traffic which is explicitly allowed. In this example, pods with the label `app: httpbin` only allow traffic from sources with an identity principal of `cluster.local/ns/ambient-demo/sa/sleep`. Traffic from all other sources will be denied.

### Layer 7 authorization policies without waypoints installed

{{< warning >}}
If an `AuthorizationPolicy` has been configured that requires any traffic processing beyond L4, and if no waypoint proxies are configured for the destination of the traffic, then ztunnel proxy will simply drop all traffic as a defensive move. Hence, check to ensure that either all rules involve L4 processing only or else if non-L4 rules are unavoidable, that waypoint proxies are configured.
{{< /warning >}}

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

## Peer authentication

Istio's [peer authentication policies](/docs/concepts/security/#peer-authentication), which configure mutual TLS (mTLS) modes, are supported by ztunnel.

As ztunnel and {{< gloss >}}HBONE{{< /gloss >}} implies the use of mTLS, it is not possible to use the `DISABLE` mode in a policy. Such policies will be ignored.

If you need to disable mTLS for an entire namespace, you will have to disable ambient mode:

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}
