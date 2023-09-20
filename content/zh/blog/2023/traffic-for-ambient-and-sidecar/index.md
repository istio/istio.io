---
title: "深挖 Ambient 与 Sidecar 并存的网络流量路径"
description: "深挖 Ambient 与 Sidecar 共存的流量路径。"
publishdate: 2023-09-18
attribution: "Steve Zhang (Intel), John Howard (Google), Yuxing Zeng(Alibaba), Peter Jausovec(Solo.io); Translated by Wilson Wu (DaoCloud)"
keywords: [traffic,ambient,sidecar,coexistence]
---

There are 2 deployment modes for Istio: ambient mode and sidecar mode. The former is still on the way, the latter is the classic one. Therefore, the coexistence of ambient mode and sidecar mode should be a normal deployment form and the reason why this blog may be helpful for Istio users.
Istio 有两种部署模式：Ambient 模式和 Sidecar 模式。
前者还在路上，后者才是经典。因此，Ambient 模式和 Sidecar
模式并存应该是一种正常的部署形式，这也是这篇博客可能对 Istio 用户有所帮助的原因。

## Background
## 背景 {#background}

In the architecture of modern microservices, communication and management among services is critical. To address the challenge, Istio emerged as a service mesh technology. It provides traffic control, security, and superior observation capabilities by utilizing the sidecar. In order to further improve the adaptability and flexibility of Istio, the Istio community began to explore a new mode - ambient mode. In this mode, Istio no longer relies on explicit sidecar injection, but achieves communication and mesh management among services through ztunnel and waypoint proxies. Ambient also brings a series of improvements, such as lower resource consumption, simpler deployment, and more flexible configuration options. When enabling ambient mode, we don't have to restart pods anymore which enables Istio to play a better role in various scenarios.
在现代微服务架构中，服务之间的通信和管理至关重要。为了应对这一挑战，
Istio 作为一种服务网格技术应运而生。它利用 Sidecar 提供流量控制、安全性和卓越的可观察功能。
为了进一步提高 Istio 的适应性和灵活性，Istio 社区开始探索一种新的模式 —— Ambient 模式。
在这种模式下，Istio 不再依赖显式的 Sidecar 注入，而是通过 ztunnel 和 waypoint
代理实现服务之间的通信和网格管理。Ambient 还带来了一系列改进，例如更低的资源消耗、更简单的部署以及更灵活的配置选项。
启用 Ambient 模式后，我们不再需要重新启动 Pod，这使得 Istio 在各种场景中能够更好地发挥作用。

There are many blogs, which can be found in `Reference Resources` section of this blog, to introduce and analyze ambient mode in community and technology forums, and this blog will analyze the network traffic path in Istio ambient and sidecar modes. We will analyze the network traffic path between services in these two modes.
社区和技术论坛上有很多介绍和分析 Ambient 模式的博客，
可以在本博客的 `参考资源` 部分找到，本博客将分析Istio Ambient 和 Sidecar 模式下的网络流量路径。
我们将分析这两种模式下服务之间的网络流量路径。

To clarify the network traffic paths and make it easier to understand, this blog post explores the following two scenarios with corresponding diagrams:
为了阐明网络流量路径并使其更容易理解，本博文探讨了以下两种场景并配有相应的图表：

- **The network path of services in ambient mode to services in sidecar mode**
- **The network path of services in sidecar mode to services in ambient mode**
- **Ambient 模式下的服务到 Sidecar 模式下服务的网络路径**
- **Sidecar 模式下的服务到 Ambient 模式下服务的网络路径**

_Note 1: The following analysis is based on Istio 1.18.2, where ambient mode uses iptables for redirection._
**备注 1：以下分析基于 Istio 1.18.2，其中 Ambient 模式使用 iptables 进行重定向。**

_Note 2: The communications between sidecar and ztunnel/waypoint proxy uses `[HTTP Based Overlay Network (HBONE)](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit)`._
**备注 2：Sidecar 和 ztunnel/waypoint 代理之间的通信使用 `[基于 HTTP 的覆盖网络（HBONE)](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit)`。**

## Ambient mode `sleep` to sidecar mode `httpbin`
## Ambient 模式 `sleep` 到 Sidecar 模式 `httpbin` {#ambient-mode-sleep-to-sidecar-mode-httpbin}

### Deployment and configuration for the first scenario
### 第一个场景的部署和配置 {#deployment-and-configuration-for-the-first-scenario}

- `sleep` is deployed in namespace foo
    - `sleep` pod is scheduled to Node A
- `httpbin` is deployed in namespace bar
    - `httpbin` is scheduled to Node B
