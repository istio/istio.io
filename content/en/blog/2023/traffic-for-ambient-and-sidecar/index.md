---
title: "Deep Dive into the Network Traffic Path of the Coexistence of Ambient and Sidecar"
description: "Deep Dive into the Traffic Path of the Coexistence of Ambient and Sidecar."
publishdate: 2023-09-15
attribution: "Steve Zhang (Intel), John Howard (Google), Yuxing Zeng(Alibaba)"
keywords: [traffic,ambient,sidecar,coexistence]
---

There are 2 modes for Istio: ambient and sidecar, the former is still on the way, the latter is the classic one. Therefore, the coexistence of Ambient and Sidecar should be a normal deployment form. That's the reason why this blog may be helpful for Istio users.

## Background

In the architecture of modern microservices, communication and management among services is critical. To address the challenge, Istio emerged as a service mesh technology. It provides traffic control, security, and superior observation capabilities by importing the sidecar. In order to further improve the adaptability and flexibility of Istio, the Istio community began to explore a new mode - ambient mode. In this mode, Istio no longer relies on explicit sidecar injection, but achieves communication and mesh management among services through ztunnel and waypoint proxies. Ambient also brings a series of improvements, such as lower resource consumption, simpler deployment, more flexible configuration options, and non-restarting for pods when enabling ambient, enabling Istio to play a better role in various scenarios.

There are many blogs to introduce and analyze ambient in community and technology forums, and this blog will analyze the network traffic path in Istio ambient and sidecar modes. We will analyze the network traffic path between services in these two modes.

In order to clarify the network traffic paths, this blog will explore two concrete scenarios with corresponding diagram to make it easier to understand. These two scenarios include:

- **The network path of services in ambient mode to services in sidecar mode**
- **The network path of service in Sidecar mode to service in Ambient mode**

_Note: The following analysis is based on Istio 1.18.2 which ambient only use iptables as the redirection mode._

## Ambient sleep to Sidecar httpbin

### Deployment and configuration for the first scenario

- sleep is deployed in namespace foo
    - sleep pod is scheduled to Node A
- httpbin is deployed in namespace bar
    - httpbin is scheduled to Node B
- foo namespace enables ambient mode (foo namespace contains label: `istio.io/dataplane-mode=ambient`)
- bar namespace enables sidecar injection (bar namespace contains label: `istio-injection: enabled`)

According to above description, the deployment and network traffic path are showing below:

{{< image width="100%"
    link="ambient-to-sidecar.png"
    caption="Ambient sleep to Sidecar httpbin"
    >}}

`ztunnel` will be deployed as DaemonSet in istio-system namespace if Ambient is enabled, meanwhile, the components of istio-cni and ztunnel would generate separately iptables rules and routes for both ztunnel pod and its node.

All network traffic coming in/out for the pod with Ambient enabled will go through ztunnel based on the network traffic hijacking mechanism. And ztunnel will handle L4 load balance, then forward the request traffic to correct endpoints.

### sleep -> ztunnel -> [ sidecar -> httpbin ] network traffic path

According to above diagram, the details of network traffic path is demonstrated as below:

**(1) (2) (3)**  Request traffic of service sleep is sent out from `veth` of the sleep pod, then it will be marked and forwarded to the `istioout` device in the node by following the iptables rules and route rules. The `istioout` device in the node A is a `[geneve](https://www.rfc-editor.org/rfc/rfc8926.html)` tunnel, and the other side of this tunnel is pair to `pistioout` device which is inside the ztunnel pod of node A.

**(4) (5)**  When the traffic arrives `pistioout` device, it goes on to be intercepted to the interface `eth0` of ztunnel pod on port 15001 by iptables rules inside the pod, so far the request traffic goes inside the ztunnel.

**(6)** According to the original request information, ztunnel can obtain the endpoint list of the target service, then it will handle L4 load balance strategy and send the request to one of the Endpoint, such as one of the httpbin pod. At last, the request traffic would get into the httpbin pod via the container network.

