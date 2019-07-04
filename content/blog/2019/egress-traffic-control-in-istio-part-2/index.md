---
title: Secure Control of Egress Traffic in Istio, part 2
subtitle: Use Istio Egress Traffic Control to prevent attacks involving egress traffic
description: Use Istio Egress Traffic Control to prevent attacks involving egress traffic.
publishdate: 2019-05-29
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,egress,security,gateway,tls]
---

Welcome to part 2 in our new series about secure control of egress traffic in Istio.
In [the first part in the series](/blog/2019/egress-traffic-control-in-istio-part-1/), I presented the attacks involving
egress traffic and the requirements we collected for a secure control system for egress traffic.
In this installment, I describe the Istio way to securely control the egress traffic, and show how Istio can help you
prevent the attacks.

## Secure control of egress traffic in Istio

To implement secure egress traffic control in Istio, you must
[direct TLS traffic to external services through an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#egress-gateway-for-https-traffic).
Alternatively, you
can [direct HTTP traffic through an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#egress-gateway-for-http-traffic)
and [let the egress gateway perform TLS origination](/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/#perform-tls-origination-with-an-egress-gateway).

Both alternatives have their pros and cons, you should choose between them according to your circumstances. The choice would mainly depend on the question if your application can send unencrypted HTTP requests and if your organization's security policies allow sending unencrypted HTTP requests. For example, if your application uses some client library that encrypts the traffic without a possibility to cancel the encryption, you cannot use the option of sending HTTP traffic. The same in the case your organization's security policies do not allow sending unencrypted HTTP requests **inside the pod** (outside the pod the traffic is encrypted by Istio).

If the application sends HTTP requests and the egress gateway performs TLS origination, you can monitor HTTP
information like HTTP methods, headers, and URL paths. You can also
[define policies](/blog/2018/egress-monitoring-access-control) based on said HTTP information. If the application
performs TLS origination, you can
[monitor SNI and the service account](/docs/tasks/traffic-management/egress/egress_sni_monitoring_and_policies/) of the
source pod's TLS traffic, and define policies based on SNI and service accounts.

In all cases you have to apply some
[additional security mechanisms](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations),
like [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) or an L3
firewall that will enforce that traffic from the cluster to the outside is allowed for the egress gateway only. See
[an example for Kubernetes Network Policies configuration](/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies).

You must also increase the security measures applied to the Istio control plane pods and the egress gateway, for example:

* run them on nodes separate from the application nodes
* run them in a separate namespace
* apply Kubernetes RBAC and Network policies to protect them
* monitor them more thoroughly and more frequently than the application pods

After all, if the attackers are able to attack Istio Mixer or the egress gateway, they could
violate any policy.

Once you direct egress traffic through an egress gateway and apply the additional security mechanisms,
you can securely monitor and define security policies for the traffic.

The following diagram shows Istio's security architecture, augmented with an L3 firewall which is part of the
[additional security mechanisms](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)
that should be provided outside of Istio.

{{< image width="80%" link="./SecurityArchitectureWithL3Firewalls.svg" caption="Istio Security Architecture with Egress Gateway and L3 Firewall" >}}

You can configure the L3 firewall trivially to only allow incoming traffic through the Istio ingress gateway and
only allow outgoing traffic through the Istio egress gateway. The Istio proxies of the gateways enforce policies and report telemetry as all other proxies in the mesh.

Now let's examine possible attacks and let me show you how the secure control of egress traffic in Istio prevents them.

## Preventing possible attacks

Consider the following security policies for egress traffic:

* Application **A** is allowed to access `*.ibm.com`, which includes all the external services with URLs matching `*.ibm.com`.
* Application **B** is allowed to access `mongo1.composedb.com`.
* All egress traffic is monitored.

In the scenario that one pod of application **A** is compromised, suppose the attackers have the
following goals:

1. Application **A** will try to access `*.ibm.com`
1. Application **A** will try to access `*.ibm.com` undetected
1. Application **A** will try to access `mongo1.composedb.com`

First, let's see which attacker's goals you can thwart. Since application **A** is allowed to access `*.ibm.com`, the
attacker is able to access it. There is no way to prevent such access since there is no way to distinguish, at least
initially, between the original and the compromised versions of application **A**. Fortunately, if you can monitor all
access to external services, you could detect suspicious traffic and thwart the second goal of the attackers.
For example, you could apply anomaly detection tools on the egress traffic logs. The attackers, on the contrary, want to
access external services unmonitored, so the attack will not be detected. You can thwart the third goal if you can
correctly detect the source of the traffic, in this case, application **A**, and check that it is not allowed to access
the destination, `mongo1.composedb.com`, according to the security policies mentioned above.

Now, let's see which attacks malicious actors could attempt to achieve their goals and how secure control of egress
traffic in Istio will prevent each kind of attack. The attackers may try to:

1. **Bypass** the container's sidecar proxy and access external services directly. This attack is prevented by a
   Kubernetes Network Policy or by an L3 firewall that allow egress traffic to exit the mesh only from the egress
   gateway.
1. **Compromise** the egress gateway and force it to send fake information to the monitoring system or to disable
   enforcement of the security policies.
   This attack is prevented by applying the special security measures to the egress gateway pods.
1. Since the previous attacks are prevented, the attackers have no other option but to direct the traffic through the
   egress gateway. The traffic will be monitored by the egress gateway, so the goal of the attackers to access
   external services unmonitored cannot be achieved. The attackers may want to try to achieve their second goal, that is
   to access `mongo1.composedb.com`. To achieve it, they may try to **impersonate** as application **B** since
   application **B** is allowed to access `mongo1.composedb.com`. This attack, fortunately, is prevented by Istio's [strong
   identity support](/docs/concepts/security/#istio-identity).

## Summary

Hopefully, I managed to convince you that Istio is an effective tool to prevent attacks involving egress
traffic. In the next part of this series, I compare secure control of egress traffic in Istio with alternative
solutions such as
[Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) and legacy
egress proxies/firewalls.