- foo namespace enables ambient mode (foo namespace contains label: `istio.io/dataplane-mode=ambient`)
- bar namespace enables sidecar injection (bar namespace contains label: `istio-injection: enabled`)
- `sleep` 部署在名称空间 foo 中
    - `sleep` Pod 被调度到节点 A
- `httpbin` 部署在命名空间 bar 中
    - `httpbin` 被调度到节点 B
- foo 命名空间启用 Ambient 模式（foo 命名空间包含标签：`istio.io/dataplane-mode=ambient`）
- bar 命名空间启用 Sidecar 注入（bar 命名空间包含标签：`istio-injection：enabled`）

With the above description, the deployment and network traffic paths are:
根据以上描述，部署和网络流量路径为：

{{< image width="100%"
    link="ambient-to-sidecar.png"
    caption="Ambient 模式 sleep 到 Sidecar 模式 httpbin"
    >}}

ztunnel will be deployed as a DaemonSet in istio-system namespace if ambient mode is enabled, while istio-cni and ztunnel would generate iptables rules and routes for both the ztunnel pod and pods on each node.
如果启用 Ambient 模式，ztunnel 将作为 DaemonSet 部署在 istio-system 命名空间中，
而 istio-cni 和 ztunnel 将为 ztunnel Pod 和每个节点上的 Pod 生成 iptables 规则和路由。

All network traffic coming in/out of the pod with ambient mode enabled will go through ztunnel based on the network redirection logic. The ztunnel will then forward the traffic to the correct endpoints.
启用 Ambient 模式的 Pod 进出的所有网络流量都将根据网络重定向逻辑通过 ztunnel。
然后 ztunnel 会将流量转发到正确的端点。

### Network traffic path analysis of ambient mode `sleep` to sidecar mode `httpbin`
### Ambient 模式 `sleep` 到 Sidecar 模式 `httpbin` 的网络流量路径分析 {#network-traffic-path-analysis-of-ambient-mode-sleep-to-sidecar-mode-httpbin}

According to above diagram, the details of network traffic path is demonstrated as below:
根据上图，网络流量路径的详细情况如下所示：

**(1) (2) (3)**  Request traffic of the `sleep` service is sent out from the `veth` of the `sleep` pod where it will be marked and forwarded to the `istioout` device in the node by following the iptables rules and route rules. The `istioout` device in the node A is a `[geneve](https://www.rfc-editor.org/rfc/rfc8926.html)` tunnel, and the other end of the tunnel is `pistioout`, which is inside the ztunnel pod on the same node.
**(1) (2) (3)** `sleep` 服务的请求流量从 `sleep` Pod 的 `veth` 发出，
在该 Pod 中被标记并转发到 `istioout` 设备。节点遵循 iptables 规则和路由规则。
节点 A 中的 `istioout` 设备是一个 `[geneve](https://www.rfc-editor.org/rfc/rfc8926.html)` 隧道，
隧道的另一端是 `pistioout`，即位于同一节点上的 ztunnel Pod 内。

**(4) (5)**  When the traffic arrives through the `pistioout` device, the iptables rules inside the pod intercept and redirect it through the `eth0` interface in the pod to port `15001`.
**(4) (5)** 当流量通过 `pistioout` 设备到达时，
Pod 内的 iptables 规则会拦截并通过 pod 中的 `eth0` 接口将其重定向到端口 `15001`。

**(6)** According to the original request information, ztunnel can obtain the endpoint list of the target service. It will then handle sending the request to the endpoint, such as one of the `httpbin` pods. At last, the request traffic would get into the `httpbin` pod via the container network.
**(6)** 根据原始请求信息，ztunnel 可以获取目标服务的端点列表。
然后，它将处理将请求发送到端点，例如 `httpbin` Pod 之一。
最后，请求流量将通过容器网络进入 `httpbin` Pod。

**(7)**  The request traffic arriving in `httpbin` pod will be intercepted and redirected through port `15006` of the sidecar by its iptables rules.
**(7)** 到达 `httpbin` Pod 的请求流量将被 Sidecar 的 iptables
规则拦截并重定向到 Sidecar 的端口 `15006`。

**(8)**  Sidecar handles the inbound request traffic coming in via port 15006, and forwards the traffic to the `httpbin` container in the same pod.
**(8)** Sidecar 处理通过端口 15006 传入的入站请求流量，
并将流量转发到同一 Pod 中的 `httpbin` 容器。

