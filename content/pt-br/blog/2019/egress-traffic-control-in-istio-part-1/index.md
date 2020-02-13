---
title: Secure Control of Egress Traffic in Istio, part 1
subtitle: Attacks involving egress traffic and requirements for egress traffic control
description: Attacks involving egress traffic and requirements for egress traffic control.
publishdate: 2019-05-22
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,egress,security]
---

This is part 1 in a new series about secure control of egress traffic in Istio that I am going to publish.
In this installment, I explain why you should apply egress traffic control to your cluster, the attacks
involving egress traffic you want to prevent, and the requirements for a system for egress traffic control
to do so.
Once you agree that you should control the egress traffic coming from your cluster, the following questions arise:
What is required from a system for secure control of egress traffic? Which is the best solution to fulfill
these requirements? (spoiler: Istio in my opinion)
Future installments will describe
[the implementation of the secure control of egress traffic in Istio](/pt-br/blog/2019/egress-traffic-control-in-istio-part-2/)
and compare it with other solutions.

The most important security aspect for a service mesh is probably ingress traffic. You definitely must prevent attackers
from penetrating the cluster through ingress APIs. Having said that, securing
the traffic leaving the mesh is also very important. Once your cluster is compromised, and you must be
prepared for that scenario, you want to reduce the damage as much as possible and prevent the attackers from using the
cluster for further attacks on external services and legacy systems outside of the cluster. To achieve that goal,
you need secure control of egress traffic.

