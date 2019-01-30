---
title: Istio as a transparent DNS-aware Kubernetes-aware Egress Firewall
subtitle: Secure Egress Traffic Control in Istio
publishdate: 2019-01-31
attribution: Vadim Eisenberg
weight: 70
keywords: [traffic-management,egress]
---

In this blog post I describe how Istio can be used for secure egress traffic control. While the most important security
aspect for a service mesh is ingress traffic (preventing attackers to penetrate the cluster though ingress APIs),
securing egress traffic is also very important. The idea is that once your cluster is compromised (and you must be
prepared for that scenario), you want to reduce the damage as much as possible and prevent the attackers from using the
cluster for further attacks on external services and legacy systems outside of the cluster. For that you need egress
traffic control.

Below I describe the Istio way for controlling egress traffic securely, and compare it with alternative solutions such as
[Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) and legacy
egress proxies/firewalls.

## The attacks

Once attackers are able to penetrate an application in a cluster, they can proceed to attack external services:
legacy systems, external web services and databases. The attackers may want to steal the data of the application and to
transfer it to their external servers. Attackers' malware may require access to attackers' servers to download
updates. The attackers may use pods in the cluster to perform DDOS attacks or to break into external systems.
Even though we cannot know all the possible types of the attacks, we want to reduce possibilities for the attacks, both
for known and unknown ones.

The attackers can be external, i.e. can gain access to the application’s container from the outside, through a bug in
the application, or internal, i.e. a malicious DevOps person inside the organization.

## The solution: egress traffic control