## Sidecar mode `sleep` to ambient mode `httpbin` and `helloworld`
## Sidecar 模式 `sleep` 到 Ambient 模式 `httpbin` 和 `helloworld` {#sidecar-mode-sleep-to-ambient-mode-httpbin-and-helloworld}

### Deployment and configuration for the second scenario
### 第二种场景的部署和配置 {#deployment-and-configuration-for-the-second-scenario}

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
- `sleep` 部署在名称空间 foo 中
    - `sleep` Pod 被调度到节点 A
- `httpbin` 部署在命名空间 bar-1 中
    - `httpbin` Pod 被调度到节点 B
    - `httpbin` 的 waypoint 代理被禁用
- `helloworld` 部署在命名空间 bar-2 中
    - `helloworld` Pod 被调度到节点 D
    - `helloworld` 的 waypoint 代理被启用
    - waypoint 代理被调度到节点 C
- foo 命名空间启用 Sidecar 注入（foo 命名空间包含标签：`istio-injection:enabled`）
- bar-1 命名空间启用 Ambient 模式（bar-1 命名空间包含标签：`istio.io/dataplane-mode=ambient`）

With the above description, the deployment and network traffic paths are:
根据以上描述，部署和网络流量路径为：

{{< image width="100%"
    link="sidecar-to-ambient.png"
    caption="sleep 到 httpbin 和 helloworld"
    >}}

### Network traffic path analysis of sidecar mode `sleep` to ambient mode `httpbin`
### Sidecar 模式 `sleep` 到 Ambient 模式 `httpbin` 的网络流量路径分析 {#network-traffic-path-analysis-of-sidecar-mode-sleep-to-ambient-mode-httpbin}

Network traffic path of a request from the `sleep` pod (sidecar mode) to the `httpbin` pod (ambient mode) is depicted in the top half of the diagram above.
上图的上半部分描述了从 `sleep` Pod（Sidecar 模式）到 `httpbin` Pod（Ambient 模式）的请求的网络流量路径。

**(1) (2) (3) (4)** the `sleep` container sends a request to `httpbin`. The request is intercepted by iptables rules and directed to port `15001` on the sidecar in the `sleep` pod. Then, the sidecar handles the request and routes the traffic based on the configuration received from istiod (control plane). Next, the sidecar forwards the traffic to an IP address corresponding to the `httpbin` pod on node B.
**(1) (2) (3) (4)** `sleep` 容器向 `httpbin` 发送请求。该请求被 iptables 规则拦截，
并定向到 `sleep` Pod 中 Sidecar 上的端口 `15001`。然后，
Sidecar 处理请求并根据从 istiod（控制平面）收到的配置路由流量。
接下来，Sidecar 将流量转发到节点 B 上的 `httpbin` Pod 对应的 IP 地址。

**(5) (6)**  After the request is sent to the device pair (`veth httpbin <-> eth0 inside httpbin pod`), the request is intercepted and forwarded using the iptables and route rules to the `istioin` device on the node B where `httpbin` pod is running by following its iptables and route rules. The `istioin` device on node B and the `pistion` device inside the ztunnel pod on the same node are connected by a `[geneve](https://www.rfc-editor.org/rfc/rfc8926.html)` tunnel.
**(5) (6)** 将请求发送到设备对（`veth httpbin <-> eth0 inside httpbin pod`）后，
请求被拦截并使用 iptables 和路由规则转发到 `istioin` 通过遵循其 iptables 和路由规则，
运行 `httpbin` Pod 的节点 B 上的设备。节点 B 上的 `istioin` 设备和同一节点上
ztunnel Pod 内的 `pistion` 设备通过 `[geneve](https://www.rfc-editor.org/rfc/rfc8926.html)` 连接隧道。

**(7) (8)** After the request enters the `pistioin` device of the ztunnel pod, the iptables rules in the ztunnel pod intercept and redirect the traffic through port 15008 on the ztunnel proxy running inside the pod.
**(7) (8)** 请求进入 ztunnel Pod 的 pistioin 设备后，ztunnel pod 中的 iptables
规则会拦截并通过 Pod 内运行的 ztunnel 代理上的端口 15008 重定向流量。

**(9)** The traffic getting into the port 15008 would be considered as a inbound request, then ztunnel will forward the request to the `httpbin` pod in the same node B.
**(9)** 进入端口 15008 的流量将被视为入站请求，
然后 ztunnel 会将请求转发到同一节点 B 中的 `httpbin` Pod。

### Network traffic path analysis of sidecar mode `sleep` to ambient mode `httpbin` via waypoint proxy
### 通过 waypoint 代理从 Sidecar 模式 `sleep` 到 Ambient 模式 `httpbin` 的网络流量路径分析 {#network-traffic-path-analysis-of-sidecar-mode-sleep-to-ambient-mode-httpbin-via-waypoint-proxy}