Compliance requirements are another reason to implement secure control of egress traffic. For example, the [Payment Card
Industry (PCI) Data Security Standard](https://www.pcisecuritystandards.org/pci_security/) requires that inbound
and outbound traffic must be restricted to that which is necessary:

{{< quote >}}
_1.2.1 Restrict inbound and outbound traffic to that which is necessary for the cardholder data environment, and specifically deny all other traffic._
{{< /quote >}}

And specifically regarding outbound traffic:

{{< quote >}}
_1.3.4 Do not allow unauthorized outbound traffic from the cardholder data environment to the Internet... All traffic outbound from the cardholder data environment should be evaluated to ensure that it follows established, authorized rules. Connections should be inspected to restrict traffic to only authorized communications (for example by restricting source/destination addresses/ports, and/or blocking of content)._
{{< /quote >}}

Let's start with the attacks that involve egress traffic.

## The attacks

An IT organization must assume it will be attacked if it hasn't been attacked already, and that
part of its infrastructure could already be compromised or become compromised in the future.
Once attackers are able to penetrate an application in a cluster, they can proceed to attack external services:
legacy systems, external web services and databases. The attackers may want to steal the data of the application and to
transfer it to their external servers. Attackers' malware may require access to attackers' servers to download
updates. The attackers may use pods in the cluster to perform DDOS attacks or to break into external systems.
Even though you [cannot know](https://en.wikipedia.org/wiki/There_are_known_knowns) all the possible types of
attacks, you want to reduce possibilities for any attacks, both for known and unknown ones.

The external attackers gain access to the application’s container from outside the mesh through a
bug in the application but attackers can also be internal, for example, malicious DevOps people inside the
organization.

To prevent the attacks described above, some form of egress traffic control must be applied. Let me present egress
traffic control in the following section.

## The solution: secure control of egress traffic

Secure control of egress traffic means monitoring the egress traffic and enforcing all the security policies regarding
the egress traffic.
Monitoring the egress traffic, enables you to analyze it, possibly offline, and detect the attacks even if
you were unable to prevent them in real time.
Another good practice to reduce possibilities of attacks is to specify policies that limit access following the
[Need to know](https://en.wikipedia.org/wiki/Need_to_know#In_computer_technology]) principle: only the applications that
need external services should be allowed to access the external services they need.

Let me now turn to the requirements for egress traffic control we collected.

## Requirements for egress traffic control

My colleagues at IBM and I collected requirements for secure control of egress traffic from several customers, and
combined them with the
[egress traffic control requirements from Kubernetes Network Special Interest Group](https://docs.google.com/document/d/1-Cq_Y-yuyNklvdnaZF9Qngl3xe0NnArT7Xt_Wno9beg).

Istio 1.1 satisfies all gathered requirements:

1.  Support for [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security) with
    [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) or for [TLS origination](/pt-br/docs/reference/glossary/#tls-origination) by Istio.

1.  **Monitor** SNI and the source workload of every egress access.

1.  Define and enforce **policies per cluster**, e.g.:

    * all applications in the cluster may access `service1.foo.com` (a specific host)

    * all applications in the cluster may access any host of the form `*.bar.com` (a wildcarded domain)

     All unspecified access must be blocked.

1.  Define and enforce **policies per source**, _Kubernetes-aware_:

    * application `A` may access `*.foo.com`.

    * application `B` may access `*.bar.com`.

    All other access must be blocked, in particular access of application `A` to `service1.bar.com`.

1.  **Prevent tampering**. In case an application pod is compromised, prevent the compromised pod from escaping
    monitoring, from sending fake information to the monitoring system, and from breaking the egress policies.

1.  Nice to have: traffic control is **transparent** to the applications.

Let me explain each requirement in more detail. The first requirement states that only TLS traffic to the external
services must be supported.
The requirement emerged upon observation that all the traffic that leaves the cluster must be encrypted.
This means that either the applications perform TLS origination or Istio must perform TLS origination
for them.
Note that in the case an application performs TLS origination, the Istio proxies cannot see the original traffic,
only the encrypted one, so the proxies see the TLS protocol only. For the proxies it does not matter if the original
protocol is HTTP or MongoDB, all the Istio proxies can see is TLS traffic.

The second requirement states that SNI and the source of the traffic must be monitored. Monitoring is the first step to
prevent attacks. Even if attackers would be able to access external services from the cluster, if the access is
monitored, there is a chance to discover the suspicious traffic and take a corrective action.

Note that in the case of TLS originated by an application, the Istio sidecar proxies can only see TCP traffic and a
TLS handshake that includes SNI.
A label of the source pod could identify the source of the traffic but a service account of the pod or some
other source identifier could be used. We call this property of an egress control system as _being Kubernetes-aware_:
the system must understand Kubernetes artifacts like pods and service accounts. If the system is not Kubernetes-aware,
it can only monitor the IP address as the identifier of the source.

The third requirement states that Istio operators must be able to define policies for egress traffic for the entire
cluster.
The policies state which external services may be accessed by any pod in the cluster. The external services can be
identified either by a [Fully qualified domain name](https://en.wikipedia.org/wiki/Fully_qualified_domain_name) of the
service, e.g. `www.ibm.com` or by a wildcarded domain, e.g. `*.ibm.com`. Only the specified external services may be
accessed, all other egress traffic is blocked.

This requirement originates from the need to prevent
attackers from accessing malicious sites, for example for downloading updates/instructions for their malware. You also
want to limit the number of external sites that the attackers can access and attack.
You want to allow access only to the external services that the applications in the cluster need to
access and to block access to all the other services, this way you reduce the
[attack surface](https://en.wikipedia.org/wiki/Attack_surface). While the external services
can have their own security mechanisms, you want to exercise [Defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) and to have multiple security layers: a security layer in your cluster in addition to
the security layers in the external systems.

This requirement means that the external services must be identifiable by domain names. We call this property
of an egress control system as _being DNS-aware_.
If the system is not DNS-aware, the external services must be specified by IP addresses.
Using IP addresses is not convenient and often is not feasible, since the IP addresses of a service can change. Sometimes
all the IP addresses of a service are not even known, for example in the case of
[CDNs](https://en.wikipedia.org/wiki/Content_delivery_network).

The fourth requirement states that the source of the egress traffic must be added to the policies effectively extending
the third requirement.
Policies can specify which source can access which external service and the source must be identified just as in the
second requirement, for example, by a label of the source pod or by service account of the pod.
It means that policy enforcement must also be _Kubernetes-aware_.
If policy enforcement is not Kubernetes-aware, the policies must identify the source of traffic by
the IP of the pod, which is not convenient, especially since the pods can come and go so their IPs are not static.

The fifth requirement states that even if the cluster is compromised and the attackers control some of the pods, they
must not be able to cheat the monitoring or to violate policies of the egress control system. We say that such a
system provides _secure_ control of egress traffic.

The sixth requirement states that the traffic control should be provided without changing the application containers, in
particular without changing the code of the applications and without changing the environment of the containers.
We call such a control of egress traffic _transparent_.

In the next posts I will show that Istio can function as an example of an egress traffic control system that satisfies
all of these requirements, in particular it is transparent, DNS-aware, and Kubernetes-aware.

## Summary

I hope that you are convinced that controlling egress traffic is important for the security of your cluster. In [the
part 2 of this series](/pt-br/blog/2019/egress-traffic-control-in-istio-part-2/) I describe the Istio way to perform secure
control of egress traffic. In
[the
part 3 of this series](/pt-br/blog/2019/egress-traffic-control-in-istio-part-3/) I compare it with alternative solutions such as
[Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) and legacy
egress proxies/firewalls.