**(7)**  The request traffic arriving in httpbin pod will be intercepted to port 15006 of the sidecar by its iptables rules in Sidecar mode.

**(8)**  Sidecar will handle the inbound request traffic coming in via its port 15006, and forward the request traffic to httpbin container in the same pod.

## Sidecar sleep to Ambient httpbin and helloworld

### Deployment and configuration for the second scenario

- sleep is deployed in namespace foo
    - sleep pod is scheduled to Node A
- httpbin deployed in namespace bar-1
    - httpbin pod is scheduled to Node B
    - the waypoint proxy of httpbin is disable
- helloworld is deployed in namespace bar-2
    - helloworld pod is scheduled to Node D
    - the waypoint proxy of helloworld is enabled
    - the waypoint proxy is scheduled to Node C
- foo namespace enables sidecar injection (foo namespace contains label: `istio-injection: enabled`)
- bar-1 namespace enables ambient mode (bar-1 namespace contains label: `istio.io/dataplane-mode=ambient`)

According to above description, the deployment and network traffic path are showing below:

{{< image width="100%"
    link="sidecar-to-ambient.png"
    caption="sleep to httpbin and helloworld"
    >}}

### [ sleep -> sidecar ] -> ztunnel -> httpbin network traffic path

Based on the above deployment, the first part is showing on top half of the diagram: the network traffic path of sleep pod in Sidecar mode to httpbin pod in Ambient mode.

**(1) (2) (3) (4)** the sleep container sends a request to httpbin, the request is intercepted by iptables rules and directed to port 15001 on the sleep sidecar. Then, the sidecar handles the L7 load balancing and routing rules by following configurations distributed by the control plane. Next, the request traffic is forwarded to a specific httpbin pod in node B, identified by its concrete ip address.

**(5) (6)**  After the request is sent to the  device pair (`veth httpbin <-> eth0 inside httpbin pod`),  the request would be intercepted and forwarded to the `istioin` device in the node B where httpbin pod is running by following its iptables rules and route rules. The `istioin` device in the node B is a `[geneve](https://www.rfc-editor.org/rfc/rfc8926.html)` tunnel, and the other side of this tunnel is pair to `pistioin` device which is inside the ztunnel pod of node B.

**(7) (8)** After the request enters the `pistioin` device of the ztunnel pod, the request is intercepted to port 15008 of the ztunnel pod by the iptables rules of the ztunnel pod in node B.

**(9)** The traffic getting into the port 15008 would be considered as a inbound request, then ztunnel will forward the request to the httpbin pod in the same node B.

### [ sleep-> sidecar ] -> waypoint -> ztunnel -> helloworld httpbin network traffic path

Comparing with the first part of the diagram, it's clear that the waypoint proxy is added in path **"[ sleep -> sidecar ] -> ztunnel -> httpbin"**.

What's the background story?

The Istiod control plane has all information of service and configuration in the service mesh. When helloworld is configured with waypoint proxy, the EDS configuration of helloworld service received by sidecar of sleep pod will be changed to type of `envoy_internal_address`, this causes that the request traffic going through the internal of envoy will be forwarded to port 15008 of waypoint proxy in node C via `[HBONE](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit)` protocol.

Similar with sidecar, waypoint proxy is based on envoy and it will forward the request to helloworld pod based on envoy L7 routing strategy.

## Wrapping up

Sidecar mode is significant to make Istio as a great service mesh solution, however, it also causes some problems because app and sidecar container must be in a pod together. Istio implements communication among services through centralized proxies (ztunnel and waypoint). This mode provides greater flexibility and scalability, reduces resource consumption, and allows more precise configuration based on demand. Therefore,  it's no doubt that Ambient mode is the evolution of Istio. However, Ambient is currently in alpha stage and is still on the way, and Sidecar mode is still the recommendation installation of Istio, so the coexistence of Sidecar and Ambient may be last for a while before "All in Ambient".
