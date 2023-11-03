---
title: "Deep Dive into the Network Traffic Path of the Coexistence of Ambient and Sidecar"
description: "Deep Dive into the Traffic Path of the Coexistence of Ambient and Sidecar."
publishdate: 2023-09-18
attribution: "Steve Zhang (Intel), John Howard (Google), Yuxing Zeng(Alibaba), Peter Jausovec(Solo.io)"
keywords: [traffic,ambient,sidecar,coexistence]
---

There are 2 deployment modes for Istio: ambient mode and sidecar mode. The former is still on the way, the latter is the classic one. Therefore, the coexistence of ambient mode and sidecar mode should be a normal deployment form and the reason why this blog may be helpful for Istio users.

## Background

In the architecture of modern microservices, communication and management among services is critical. To address the challenge, Istio emerged as a service mesh technology. It provides traffic control, security, and superior observation capabilities by utilizing the sidecar. In order to further improve the adaptability and flexibility of Istio, the Istio community began to explore a new mode - ambient mode. In this mode, Istio no longer relies on explicit sidecar injection, but achieves communication and mesh management among services through ztunnel and waypoint proxies. Ambient also brings a series of improvements, such as lower resource consumption, simpler deployment, and more flexible configuration options. When enabling ambient mode, we don't have to restart pods anymore which enables Istio to play a better role in various scenarios.