Comparing with the top part of the diagram, the bottom part inserts a waypoint proxy in the path between `sleep`, ztunnel and `httpbin` pods. The Istio control plane has all information of service and configuration of the service mesh. When `helloworld` pod is deployed with a waypoint proxy, the EDS configuration of `helloworld` service received by sidecar of `sleep` pod will be changed to the type of `envoy_internal_address`. This causes that the request traffic going through the sidecar to be forwarded to port 15008 of the waypoint proxy on node C via the `[HBONE](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit)` protocol.
与图中的顶部相比，底部在 `sleep`、ztunnel 和 `httpbin` Pod 之间的路径中插入了一个 waypoint 代理。
Istio 控制平面拥有服务网格的所有服务和配置信息。当使用 waypoint 代理部署 helloworld Pod 时，
sleep Pod 的 Sidecar 接收到的 helloworld 服务的 EDS 配置将更改为 envoy_internal_address 类型。
这会导致通过 Sidecar 的请求流量通过
`[HBONE](https://docs.google.com/document/d/1Ofqtxqzk-c_wn0EgAXjaJXDHB9KhDuLe-W3YGG67Y8g/edit)`
协议转发到节点 C 上的 waypoint 代理的 15008 端口。

Waypoint proxy is an instance of the Envoy proxy and forwards the request to the `helloworld` pod based on the routing configuration received from the control plane. Once traffic reaches the `veth` on node D, it follows the same path as the previous scenario
waypoint 代理是 Envoy 代理的一个实例，它根据从控制平面收到的路由配置将请求转发到 `helloworld` Pod。
一旦流量到达节点 D 上的 `veth`，它就会遵循与之前场景相同的路径。

## Wrapping up
## 总结 {#wrapping-up}

The sidecar mode is what made Istio a great service mesh. However, the sidecar mode can also cause problems as it requires the app and sidecar containers to run in the same pod. Istio ambient mode implements communication among services through centralized proxies (ztunnel and waypoint). The ambient mode provides greater flexibility and scalability, reduces resource consumption as it doesn't require a sidecar for each pod in the mesh, and allows more precise configuration. Therefore, there's no doubt ambient mode is the next evolution of Istio. It's obvious that the coexistence of sidecar and ambient modes may be last a very long time, although the ambient mode is still in alpha stage and the sidecar mode is still the recommended mode of Istio, it will give users a more light-weight option of running and adopting the Istio service mesh as the ambient mode moves towards beta and future releases.
Sidecar 模式使 Istio 成为一个出色的服务网格。但是，Sidecar 模式也会导致问题，
因为它要求应用程序和 Sidecar 容器在同一个 Pod 中运行。
Istio 环境模式通过集中式代理（ztunnel 和 waypoint）实现服务之间的通信。
环境模式提供了更大的灵活性和可扩展性，减少了资源消耗，因为它不需要网格中的每个 Pod 都有 sidecar，
并且允许更精确的配置。 因此，毫无疑问，环境模式是 Istio 的下一个演进。
显然，sidecar 和ambient 模式的共存可能会持续很长一段时间，
虽然ambient 模式还处于alpha 阶段，sidecar 模式仍然是Istio 的推荐模式，
但它将给用户提供更轻量级的选择 随着环境模式转向测试版和未来版本，运行并采用 Istio 服务网格。

## Reference Resources
## 参考资源 {#reference-resources}

- [Traffic in ambient mesh: Istio CNI and node configuration](https://www.solo.io/blog/traffic-ambient-mesh-istio-cni-node-configuration/)
- [Traffic in ambient mesh: Redirection using iptables and GENEVE tunnels](https://www.solo.io/blog/traffic-ambient-mesh-redirection-iptables-geneve-tunnels/)
- [Traffic in ambient mesh: ztunnel, eBPF configuration, and waypoint proxies](https://www.solo.io/blog/traffic-ambient-mesh-ztunnel-ebpf-waypoint/)
- [环境网格中的流量：Istio CNI 和节点配置](https://www.solo.io/blog/traffic-ambient-mesh-istio-cni-node-configuration/)
- [环境网格中的流量：使用 iptables 和 GENEVE 隧道进行重定向](https://www.solo.io/blog/traffic-ambient-mesh-redirection-iptables-geneve-tunnels/)
- [环境网格中的流量：ztunnel、eBPF 配置和路点代理](https://www.solo.io/blog/traffic-ambient-mesh-ztunnel-ebpf-waypoint/)
