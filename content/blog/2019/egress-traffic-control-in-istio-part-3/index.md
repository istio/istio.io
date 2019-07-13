---
title: Secure Control of Egress Traffic in Istio, part 3
subtitle: Comparison with alternative solutions for control of egress and performance considerations
description: Comparison with alternative solutions for control of egress traffic and performance considerations.
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
Network Policies and legacy egress proxies and firewalls. Finally, I describe the performance considerations regarding the
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

Next, I'm going to cover two alternative solutions for egress traffic control, namely Kubernetes Network Policies and
egress proxies and firewalls, and show the requirements they satisfy, and, more importantly, the requirements they can't satisfy.

Kubernetes provides a native solution for traffic control, and in particular, for control of egress traffic, through the [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/).
Using these network policies, cluster operators can configure which pods can access specific external services.
Cluster operators can identify pods by pod labels, namespace labels, or by IP ranges. To specify the external services, cluster operators can use IP ranges, but cannot use domain names like `cnn.com`. This is because **Kubernetes network policies are not DNS-aware**.
The network policies satisfy the first requirement since they can control any TCP traffic.
Network policies only partially satisfy requirements 3 and 4 because cluster operators can specify policies
per cluster or per pod but operators can't identify external services by domain names.
Network policies only satisfy the fifth requirement if the attackers are not able to break from a malicious container into the Kubernetes
node and interfere with the implementation of the policies inside said node.
Lastly, network policies do satisfy the sixth requirement: Operators don't need to change the code or the
container environment. In summary, we can say that Kubernetes Network Policies provide transparent, Kubernetes-aware egress traffic
control, which is not DNS-aware.

The second alternative predates the Kubernetes network policies. Using a **DNS-aware egress proxy or firewall** lets you
configure applications to direct the traffic to the proxy and use some proxy protocol, for example,
[SOCKS](https://en.wikipedia.org/wiki/SOCKS).
Since the applications must be specially configured, this solution is not transparent. Moreover, egress proxies are not
Kubernetes-aware, since neither pod labels nor pod service account are known to the egress proxy. Such egress proxies
cannot fulfill the fourth requirement, that is they cannot enforce policies by source if the source is specified by a
Kubernetes artifact. The egress proxies can fulfill the first, second, third and fifth requirements,
but not the fourth and the six requirements.
They are DNS-aware, but not transparent and not Kubernetes-aware.

## Advantages of Istio egress traffic control

Istio egress traffic control is **DNS-aware**: you can define policies based on URLs or on wildcard domains like
`*.ibm.com`. In this sense, it is better than Kubernetes Network Policies which are not DNS-aware.

Istio egress traffic control is **transparent** with regard to TLS traffic, since Istio is transparent:
you do not need to change the applications or to configure their containers.
For HTTP traffic with TLS origination, you must configure the applications to use HTTP instead of HTTPS
when the applications run with Istio sidecars injected.

Istio egress traffic control is **Kubernetes-aware**: the identity of the source of egress traffic is based on
Kubernetes service accounts. Istio egress traffic control is better than the legacy DNS-aware proxies/firewalls which
are not transparent and not Kubernetes-aware.

Istio egress traffic control is **secure**: it is based on the strong identity of Istio and, when you
apply
[additional security measures](/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations),
it is tamper-proof.

On top of these beneficial features, Istio egress traffic control provides additional advantages:

*  It allows defining access policies in the same language for ingress, egress and in-cluster traffic. You
   need to learn a single policy and configuration language for all types of traffic.
*  Istio egress traffic control is integrated with Istio policy and telemetry adapters and can work out-of-the-box.
*  When you use external monitoring/access control systems with Istio, you must write the adapters for them only once,
   and then apply the adapters for all types of traffic: ingress, egress and in-cluster.
*  You can apply Istio traffic management features to egress traffic, such as
   load balancing, passive and active health checking, circuit breaker, timeouts, retries, fault injection, and others.

We call a system that has the advantages above **Istio-aware**.

Let me summarize the features of Istio egress traffic control and of the alternative solutions in the following table:

| | Kubernetes Network Policies | Legacy Egress Proxy/Firewall | Istio Egress Traffic Control |
| --- | --- | --- | ---|
| DNS-aware | {{< cancel_icon >}} | {{< checkmark_icon >}} | {{< checkmark_icon >}} |
| Kubernetes-aware | {{< checkmark_icon >}} | {{< cancel_icon >}} | {{< checkmark_icon >}} |
| Transparent | {{< checkmark_icon >}} | {{< cancel_icon >}} | {{< checkmark_icon >}} |
| Istio-aware | {{< cancel_icon >}} | {{< cancel_icon >}} | {{< checkmark_icon >}} |

## Performance considerations

Note that Istio egress control has its price, which is the increased latency of the calls to external services and
increase of CPU usage by the cluster pods.
After all, the traffic has to pass through two proxies, namely the sidecar proxy of the
application and the proxy of the egress gateway. In the case of
[TLS egress traffic to wildcard domains](/docs/tasks/traffic-management/egress/wildcard-egress-hosts/),
you have to add
[an additional proxy](/docs/tasks/traffic-management/egress/wildcard-egress-hosts/#wildcard-configuration-for-arbitrary-domains),
making the count of proxies between the application and the external service three. The traffic between the second and
third proxies is on the local network of the pod, so it should not have significant impact on the latency.

See a [performance evaluation](/blog/2019/egress-performance/) of different configurations of Istio egress
traffic control. I would encourage you to measure carefully different configurations for your own applications and your
external services, and decide whether you can afford the performance overhead for your use cases. You should weigh the
required level of security versus your performance requirements, and also compare with the performance overhead of
alternative solutions.

Let me provide our take on the performance overhead of Istio egress traffic control.
The latency of access to external services could be already high, so adding the overhead
of two or three proxies inside the cluster could be not very significant.
After all, in the microservice architecture you can have chains of dozens of calls between microservices, so adding an
additional hop with two proxies, the egress gateway, should not have a large impact.

Moreover, we are working to reduce
performance overhead of Istio, so I hope the overhead of egress traffic control in Istio will be reduced in the future.
Possible optimizations are to extend Envoy to handle wildcard domains so there will be no need for the
third proxy; or to use mutual TLS for authentication only without encrypting the TLS traffic (since it is already
encrypted).

## Summary

I hope that after reading this series you are convinced that controlling egress traffic is very important for the
security of your cluster.
I also hope that I managed to convince you that Istio can serve as an effective tool for controlling egress traffic
securely, and that Istio has multiple advantages over the alternative solutions.
In my opinion, you can even choose secure control of egress traffic as the first use case for applying Istio to your
cluster.
Istio will already be beneficial for you, even before you start using all other features, such as
traffic management, security, policies and telemetry, applied to traffic between microservices inside the cluster.
You should pay attention, however, to performance considerations of Istio egress traffic control and measure performance
overhead for your use cases.
