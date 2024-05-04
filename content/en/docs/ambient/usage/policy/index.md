---
title: Enable policy in ambient mode
description: The two enforcement points for policy in an ambient mesh.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

The ztunnel proxy performs authorization policy enforcement when a workload is enrolled in secure overlay mode (i.e. with no waypoint proxy configured).
The actual enforcement point is at the receiving (or server-side) ztunnel proxy in the path of a connection.

## Layer 4 authorization policies

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

The behavior of the `AuthorizationPolicy` API has the same functional behavior in Istio ambient mode as in sidecar mode. When there is no `AuthorizationPolicy` provisioned, then the default action is `ALLOW`. Once a policy is provisioned, pods matching the selector in the policy only allow traffic which is explicitly allowed. In this example, pods with the label `app:httpbin` only allow traffic from sources with an identity principal of `cluster.local/ns/ambient-demo/sa/sleep`. Traffic from all other sources will be denied.

## Layer 7 authorization policies without waypoints installed

{{< warning >}}
If an `AuthorizationPolicy` has been configured that requires any traffic processing beyond L4, and if no waypoint proxies are configured for the destination of the traffic, then ztunnel proxy will simply drop all traffic as a defensive move. Hence, check to ensure that either all rules involve L4 processing only or else if non-L4 rules are unavoidable, that waypoint proxies are configured.
{{< /warning >}}

This example adds a check for the HTTP GET method.

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

Even though the identity of the pod is otherwise correct, the presence of a L7 policy causes the ztunnel to deny the connection.

{{< text plain >}}
command terminated with exit code 56
{{< /text >}}

You can also confirm by viewing logs of specific ztunnel proxy pods (not shown in the example here) that it is always the ztunnel proxy on the node hosting the destination pod that actually enforces the policy.
