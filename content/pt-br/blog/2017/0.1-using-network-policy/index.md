---
title: Using Network Policy with Istio
description: How Kubernetes Network Policy relates to Istio policy.
publishdate: 2017-08-10
subtitle:
attribution: Spike Curtis
aliases:
    - /blog/using-network-policy-in-concert-with-istio.html
target_release: 0.1
---

The use of Network Policy to secure applications running on Kubernetes is a now a widely accepted industry best practice.  Given that Istio also supports policy, we want to spend some time explaining how Istio policy and Kubernetes Network Policy interact and support each other to deliver your application securely.

Let’s start with the basics: why might you want to use both Istio and Kubernetes Network Policy? The short answer is that they are good at different things. Consider the main differences between Istio and Network Policy (we will describe "typical” implementations, e.g. Calico, but implementation details can vary with different network providers):

|                       | Istio Policy      | Network Policy     |
| --------------------- | ----------------- | ------------------ |
| **Layer**             | "Service" --- L7  | "Network" --- L3-4 |
| **Implementation**    | User space        | Kernel             |
| **Enforcement Point** | Pod               | Node               |

## Layer

Istio policy operates at the "service” layer of your network application. This is Layer 7 (Application) from the perspective of the OSI model, but the de facto model of cloud native applications is that Layer 7 actually consists of at least two layers: a service layer and a content layer. The service layer is typically HTTP, which encapsulates the actual application data (the content layer). It is at this service layer of HTTP that the Istio’s Envoy proxy operates. In contrast, Network Policy operates at Layers 3 (Network) and 4 (Transport) in the OSI model.

Operating at the service layer gives the Envoy proxy a rich set of attributes to base policy decisions on, for protocols it understands, which at present includes HTTP/1.1 & HTTP/2 (gRPC operates over HTTP/2). So, you can apply policy based on virtual host, URL, or other HTTP headers.  In the future, Istio will support a wide range of Layer 7 protocols, as well as generic TCP and UDP transport.

In contrast, operating at the network layer has the advantage of being universal, since all network applications use IP. At the network layer you can apply policy regardless of the layer 7 protocol: DNS, SQL databases, real-time streaming, and a plethora of other services that do not use HTTP can be secured. Network Policy isn’t limited to a classic firewall’s tuple of IP addresses, proto, and ports. Both Istio and Network Policy are aware of rich Kubernetes labels to describe pod endpoints.

## Implementation

Istio’s proxy is based on {{<gloss envoy>}}Envoy{{</gloss>}}, which is implemented as a user space daemon in the data plane that
interacts with the network layer using standard sockets. This gives it a large amount of flexibility in processing, and allows it to be
distributed (and upgraded!) in a container.

Network Policy data plane is typically implemented in kernel space (e.g. using iptables, eBPF filters, or even custom kernel modules). Being in kernel space
allows them to be extremely fast, but not as flexible as the Envoy proxy.

## Enforcement point

Policy enforcement using the Envoy proxy is implemented inside the pod, as a sidecar container in the same network namespace. This allows a simple deployment model. Some containers are given permission to reconfigure the networking inside their pod (`CAP_NET_ADMIN`).  If such a service instance is compromised, or misbehaves (as in a malicious tenant) the proxy can be bypassed.

While this won’t let an attacker access other Istio-enabled pods, so long as they are correctly configured, it opens several attack vectors:

- Attacking unprotected pods
- Attempting to deny service to protected pods by sending lots of traffic
- Exfiltrating data collected in the pod
- Attacking the cluster infrastructure (servers or Kubernetes services)
- Attacking services outside the mesh, like databases, storage arrays, or legacy systems.

Network Policy is typically enforced at the host node, outside the network namespace of the guest pods. This means that compromised or misbehaving pods must break into the root namespace to avoid enforcement. With the addition of egress policy due in Kubernetes 1.8, this difference makes Network Policy a key part of protecting your infrastructure from compromised workloads.

## Examples

Let’s walk through a few examples of what you might want to do with Kubernetes Network Policy for an Istio-enabled application.  Consider the Bookinfo sample application.  We’re going to cover the following use cases for Network Policy:

- Reduce attack surface of the application ingress
- Enforce fine-grained isolation within the application

### Reduce attack surface of the application ingress

Our application ingress controller is the main entry-point to our application from the outside world.  A quick peek at `istio.yaml` (used to install Istio) defines the Istio ingress like this:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: istio-ingress
  labels:
    istio: ingress
spec:
  type: LoadBalancer
  ports:
  - port: 80
    name: http
  - port: 443
    name: https
  selector:
    istio: ingress
{{< /text >}}

The `istio-ingress` exposes ports 80 and 443.  Let’s limit incoming traffic to just these two ports.  Envoy has a [built-in administrative interface](https://www.envoyproxy.io/docs/envoy/latest/operations/admin.html#operations-admin-interface), and we don’t want a misconfigured `istio-ingress` image to accidentally expose our admin interface to the outside world.  This is an example of defense in depth: a properly configured image should not expose the interface, and a properly configured Network Policy will prevent anyone from connecting to it.  Either can fail or be misconfigured and we are still protected.

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: istio-ingress-lockdown
  namespace: default
spec:
  podSelector:
    matchLabels:
      istio: ingress
  ingress:
  - ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
{{< /text >}}

### Enforce fine-grained isolation within the application

Here is the service graph for the Bookinfo application.

{{< image width="80%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="Bookinfo Service Graph"
    >}}

This graph shows every connection that a correctly functioning application should be allowed to make.  All other connections, say from the Istio Ingress directly to the Rating service, are not part of the application.  Let’s lock out those extraneous connections so they cannot be used by an attacker.  Imagine, for example, that the Ingress pod is compromised by an exploit that allows an attacker to run arbitrary code.  If we only allow connections to the Product Page pods using Network Policy, the attacker has gained no more access to my application backends _even though they have compromised a member of the service mesh_.

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: product-page-ingress
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: productpage
  ingress:
  - ports:
    - protocol: TCP
      port: 9080
    from:
    - podSelector:
        matchLabels:
          istio: ingress
{{< /text >}}

You can and should write a similar policy for each service to enforce which other pods are allowed to access each.

## Summary

Our take is that Istio and Network Policy have different strengths in applying policy. Istio is application-protocol aware and highly flexible, making it ideal for applying policy in support of operational goals, like service routing, retries, circuit-breaking, etc, and for security that operates at the application layer, such as token validation. Network Policy is universal, highly efficient, and isolated from the pods, making it ideal for applying policy in support of network security goals. Furthermore, having policy that operates at different layers of the network stack is a really good thing as it gives each layer specific context without commingling of state and allows separation of responsibility.

This post is based on the three part blog series by Spike Curtis, one of the Istio team members at Tigera.  The full series can be found here: <https://www.projectcalico.org/using-network-policy-in-concert-with-istio/>
