---
title: Istio as a transparent DNS-aware Kubernetes-aware Egress Firewall
subtitle: Secure Egress Traffic Control in Istio
publishdate: 2019-01-31
attribution: Vadim Eisenberg
weight: 70
---

In this blog post I describe how Istio can be used for secure egress traffic control. While the most important security
aspect for a service mesh is ingress traffic (preventing attackers to penetrate the cluster though the ingress APIs),
securing egress gateway is second in importance. The idea is that once our cluster is compromised (and we have to be
prepare for that scenario), we want to reduce the damage as much as possible and prevent the attackers from using the
cluster for further attacks on external services and legacy systems outside of the cluster. For that we need egress
traffic control.

Below I describe the Istio way for controlling egress traffic securely, and compare it with other solutions such as [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) and Legacy Proxy/Firewall.

## The attacks

Once the attackers are able to penetrate an application in the cluster, they can proceed to attack external services:
legacy systems, external web services and databases. The attackers may want to steal the data of the application and to
transfer it to their external servers. The attackers' malware may require access to attackers' servers to download
updates. The attackers may use the pods in the service mesh to perform DOS attacks.

The attackers can be external, i.e. can gain access to the application’s container from the outside, through a bug in
the application, or internal, i.e. a malicious DevOps person inside the organization.

## The solution: egress traffic control

To prevent the attacks described above, the egress traffic control must be applied. This means that all the egress
traffic must be monitored and security policies must be enforced. Let me present the requirements for egress traffic
control in the following section.

### The requirements for egress traffic control

We collected requirements for secure egress traffic control from several customers. All the requirements are implemented in Istio 1.1.

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
prevent attacks. Even if attackers would be able to access external services from the cluster, if the access is monitored, there is a chance to discover the suspicious traffic and take a corrective action.

Note that in case of TLS originated by the application, Istio sidecar proxies can only see TCP traffic and TLS handshake that includes SNI. The source of the traffic could be a pod, a service account of the pod or some other source identifier. We call this property of the egress control system as _being Kubernetes-aware_: the system must understand Kubernetes artifacts like pods and service accounts. If the system is not Kubernetes-aware, it can monitor only the IP address as the identifier of the source.

Requirement 3 states that the Istio operators must be able to define policies for egress traffic per whole cluster. The policies state which external services may be accessed by any pod in the cluster. The external services can be identified either by a [Fully qualified domain name](https://en.wikipedia.org/wiki/Fully_qualified_domain_name) of the service, e.g. `www.ibm.com` or by a wildcarded domain, e.g. `*.ibm.com`. Only the external services specified can be accessed, all other egress traffic must be blocked. We want to prevent attackers to access malicious sites, for example for downloading updates/instructions for their malware, and we want to limit the number of external sites that the attackers can access. We want to allow access only to the external services that applications in the cluster need to access and to block access to all the other services, this way reducing the attack vector. While the external services can have their own security mechanisms, we want to exercise [Defense in depth](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) and to add multiple security mechanisms, one in our cluster, and other ones in the external systems.

Note that the requirement must identify external services by domain names, we call this property of the egress control system as _being DNS-aware_. If the system is not DNS-aware, the external services must be specified by IP addresses, which is not convenient and often is not feasible, since IP addresses of a service can change or when they are not known, for example in case of [CDNs](https://en.wikipedia.org/wiki/Content_delivery_network).

Requirement 4 extends requirement 3, by adding source of the egress traffic to the policies: the policies should specify which source can access which external service. The source can be identified by pod or by service account of the pod, or by some label of the pod. Here the policy enforcement must also be _Kubernetes-aware_. If policy enforcement is not Kubernetes-aware, the policies must identify the source of traffic by the IP of the pod, which is not convenient, especially since the pods can come and go and their IPs are not static.

Requirement 5 states that even if the cluster is compromised and the attackers controls some of the pods, the attackers must not be able to cheat the monitoring or to break the policies of the egress control system. We say that such a system provides _secure_ egress traffic control.

Requirement 6 states that the control should be provided without changing the application containers, in particular without changing the code of the applications and without changing the environment of the containers. We call such an egress traffic control system _transparent_.

In this blog post I show that can serve Istio as an example of an egress traffic control system that satisfies all the requirements, in particular it is transparent, DNS-aware, and Kubernetes-aware.

### Existing solutions for egress traffic control

### Egress traffic control by Istio

## Further reading
