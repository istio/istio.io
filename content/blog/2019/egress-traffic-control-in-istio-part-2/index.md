---
title: Secure Control of Egress Traffic in Istio, part 2
subtitle: Use Istio Egress Traffic Control to prevent attacks involving egress traffic
description: Use Istio Egress Traffic Control to prevent attacks involving egress traffic.
publishdate: 2019-07-09
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,egress,security,gateway,tls]
---

Welcome to part 2 in our new series about secure control of egress traffic in Istio.
In [the first part in the series](/blog/2019/egress-traffic-control-in-istio-part-1/), I presented the attacks involving
egress traffic and the requirements we collected for a secure control system for egress traffic.
In this installment, I describe the Istio way to securely control the egress traffic, and show how Istio can help you
prevent the attacks.

## Secure control of egress traffic in Istio

To implement secure control of egress traffic in Istio, you must
[direct TLS traffic to external services through an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#egress-gateway-for-https-traffic).
Alternatively, you
can [direct HTTP traffic through an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#egress-gateway-for-http-traffic)
and [let the egress gateway perform TLS origination](/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/#perform-tls-origination-with-an-egress-gateway).

Both alternatives have their pros and cons, you should choose between them according to your circumstances.
The choice would mainly depend on the question if your application can send unencrypted HTTP requests and if your
organization's security policies allow sending unencrypted HTTP requests.
For example, if your application uses some client library that encrypts the traffic without a possibility to cancel the
encryption, you cannot use the option of sending unencrypted HTTP traffic.
The same in the case your organization's security policies do not allow sending unencrypted HTTP requests
**inside the pod** (outside the pod the traffic is encrypted by Istio).

If the application sends HTTP requests and the egress gateway performs TLS origination, you can monitor HTTP
information like HTTP methods, headers, and URL paths. You can also
[define policies](/blog/2018/egress-monitoring-access-control) based on said HTTP information. If the application
performs TLS origination, you can
[monitor SNI and the service account](/docs/tasks/traffic-management/egress/egress_sni_monitoring_and_policies/) of the
source pod's TLS traffic, and define policies based on SNI and service accounts.

You must ensure that traffic from your cluster to the outside cannot bypass the egress gateway. Istio cannot enforce it
for you, so you must apply some
[additional security mechanisms](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations),
for example,
the [Kubernetes network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) or an L3
firewall. See an example of the
[Kubernetes network policies configuration](/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies).
According to the [Defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) concept, the more
security mechanisms you apply for the same goal, the better.

You must also insure that Istio control plane and the egress gateway cannot be compromised. While you may have hundreds
or thousands of application pods in your cluster, there are only a dozen of control plane pods and the gateways.
You can and should focus on protecting the control planes pods and the gateways, since it is easy (there is a small
number of pods to protect) and it is most crucial for the security of your cluster.
If attackers compromise the control plane or the egress gateway, they could violate any policy.

You might have multiple tools to protect the control plane pods, depending on your environment.
The reasonable security measures are:

- Run the control plane pods on nodes separate from the application nodes.
- Run the control plane pods in their own separate namespace.
- Apply the Kubernetes RBAC and network policies to protect the control plane pods.
- Monitor the control plane pods more closely than you do the application pods.

Once you direct egress traffic through an egress gateway and apply the additional security mechanisms,
you can securely monitor and enforce security policies for the traffic.

The following diagram shows Istio's security architecture, augmented with an L3 firewall which is part of the
[additional security mechanisms](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)
that should be provided outside of Istio.

{{< image width="80%" link="./SecurityArchitectureWithL3Firewalls.svg" caption="Istio Security Architecture with Egress Gateway and L3 Firewall" >}}

You can configure the L3 firewall trivially to only allow incoming traffic through the Istio ingress gateway and
only allow outgoing traffic through the Istio egress gateway. The Istio proxies of the gateways enforce
policies and report telemetry just as all other proxies in the mesh do.

Now let's examine possible attacks and let me show you how the secure control of egress traffic in Istio prevents them.

## Preventing possible attacks

Consider the following security policies for egress traffic:

- Application **A** is allowed to access `*.ibm.com`, which includes all the external services with URLs matching
`*.ibm.com`.
- Application **B** is allowed to access `mongo1.composedb.com`.
- All egress traffic is monitored.

Suppose the attackers have the following goals:

- Access `*.ibm.com` from your cluster.
- Access `*.ibm.com` from your cluster, unmonitored. The attackers want their traffic to be unmonitored to prevent a
  possibility that you will detect the forbidden access.
- Access `mongo1.composedb.com` from your cluster.

Now suppose that the attackers manage to break into one of the pods of application **A**, and try to use the compromised
pod to perform the forbidden access. The attackers may try their luck and access the external services in a
straightforward way. You will react to the straightforward attempts as follows:

- Initially, there is no way to prevent a compromised application **A** to access `*.ibm.com`, because the compromised
  pod is able to access it indistinguishable from the original pod.
- Fortunately, you can monitor all access to external services, detect suspicious traffic, and thwart attackers from
  gaining unmonitored access to `*.ibm.com`. For example, you could apply anomaly detection tools on the
  egress traffic logs.
- To stop attackers from accessing `mongo1.composedb.com` from your cluster, Istio will correctly detect the source of
  the traffic, application **A** in this case, and verify that it is not allowed to access `mongo1.composedb.com`
  according to the security policies mentioned above.

Having failed to achieve their goals in a straightforward way, the malicious actors may resort to advanced attacks:

- **Bypass the container's sidecar proxy** to be able to access any external service directly, without the sidecar's
  policy enforcement and reporting. This attack is prevented by a Kubernetes Network Policy or by an L3 firewall that
  allow egress traffic to exit the mesh only from the egress gateway.
- **Compromise the egress gateway** to be able to force it to send fake information to the monitoring system or to
  disable enforcement of the security policies. This attack is prevented by applying the special security measures to
  the egress gateway pods.
- **Impersonate as application B** since application **B** is allowed to access `mongo1.composedb.com`. This attack,
  fortunately, is prevented by Istio's [strong identity support](/docs/concepts/security/#istio-identity).

## Summary

Hopefully, I managed to convince you that Istio is an effective tool to prevent attacks involving egress
traffic. In the next part of this series, I compare secure control of egress traffic in Istio with alternative
solutions such as
[Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) and legacy
egress proxies/firewalls.