To prevent the attacks described above, the egress traffic control must be applied. This means that all the egress
traffic must be monitored and security policies must be enforced. You want to monitor every access to external services
to be able to detect the attacks, possibly offline, even if you fail to prevent them in real time. You want to specify
policies to limit access similar to the
[Need to know](https://en.wikipedia.org/wiki/Need_to_know#In_computer_technology]) principle: only the applications that
need to access external services should be allowed to access the external services they need.

Let me present requirements for egress traffic control in the following section.

## Requirements for egress traffic control

We collected requirements for secure egress traffic control from several customers, and also
[requirements from Kubernetes Network Special Interest Group](https://docs.google.com/document/d/1-Cq_Y-yuyNklvdnaZF9Qngl3xe0NnArT7Xt_Wno9beg).
All the requirements are implemented in Istio 1.1.

1. Support for **[TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security) with [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)** or for [TLS origination](/help/glossary/#tls-origination) by Istio.
1. **Monitor** all the egress access by SNI and the source workload
1. Define and enforce **policies per cluster**, e.g.:

   * all the applications in the cluster may access `service1.foo.com` (a specific host)
   * all the applications in the cluster may access any host of the form `*.bar.com` (a wildcard domain)

     All unspecified access must be blocked.

1. Define and enforce **policies per source**, _Kubernetes-aware_:

   * application `A` may access `*.foo.com`.
   * application `B` may access `*.bar.com`.

    All other access must be blocked, in particular access of application `A` to `service1.bar.com`.

1. **Prevent tampering**. In case an application pod is compromised, prevent the compromised pod from escaping monitoring,
from sending fake information to the monitoring system, and from breaking the egress policies.
1. Preferably: perform traffic control **transparently** to the applications

Let me explain each of the requirements. Requirement 1 states that only TLS traffic to the external services must be
supported. The requirement is based on the observation that all the traffic that leaves the cluster must be encrypted,
so either the applications will perform TLS origination or Istio must perform TLS origination
for them. Note that in case an application performs TLS origination, Istio's proxies cannot see the original traffic,
only the encrypted one, so the proxies see TLS protocol only. For the proxies it does not matter if the original
protocol is HTTP or MongoDB, all Istio proxies can see is TLS traffic.

Requirement 2 states that SNI and the source of the traffic must be monitored. Monitoring is the first step to
prevent attacks. Even if attackers would be able to access external services from the cluster, if the access is
monitored, there is a chance to discover the suspicious traffic and take a corrective action.

Note that in case of TLS originated by the application, Istio sidecar proxies can only see TCP traffic and TLS handshake
that includes SNI. The source of the traffic could be a label of the source pod, a service account of the pod or some
other source identifier. We call this property of the egress control system as _being Kubernetes-aware_: the system must
understand Kubernetes artifacts like pods and service accounts. If the system is not Kubernetes-aware, it can monitor
only the IP address as the identifier of the source.

Requirement 3 states that the Istio operators must be able to define policies for egress traffic per whole cluster. The
policies state which external services may be accessed by any pod in the cluster. The external services can be
identified either by a [Fully qualified domain name](https://en.wikipedia.org/wiki/Fully_qualified_domain_name) of the
service, e.g. `www.ibm.com` or by a wildcarded domain, e.g. `*.ibm.com`. Only the external services specified can be
accessed, all other egress traffic must be blocked. We want to prevent attackers to access malicious sites, for example
for downloading updates/instructions for their malware, and we want to limit the number of external sites that the
attackers can access. We want to allow access only to the external services that applications in the cluster need to
access and to block access to all the other services, this way reducing the attack vector. While the external services
can have their own security mechanisms, we want to exercise [Defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) and to add multiple security mechanisms, one in our cluster, and other ones in the
external systems.

Note that the requirement must identify external services by domain names, we call this property of the egress control
system as _being DNS-aware_. If the system is not DNS-aware, the external services must be specified by IP addresses,
which is not convenient and often is not feasible, since IP addresses of a service can change or when they are not
known, for example in case of [CDNs](https://en.wikipedia.org/wiki/Content_delivery_network).

Requirement 4 extends requirement 3, by adding source of the egress traffic to the policies: the policies should specify
which source can access which external service. The source must be identified as in the requirement 2, for example, by
a label of the source pod or by service account of the pod. Here the policy enforcement must also be
_Kubernetes-aware_. If policy enforcement is not Kubernetes-aware, the policies must identify the source of traffic by
the IP of the pod, which is not convenient, especially since the pods can come and go and their IPs are not static.

Requirement 5 states that even if the cluster is compromised and the attackers controls some of the pods, the attackers
must not be able to cheat the monitoring or to break the policies of the egress control system. We say that such a
system provides _secure_ egress traffic control.

Requirement 6 states that the control should be provided without changing the application containers, in particular
without changing the code of the applications and without changing the environment of the containers. We call such an
egress traffic control system _transparent_.

In this blog post I show that can serve Istio as an example of an egress traffic control system that satisfies all the
requirements, in particular it is transparent, DNS-aware, and Kubernetes-aware.

Let's examine solutions for egress traffic control other than Istio in the following section.

## Existing solutions for egress traffic control

The most natural solution for egress traffic control is
[Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/). Using
Kubernetes Network Policies, cluster operators can specify which external services can be accessed by which pods. The
pods can be identified by pod labels, namespace labels, or by IP ranges. The external services can be specified by IP
ranges - Kubernetes Network Policies are not DNS-aware. Requirement 1 is satisfied since any TCP traffic can be
controlled by Kubernetes Network policies. Requirements 3 and 4 are satisfied partially: the policies can be specified
per cluster or per pod, however the external services cannot be identified by domain names. The requirement 5 is
satisfied if the attackers are not able to break from a malicious container into the Kubernetes node and to interfere
with the kernel of the node. The requirement 6 is satisfied as well: there is no need to change the code or the
container environment. We can say that Kubernetes Network Policies provide transparent, Kubernetes-aware egress traffic
control, which is not DNS-aware.

Another approach that predates Kubernetes network policies is a **DNS-aware egress proxy** or firewall. In this
approach applications are configured to direct the traffic to the proxy and to use some proxy protocol, e.g.
[SOCKS](https://en.wikipedia.org/wiki/SOCKS).
Since the applications must be configured, this solution is not transparent. Moreover, egress proxies are not Kubernetes
aware, so the pod labels or pod namespace or pod service account are not known to the egress proxy. Such egress proxies
cannot fulfill requirement 4, i.e. they cannot enforce policies by source if the source is specified by a Kubernetes
artifact. The egress proxies can fulfill requirements 1, 2, 3 and 5, but not requirement 4 and 6. They are DNS-aware,
but not transparent and not Kubernetes-aware.

Let me explain Istio Egress Traffic control in the following section.

## Egress traffic control by Istio

To implement secure egress traffic control in Istio, you must
[direct TLS traffic to external services through an egress gateway](/docs/examples/advanced-gateways/egress-gateway/#egress-gateway-for-https-traffic).
(To support wildcard domains, you must create
[a custom version of an egress gateway](/docs/examples/advanced-gateways/wildcard-egress-hosts/)). Alternatively, you
can [direct HTTP traffic through an egress gateway](/docs/examples/advanced-gateways/egress-gateway/#egress-gateway-for-http-traffic) and [let the egress gateway perform TLS origination](/docs/examples/advanced-gateways/egress-gateway-tls-origination/#perform-tls-origination-with-an-egress-gateway).

In all the cases you have to apply some
[additional security mechanisms](/docs/examples/advanced-gateways/egress-gateway/#additional-security-considerations),
like Kubernetes Network Policies or an L3 firewall that will enforce that traffic from the cluster to the outside is
allowed for the egress gateway only. See
[an example for Kubernetes Network Policies configuration](/docs/examples/advanced-gateways/egress-gateway/#apply-kubernetes-network-policies).

You must also increase the security measures applied to Istio control plane and the
egress gateway by running them on nodes separate from the application nodes, in a separate namespace, monitoring them
more thoroughly, etc. After all, if the attackers are able to attack Istio Mixer or the egress gateway, they could
break any policy.

Once you directed egress traffic through an egress gateway and applied additional security mechanisms to the egress
gateway, you can securely monitor the traffic and define security policies on it.
If the application sends HTTP requests and the egress gateway performs TLS origination, you can monitor HTTP
information, e.g HTTP methods, headers and URL paths, and you can
[define policies](/blog/2018/egress-monitoring-access-control) based on the HTTP information. If the application
performs TLS origination, for TLS traffic you can
[monitor SNI and the service account](/docs/examples/advanced-gateways/egress_sni_monitoring_and_policies/) of the
source pod, and define policies based on them.

### Possible attacks and their prevention

Let's examine possible attacks and let me show you how the secure egress control in Istio prevents them. Consider the
following security policy with regard to egress traffic:

1. Application A is allowed to access `*.ibm.com` (all the external services with URL matching `*.ibm.com`,
  e.g. `www.ibm.com`)
1. Application B is allowed to access `mongo1.composedb.com`
1. All the egress traffic must be monitored

Now consider a scenario in which the application A (one of the pods) is compromised. Suppose the attackers have the
following goals:

1. Application A will try to access `*.ibm.com` unmonitored
1. Application A will try to access `mongo1.composedb.com`

Note that the application A is allowed to access `*.ibm.com`, so the attacker is able to access it. There is no way
to prevent such access since there is no way to distinguish, at least initially, between the original and the
compromised versions of the application A. However, you want to monitor any access to external services to be able to
detect suspicious traffic, for example by applying anomaly detection tools on logs of the egress traffic.
The attackers, on the contrary, want to access external services unmonitored, so the attack will not be detected.
Additional goal of the attackers is to access `mongo1.composedb.com`, which is forbidden for the application A. Istio
must enforce the policy that forbids access of application A to `mongo1.composedb.com` and must prevent the attack.

Now let's see which attacks the attackers will try to perform and how Istio secure egress traffic control will prevent
each kind of the attack.

1. **Bypass** Istio proxy and access the external services directly. This attack is prevented by a Kubernetes Network Policy
   or by L3 firewall that allows egress traffic exit the mesh through the egress gateway.
1. **Compromise** the egress gateway. This attack is prevented by applying special security measures to the egress gateway
   pod.
1. Since the previous attacks are prevented, the attackers have no other option but to direct the traffic through the
   egress gateway. The traffic will be monitored by the egress gateway, so the goal of the attackers to access the
   external services unmonitored cannot be achieved. The attackers may want to try to achieve their second goal, that is
   to access `mongo1.composedb.com`. To achieve it, they may try to **impersonate** as the application B since the
   application B is allowed to access `mongo1.composedb.com`. This attack, fortunately, is prevented by Istio's [strong
   identity support](/docs/concepts/security/#istio-identity).

### Advantages of Istio egress traffic control

Istio egress traffic control is **DNS-aware**: you can define policies based on URLs or on wildcard domains like
`*.ibm.com`. In this sense, it is superior to Kubernetes network policies which are not DNS-aware.

Istio egress traffic control is **transparent** for TLS traffic, as Istio as a whole: you do not need to change the
applications or to configure their containers. For HTTP traffic with TLS origination, the DevOps people must
configure the applications to use HTTP when deploying Istio.

Istio egress traffic control is **Kubernetes-aware**: the identity of the source of egress traffic is based on
Kubernetes service accounts. Istio egress traffic control is superior to legacy DNS-aware proxies/firewalls which
are not transparent and not Kubernetes-aware.

Istio egress traffic control is **secure**: it is based on the strong identity of Istio and when the cluster operators
provide additional security measures, it is tampering-proof.

On top of these beneficial features, Istio egress traffic control provides additional advantages:

*  It allows defining access policies in the same language for ingress/egress/in-cluster traffic. The cluster operators
   need to learn a single policy and configuration language for all the traffic.
*  Istio egress traffic control is integrated with Istio policy and telemetry adapters and can work out-of-the-box.
*  When external monitoring/access control systems are using with Istio, the adapters for them must be written only
   once, and then used for all kinds of the traffic, including egress traffic.
*  The Istio operators can apply Istio traffic management features to egress traffic, such as
   load balancing, passive and active health checking, circuit breaker, timeouts, retries, fault injection, and others.

I call a system with the advantages above as **Istio-aware**.

Let me summarize the features of Istio egress traffic control and of the alternative solutions in the following table:

| | Kubernetes Network Policies | Legacy Egress Proxy/Firewall | Istio Egress Traffic Control |
| --- | --- | --- | ---|
| DNS-aware | {{< cancel_icon >}} | {{< checkmark_icon >}} | {{< checkmark_icon >}} |
| Kubernetes-aware | {{< checkmark_icon >}} | {{< cancel_icon >}} | {{< checkmark_icon >}} |
| Transparent | {{< checkmark_icon >}} | {{< cancel_icon >}} | {{< checkmark_icon >}} |
| Istio-aware | {{< cancel_icon >}} | {{< cancel_icon >}} | {{< checkmark_icon >}} |
