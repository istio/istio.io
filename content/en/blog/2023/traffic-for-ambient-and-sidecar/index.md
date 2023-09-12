---
title: "Deep Dive into the Network Traffic Path of the Coexistence of Ambient and Sidecar"
description: "Deep Dive into the Traffic Path of the Coexistence of Ambient and Sidecar."
publishdate: 2023-09-15
attribution: "Steve Zhang (Intel), John Howard (Google), Yuxing Zeng(Alibaba)"
keywords: [traffic,ambient,sidecar,coexistence]
---

There are 2 modes for Istio: ambient and sidecar. The former is still on the way, the latter is the classic one. Therefore, the coexistence of ambient and sidecar should be a normal deployment form and the reason why this blog may be helpful for Istio users.

## Background

In the architecture of modern microservices, communication and management among services is critical. To address the challenge, Istio emerged as a service mesh technology. It provides traffic control, security, and superior observation capabilities by importing the sidecar. In order to further improve the adaptability and flexibility of Istio, the Istio community began to explore a new mode - ambient mode. In this mode, Istio no longer relies on explicit sidecar injection, but achieves communication and mesh management among services through ztunnel and waypoint proxies. Ambient also brings a series of improvements, such as lower resource consumption, simpler deployment, more flexible configuration options, and non-restarting for pods when enabling ambient, enabling Istio to play a better role in various scenarios.

There are many blogs to introduce and analyze ambient in community and technology forums, and this blog will analyze the network traffic path in Istio ambient and sidecar modes. We will analyze the network traffic path between services in these two modes.

In order to clarify the network traffic paths, this blog will explore two concrete scenarios with corresponding diagram to make it easier to understand. These two scenarios include:

- **The network path of services in ambient mode to services in sidecar mode**
- **The network path of services in sidecar mode to services in ambient mode**

_Note 1: The following analysis is based on Istio 1.18.2, where ambient mode uses iptables for redirection._

_Note 2: The communications between sidecar and ztunnel/waypoint proxy uses `[HTTP Based Overlay Network (HBONE)](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit)`._

## Ambient sleep to sidecar httpbin

### Deployment and configuration for the first scenario

- sleep is deployed in namespace foo
    - sleep pod is scheduled to Node A
- httpbin is deployed in namespace bar
    - httpbin is scheduled to Node B
- foo namespace enables ambient mode (foo namespace contains label: `istio.io/dataplane-mode=ambient`)
- bar namespace enables sidecar injection (bar namespace contains label: `istio-injection: enabled`)

With the above description, the deployment and network traffic paths are:

{{< image width="100%"
    link="ambient-to-sidecar.png"
    caption="Ambient sleep to Sidecar httpbin"
    >}}

ztunnel will be deployed as a DaemonSet in istio-system namespace if ambient is enabled, while istio-cni and ztunnel would generate iptables rules and routes for both the ztunnel pod and pods on each node.

All network traffic coming in/out of the pod with ambient enabled will go through ztunnel based on the network redirection logic. The ztunnel will then forward the traffic to the correct endpoints.

### sleep -> ztunnel -> [ sidecar -> httpbin ] network traffic path

According to above diagram, the details of network traffic path is demonstrated as below:

**(1) (2) (3)**  Request traffic of the sleep service is sent out from the `veth` of the sleep pod where it will be marked and forwarded to the `istioout` device in the node by following the iptables rules and route rules. The `istioout` device in the node A is a `[geneve](https://www.rfc-editor.org/rfc/rfc8926.html)` tunnel, and the other end of the tunnel is `pistioout`, which is inside the ztunnel pod on the same node.

**(4) (5)**  When the traffic arrives through the `pistioout` device, it will be intercepted and redirected through the interface `eth0` of the ztunnel pod on port 15001 by iptables rules inside the pod.

**(6)** According to the original request information, ztunnel can obtain the endpoint list of the target service.  It will then handle sending the request to the endpoint, such as one of the httpbin pods. At last, the request traffic would get into the httpbin pod via the container network.

**(7)**  The request traffic arriving in httpbin pod will be intercepted and redirected through port 15006 of the sidecar by its iptables rules.

**(8)**  Sidecar will handle the inbound request traffic coming in via port 15006, and forward the traffic to the httpbin container in the same pod.

## Sidecar sleep to ambient httpbin and helloworld

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

With the above description, the deployment and network traffic paths are:

{{< image width="100%"
    link="sidecar-to-ambient.png"
    caption="sleep to httpbin and helloworld"
    >}}

### [ sleep -> sidecar ] -> ztunnel -> httpbin network traffic path

Based on the above deployment, the first part is shown on top half of the diagram: the network traffic path of the sleep pod in sidecar mode to the httpbin pod in ambient mode.

**(1) (2) (3) (4)** the sleep container sends a request to httpbin. The request is intercepted by iptables rules and directed to port 15001 of the sleep pod sidecar. Then, the sidecar handles the request and routing rules by following configurations distributed by the control plane. Next, the request traffic is forwarded to a specific httpbin pod in node B, identified by its ip address.

**(5) (6)**  After the request is sent to the device pair (`veth httpbin <-> eth0 inside httpbin pod`), the request would be intercepted and forwarded to the `istioin` device on the node B where httpbin pod is running by following its iptables and route rules. The `istioin` device in the node B is a `[geneve](https://www.rfc-editor.org/rfc/rfc8926.html)` tunnel, and the other side of this tunnel is `pistioin` device which is inside the ztunnel pod of node B.

**(7) (8)** After the request enters the `pistioin` device of the ztunnel pod, the request is intercepted and redirected through port 15008 of the ztunnel pod by the iptables rules of the ztunnel pod on node B.

**(9)** The traffic getting into the port 15008 would be considered as a inbound request, then ztunnel will forward the request to the httpbin pod in the same node B.

### [ sleep-> sidecar ] -> waypoint -> ztunnel -> helloworld httpbin network traffic path

Comparing with the first part of the diagram, it's clear that the waypoint proxy is added in path **"[ sleep -> sidecar ] -> ztunnel -> httpbin"**. The Istio control plane has all information of service and configuration of the service mesh. When helloworld is configured with a waypoint proxy, the EDS configuration of helloworld service received by sidecar of sleep pod will be changed to the type of `envoy_internal_address`. This causes that the request traffic going through the sidecar to be forwarded to port 15008 of the waypoint proxy on node C via the `[HBONE](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit)` protocol.

Similar to sidecar, waypoint proxy is based on envoy and it will forward the request to the helloworld pod based on envoy L7 routing strategy.

## Wrapping up

Sidecar mode is significant to make Istio a great service mesh solution. However, it also causes some problems because app and sidecar containers must be in a pod together. Istio ambient mode implements communication among services through centralized proxies (ztunnel and waypoint). This mode provides greater flexibility and scalability, reduces resource consumption through not needing a sidecar for each pod in the mesh, and allows more precise configuration. Therefore, it's no doubt that ambient mode is the next evolution of Istio. Currently, ambient is still alpha and sidecar mode is still the recommended mode of Istio. The coexistence of sidecar and ambient modes may be last for a while before we're "all in ambient".
