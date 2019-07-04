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
In this installment, I describe the Istio way to securely control the egress traffic, and show how Istio can help you prevent such
attacks.

## Secure control of egress traffic in Istio

To implement secure egress traffic control in Istio, you must
[direct TLS traffic to external services through an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#egress-gateway-for-https-traffic).
(To support wildcard domains, you must create
[a custom version of an egress gateway](/docs/tasks/traffic-management/egress/wildcard-egress-hosts/)). Alternatively, you
can [direct HTTP traffic through an egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#egress-gateway-for-http-traffic)
and [let the egress gateway perform TLS origination](/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/#perform-tls-origination-with-an-egress-gateway).

In all cases you have to apply some
[additional security mechanisms](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations),
like [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) or an L3
firewall that will enforce that traffic from the cluster to the outside is allowed for the egress gateway only. See
[an example for Kubernetes Network Policies configuration](/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies).

You must also increase the security measures applied to the Istio control plane and the
- Run the Istio control plane services on separate nodes and a separate namespace from the application.
- Run the egress gateway on a separate node and a separate namespace from the application.
more thoroughly, etc. After all, if the attackers are able to attack Istio Mixer or the egress gateway, they could
violate any policy.

Once you direct egress traffic through an egress gateway and apply the additional security mechanisms,
you can securely monitor and define security policies for the traffic.
If the application sends HTTP requests and the egress gateway performs TLS origination, you can monitor HTTP
information, e.g. HTTP methods, headers and URL paths, and you can
[define policies](/blog/2018/egress-monitoring-access-control) based on the HTTP information. If the application
performs TLS origination, for TLS traffic you can
[monitor SNI and the service account](/docs/tasks/traffic-management/egress/egress_sni_monitoring_and_policies/) of the
source pod, and define policies based on them.

The following diagram shows Istio's security architecture, augmented with L3 firewall (part of the
[additional security mechanisms](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)
provided outside of Istio by the cluster/cloud provider).
The L3 firewall can have a trivial configuration that would allow incoming traffic into Istio ingress gateway pods only and
outgoing traffic from Istio egress gateway pods only. Note that the Istio proxy of the egress gateway performs
policy enforcement and reporting in the same way as the sidecar proxies in the application pods.

{{< image width="80%" link="./SecurityArchitectureWithL3Firewalls.svg" caption="Istio Security Architecture with Egress Gateway and L3 Firewall" >}}

Now let's examine possible attacks and let me show you how the secure control of egress traffic in Istio prevents them.

## Preventing possible attacks

Consider the following security policy with regard to egress traffic:

1. Application A is allowed to access `*.ibm.com` (all the external services with URL matching `*.ibm.com`,
  e.g. `www.ibm.com`)
1. Application B is allowed to access `mongo1.composedb.com`
1. All egress traffic must be monitored

Now consider a scenario in which one of application A's pods is compromised. Suppose the attackers have the
following goals:

1. Application A will try to access `*.ibm.com` unmonitored
1. Application A will try to access `mongo1.composedb.com`

Note that application A is allowed to access `*.ibm.com`, so the attacker is able to access it. There is no way
to prevent such access since there is no way to distinguish, at least initially, between the original and the
compromised versions of application A. However, you want to monitor any access to external services to be able to
detect suspicious traffic, for example by applying anomaly detection tools on logs of the egress traffic.
The attackers, on the contrary, want to access external services unmonitored, so the attack will not be detected.
The second goal of the attackers is to access `mongo1.composedb.com`, which is forbidden for application A. Istio
must enforce the policy that forbids access of application A to `mongo1.composedb.com` and must prevent the attack.

Now let's see which attacks the attackers will try to perform to achieve their goals and how Istio secure egress traffic
control will prevent each kind of attack. The attackers may try to:

1. **Bypass** the container's sidecar proxy and access external services directly. This attack is prevented by a
   Kubernetes Network Policy or by an L3 firewall that allow egress traffic to exit the mesh only from the egress
   gateway.
1. **Compromise** the egress gateway and force it to send fake information to the monitoring system or to disable
   enforcement of the security policies.
   This attack is prevented by applying the special security measures to the egress gateway pods.
1. Since the previous attacks are prevented, the attackers have no other option but to direct the traffic through the
   egress gateway. The traffic will be monitored by the egress gateway, so the goal of the attackers to access
   external services unmonitored cannot be achieved. The attackers may want to try to achieve their second goal, that is
   to access `mongo1.composedb.com`. To achieve it, they may try to **impersonate** as application B since
   application B is allowed to access `mongo1.composedb.com`. This attack, fortunately, is prevented by Istio's [strong
   identity support](/docs/concepts/security/#istio-identity).

## Summary

I hope that I managed to convince you that Istio can serve as an effective tool for preventing attacks involving egress
traffic. In the next blog post in this series I compare control of egress traffic in Istio with alternative
solutions such as
[Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) and legacy
egress proxies/firewalls.
