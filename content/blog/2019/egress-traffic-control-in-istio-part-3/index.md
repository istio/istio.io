---
title: Secure Control of Egress Traffic in Istio, part 3
subtitle: Comparison of alternative solutions to control egress traffic including performance considerations
description: Comparison of alternative solutions to control egress traffic including performance considerations.
publishdate: 2019-07-16
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,egress,security,gateway,tls]
---

Welcome to part 3 in our series about secure control of egress traffic in Istio.
In [the first part in the series](/blog/2019/egress-traffic-control-in-istio-part-1/), I presented the attacks involving
egress traffic and the requirements we collected for a secure control system for egress traffic.
In [the second part in the series](/blog/2019/egress-traffic-control-in-istio-part-2/), I presented the Istio way of
securing egress traffic and showed how you can prevent the attacks using Istio.

In this installment, I compare secure control of egress traffic in Istio with alternative solutions such as using Kubernetes
network policies and legacy egress proxies and firewalls. Finally, I describe the performance considerations regarding the
secure control of egress traffic in Istio.

## Alternative solutions for egress traffic control

First, let's remember the [requirements for egress traffic control](/blog/2019/egress-traffic-control-in-istio-part-1/#requirements-for-egress-traffic-control) we previously collected:

1.  Support of [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security) with
    [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) or of [TLS origination](/docs/reference/glossary/#tls-origination).
1.  **Monitor** SNI and the source workload of every egress access.
1.  Define and enforce **policies per cluster**.
1.  Define and enforce **policies per source**, _Kubernetes-aware_.
1.  **Prevent tampering**.
1.  Traffic control is **transparent** to the applications.

Next, I'm going to cover two alternative solutions for egress traffic control: the Kubernetes network policies and
egress proxies and firewalls. I show the requirements they satisfy, and, more importantly, the requirements they can't satisfy.

Kubernetes provides a native solution for traffic control, and in particular, for control of egress traffic, through the [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/).
Using these network policies, cluster operators can configure which pods can access specific external services.
Cluster operators can identify pods by pod labels, namespace labels, or by IP ranges. To specify the external services, cluster operators can use IP ranges, but cannot use domain names like `cnn.com`. This is because **Kubernetes network policies are not DNS-aware**.
The network policies satisfy the first requirement since they can control any TCP traffic.
Network policies only partially satisfy the third and the fourth requirements because cluster operators can specify policies
per cluster or per pod but operators can't identify external services by domain names.
Network policies only satisfy the fifth requirement if the attackers are not able to break from a malicious container into the Kubernetes
node and interfere with the implementation of the policies inside said node.
Lastly, network policies do satisfy the sixth requirement: Operators don't need to change the code or the
container environment. In summary, we can say that Kubernetes Network Policies provide transparent, Kubernetes-aware egress traffic
control, which is not DNS-aware.

The second alternative predates the Kubernetes network policies. Using a **DNS-aware egress proxy or firewall** lets you
configure applications to direct the traffic to the proxy and use some proxy protocol, for example,
[SOCKS](https://en.wikipedia.org/wiki/SOCKS).
Since operators must configure the applications, this solution is not transparent. Moreover, operators can't use
pod labels or pod service accounts to configure the proxies because the egress proxies don't know about them. Therefore, **the egress proxies are not Kubernetes-aware** and can't fulfill the fourth requirement because
egress proxies cannot enforce policies by source if a Kubernetes artifact specifies the source.
In summary, egress proxies can fulfill the first, second, third and fifth requirements, but can't satisfy the fourth and
the six requirements because they are not transparent and not Kubernetes-aware.

## Advantages of Istio egress traffic control

Istio egress traffic control is **DNS-aware**: you can define policies based on URLs or on wildcard domains like
`*.ibm.com`. In this sense, it is better than Kubernetes network policies which are not DNS-aware.

Istio egress traffic control is **transparent** with regard to TLS traffic, since Istio is transparent:
you don't need to change the applications or configure their containers.
For HTTP traffic with TLS origination, you must configure the applications in the mesh to use HTTP instead of HTTPS.

Istio egress traffic control is **Kubernetes-aware**: the identity of the source of egress traffic is based on
Kubernetes service accounts. Istio egress traffic control is better than the legacy DNS-aware proxies or firewalls which
are not transparent and not Kubernetes-aware.

Istio egress traffic control is **secure**: it is based on the strong identity of Istio and, when you
apply
[additional security measures](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations),
Istio's traffic control is resilient to tampering.

Additionally, Istio's egress traffic control provides the following advantages:

-  Define access policies in the same language for ingress, egress, and in-cluster traffic. You
   need to learn a single policy and configuration language for all types of traffic.
-  Out-of-the-Box integration of Istio's egress traffic control with Istio's policy and telemetry adapters.
-  Write the adapters to use external monitoring or access control systems with Istio only once and
   and apply them for all types of traffic: ingress, egress, and in-cluster.
-  Use Istio's [traffic management features](/docs/concepts/traffic-management/) for egress traffic:
   load balancing, passive and active health checking, circuit breaker, timeouts, retries, fault injection, and others.

We refer to a system with the advantages above as **Istio-aware**.

The following table summarizes the egress traffic control features that Istio and the alternative solutions provide:

| | Istio Egress Traffic Control | Kubernetes Network Policies | Legacy Egress Proxy or Firewall |
| --- | --- | --- | ---|
| DNS-aware | {{< checkmark_icon >}} | {{< cancel_icon >}} | {{< checkmark_icon >}} |
| Kubernetes-aware | {{< checkmark_icon >}} | {{< checkmark_icon >}} | {{< cancel_icon >}} | {
| Transparent | {{< checkmark_icon >}} | {{< checkmark_icon >}} | {{< cancel_icon >}} |
| Istio-aware | {{< checkmark_icon >}} | {{< cancel_icon >}} | {{< cancel_icon >}} |

## Performance considerations

Controlling egress traffic using Istio has a price: increased latency of calls to external services and
increased CPU usage by the cluster's pods.
Traffic passes through two proxies:

- The application's sidecar proxy
- The egress gateway's proxy

If you use [TLS egress traffic to wildcard domains](/docs/tasks/traffic-management/egress/wildcard-egress-hosts/),
you must add
[an additional proxy](/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains),
adding a third proxy between the application and the external service. Since the traffic between the egress gateway's proxy and
the proxy needed for the configuration of arbitrary domains using wildcards is on the pod's local
network, that traffic shouldn't have a significant impact on latency.

See a [performance evaluation](/blog/2019/egress-performance/) of different Istio configurations set to control egress
traffic. I would encourage you to carefully measure different configurations with your own applications and your own
external services, before you decide whether you can afford the performance overhead for your use cases. You should weigh the
required level of security versus your performance requirements and compare the performance overhead of all
alternative solutions.

Let me share my thoughts on the performance overhead that controlling egress traffic using Istio adds:
Accessing external services already could have high latency and the overhead added
because of two or three proxies inside the cluster could likely not be very significant by comparison.
After all, applications with a microservice architecture can have chains of dozens of calls between microservices.
Therefore, an additional hop with one or two proxies in the egress gateway should not have a large impact.

Moreover, we continue to work towards reducing Istio's performance overhead.
Possible optimizations include:

- Extending Envoy to handle wildcard domains: This would eliminate the need for a third proxy between
  the application and the external services for that use case.
- Using mutual TLS for authentication only without encrypting the TLS traffic, since the traffic is already
  encrypted.

## Summary

I hope that after reading this series you are convinced that controlling egress traffic is very important for the
security of your cluster.
Hopefully, I also managed to convince you that Istio is an effective tool to control egress traffic
securely, and that Istio has multiple advantages over the alternative solutions.
In my opinion, secure control of egress traffic is a great choice if you are looking for your first Istio use case.
In this case, Istio already provides you some benefits even before you start using all other Istio features:
[traffic management](/docs/tasks/traffic-management/), [security](/docs/tasks/security/),
[policies](/docs/tasks/policy-enforcement/) and [telemetry](/docs/tasks/telemetry/), applied to traffic between microservices inside the cluster.
