---
title: Ambient and Kubernetes NetworkPolicy
description: Understanding how CNI-enforced L4 Kubernetes NetworkPolicy interacts with Istio's ambient mode.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Kubernetes [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) allows you to control how layer 4 traffic reaches your pods.

`NetworkPolicy` is typically enforced by the {{< gloss >}}CNI{{< /gloss >}} installed in your cluster. Istio is not a CNI, and does not enforce or manage `NetworkPolicy`, and in all cases respects it - ambient does not and will never bypass Kubernetes `NetworkPolicy` enforcement.

An implication of this is that it is possible to create a Kubernetes `NetworkPolicy` that will block Istio traffic, or otherwise impede Istio functionality, so when using `NetworkPolicy` and ambient together, there are some things to keep in mind.

## Ambient traffic overlay and Kubernetes NetworkPolicy

Once you have added applications to the ambient mesh, ambient's secure L4 overlay will tunnel traffic between your pods over port 15008. Once secured traffic enters the target pod with a destination port of 15008, the traffic will be proxied back to the original destination port.

However, `NetworkPolicy` is enforced on the host, outside the pod. This means that if you have preexisting `NetworkPolicy` in place that, for example, will deny list inbound traffic to an ambient pod on every port but 443, you will have to add an exception to that `NetworkPolicy` for port 15008. Sidecar workloads receiving traffic will also need to allow inbound traffic on port 15008 to allow ambient workloads to communicate with them.

For example, the following `NetworkPolicy` will block incoming {{< gloss >}}HBONE{{< /gloss >}} traffic to `my-app` on port 15008:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-allow-ingress-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
{{< /text >}}

and should be changed to

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-allow-ingress-web
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
    - port: 15008
      protocol: TCP
{{< /text >}}

if `my-app` is added to the mesh.

## Ambient, health probes, and Kubernetes NetworkPolicy

Kubernetes health check probes present a problem and create a special case for Kubernetes traffic policy in general. They originate from the kubelet running as a process on the node, and not some other pod in the cluster. They are plaintext and unsecured. Neither the kubelet or the Kubernetes node typically have their own cryptographic identity, so access control isn't possible. It's not enough to simply allow all traffic through on the health probe port, as malicious traffic could use that port just as easily as the kubelet could. In addition, many apps use the same port for health probes and legitimate application traffic, so simple port-based allows are unacceptable.

Various CNI implementations solve this in different ways and seek to either work around the problem by silently excluding kubelet health probes from normal policy enforcement, or configuring policy exceptions for them.

In Istio ambient, this problem is solved by using a combination of iptables rules and source network address translation (SNAT) to rewrite only packets that provably originate from the local node with a fixed link-local IP, so that they can be explicitly ignored by Istio policy enforcement as unsecured health probe traffic. A link-local IP was chosen as the default since they are typically ignored for ingress-egress controls, and [by IETF standard](https://datatracker.ietf.org/doc/html/rfc3927) are not routable outside of the local subnetwork.

This behavior is transparently enabled when you add pods to the ambient mesh, and by default ambient uses the link-local address `169.254.7.127` to identify and correctly allow kubelet health probe packets.

However if your workload, namespace or cluster has a preexisting ingress or egress `NetworkPolicy`, depending on the CNI you are using, packets with this link-local address may be blocked by the explicit `NetworkPolicy`, which will cause your application pod health probes to begin failing when you add your pods to the ambient mesh.

For instance, applying the following `NetworkPolicy` in a namespace would block all traffic (Istio or otherwise) to the `my-app` pod, **including** kubelet health probes. Depending on your CNI, kubelet probes and link-local addresses may be ignored by this policy, or be blocked by it:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  policyTypes:
  - Ingress
{{< /text >}}

Once the pod is enrolled in the ambient mesh, health probe packets will begin to be assigned a link local address via SNAT, which means health probes may begin to be blocked by your CNI's `NetworkPolicy` implementation. To allow ambient health probes to bypass `NetworkPolicy`, explicitly allow traffic from the host node to your pod by allow-listing the link-local address ambient uses for this traffic:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress-allow-kubelet-healthprobes
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-app
  ingress:
    - from:
      - ipBlock:
          cidr: 169.254.7.127/32
{{< /text >}}