There are many blogs, which can be found in the [Reference Resources](#reference-resources) section of this blog, that introduce and analyze ambient, and this blog will analyze the network traffic path in Istio ambient and sidecar modes.

To clarify the network traffic paths and make it easier to understand, this blog post explores the following two scenarios with corresponding diagrams:

- **The network path of services in ambient mode to services in sidecar mode**
- **The network path of services in sidecar mode to services in ambient mode**

## Information about the analysis

The analysis is based on Istio 1.18.2, where ambient mode uses iptables for redirection.

## Ambient mode `sleep` to sidecar mode `httpbin`

### Deployment and configuration for the first scenario

- `sleep` is deployed in namespace foo
    - `sleep` pod is scheduled to Node A
- `httpbin` is deployed in namespace bar
    - `httpbin` is scheduled to Node B
- foo namespace enables ambient mode (foo namespace contains label: `istio.io/dataplane-mode=ambient`)
- bar namespace enables sidecar injection (bar namespace contains label: `istio-injection: enabled`)

With the above description, the deployment and network traffic paths are:

{{< image width="100%"
    link="ambient-to-sidecar.png"
    caption="Ambient mode sleep to Sidecar mode httpbin"
    >}}

ztunnel will be deployed as a DaemonSet in istio-system namespace if ambient mode is enabled, while istio-cni and ztunnel would generate iptables rules and routes for both the ztunnel pod and pods on each node.

All network traffic coming in/out of the pod with ambient mode enabled will go through ztunnel based on the network redirection logic. The ztunnel will then forward the traffic to the correct endpoints.

### Network traffic path analysis of ambient mode `sleep` to sidecar mode `httpbin`

According to above diagram, the details of network traffic path is demonstrated as below:

**(1) (2) (3)** Request traffic of the `sleep` service is sent out from the `veth` of the `sleep` pod where it will be marked and forwarded to the `istioout` device in the node by following the iptables rules and route rules. The `istioout` device on node A is a [Geneve](https://www.rfc-editor.org/rfc/rfc8926.html) tunnel, and the other end of the tunnel is `pistioout`, which is inside the ztunnel pod on the same node.

**(4) (5)** When the traffic arrives through the `pistioout` device, the iptables rules inside the pod intercept and redirect it through the `eth0` interface in the pod to port `15001`.

**(6)** According to the original request information, ztunnel can obtain the endpoint list of the target service. It will then handle sending the request to the endpoint, such as one of the `httpbin` pods. Finally, the request traffic would get into the `httpbin` pod via the container network.

**(7)** The request traffic arriving in `httpbin` pod will be intercepted and redirected through port `15006` of the sidecar by its iptables rules.

**(8)** Sidecar handles the inbound request traffic coming in via port 15006, and forwards the traffic to the `httpbin` container in the same pod.

## Sidecar mode `sleep` to ambient mode `httpbin` and `helloworld`

### Deployment and configuration for the second scenario

- `sleep` is deployed in namespace foo
    - `sleep` pod is scheduled to Node A
- `httpbin` deployed in namespace bar-1
    - `httpbin` pod is scheduled to Node B
    - the waypoint proxy of `httpbin` is disabled
- `helloworld` is deployed in namespace bar-2
    - `helloworld` pod is scheduled to Node D
    - the waypoint proxy of `helloworld` is enabled
    - the waypoint proxy is scheduled to Node C
- foo namespace enables sidecar injection (foo namespace contains label: `istio-injection: enabled`)
- bar-1 namespace enables ambient mode (bar-1 namespace contains label: `istio.io/dataplane-mode=ambient`)

With the above description, the deployment and network traffic paths are:

{{< image width="100%"
    link="sidecar-to-ambient.png"
    caption="sleep to httpbin and helloworld"
    >}}

### Network traffic path analysis of sidecar mode `sleep` to ambient mode `httpbin`

Network traffic path of a request from the `sleep` pod (sidecar mode) to the `httpbin` pod (ambient mode) is depicted in the top half of the diagram above.

**(1) (2) (3) (4)** the `sleep` container sends a request to `httpbin`. The request is intercepted by iptables rules and directed to port `15001` on the sidecar in the `sleep` pod. Then, the sidecar handles the request and routes the traffic based on the configuration received from istiod (control plane) forwarding the traffic to an IP address corresponding to the `httpbin` pod on node B.

**(5) (6)** After the request is sent to the device pair (`veth httpbin <-> eth0 inside httpbin pod`), the request is intercepted and forwarded using the iptables and route rules to the `istioin` device on node B where `httpbin` pod is running by following its iptables and route rules. The `istioin` device on node B and the `pistion` device inside the ztunnel pod on the same node are connected by a [Geneve](https://www.rfc-editor.org/rfc/rfc8926.html) tunnel.

**(7) (8)** After the request enters the `pistioin` device of the ztunnel pod, the iptables rules in the ztunnel pod intercept and redirect the traffic through port 15008 on the ztunnel proxy running inside the pod.

**(9)** The traffic getting into the port 15008 would be considered as a inbound request, and the ztunnel will then forward the request to the `httpbin` pod in the same node B.

### Network traffic path analysis of sidecar mode `sleep` to ambient mode `httpbin` via waypoint proxy

Comparing with the top part of the diagram, the bottom part inserts a waypoint proxy in the path between the `sleep`, ztunnel and `httpbin` pods. The Istio control plane has all the service information and configuration of the service mesh. When `helloworld` pod is deployed with a waypoint proxy, the EDS configuration of `helloworld` service received by the `sleep` pod sidecar will be changed to the type of `envoy_internal_address`. This causes that the request traffic going through the sidecar to be forwarded to port 15008 of the waypoint proxy on node C via the [HTTP Based Overlay Network (HBONE)](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit) protocol.

Waypoint proxy is an instance of Envoy proxy and forwards the request to the `helloworld` pod based on the routing configuration received from the control plane. Once traffic reaches the `veth` on node D, it follows the same path as the previous scenario.

## Wrapping up

The sidecar mode is what made Istio a great service mesh. However, the sidecar mode can also cause problems as it requires the app and sidecar containers to run in the same pod. Istio ambient mode implements communication among services through centralized proxies (ztunnel and waypoint). The ambient mode provides greater flexibility and scalability, reduces resource consumption as it doesn't require a sidecar for each pod in the mesh, and allows more precise configuration. Therefore, there's no doubt ambient mode is the next evolution of Istio. It's obvious that the coexistence of sidecar and ambient modes may be last a very long time, although the ambient mode is still in alpha stage and the sidecar mode is still the recommended mode of Istio, it will give users a more light-weight option of running and adopting the Istio service mesh as the ambient mode moves towards beta and future releases.

## Reference Resources

- [Traffic in ambient mesh: Istio CNI and node configuration](https://www.solo.io/blog/traffic-ambient-mesh-istio-cni-node-configuration/)
- [Traffic in ambient mesh: Redirection using iptables and Geneve tunnels](https://www.solo.io/blog/traffic-ambient-mesh-redirection-iptables-geneve-tunnels/)
- [Traffic in ambient mesh: ztunnel, eBPF configuration, and waypoint proxies](https://www.solo.io/blog/traffic-ambient-mesh-ztunnel-ebpf-waypoint/)
