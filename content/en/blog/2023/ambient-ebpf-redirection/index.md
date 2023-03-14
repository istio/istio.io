---
title: "Leverage eBPF for traffic redirection in Istio ambient mode"
description: An alternative approach to redirect application pod traffic to ztunnel in Istio ambient mode.
publishdate: 2023-03-15
attribution: "Iris Ding (Intel), Chun Li (Intel)"
keywords: [istio,ambient,ztunnel,eBPF]
---

The istio-cni component running on each Kubernetes worker node is responsible for redirecting application pod traffics to ztunnel on that node. By default it relies on iptables and
Geneve tunnel to achieve this redirection.  Now a new approach which is based on eBPF is also available in Istio ambient mode for this purpose.

## Why eBPF

In the context of Istio ambient mode redirection, although performance is undoubtedly important, it is imperative to recognize that, programmability or possibility takes precedence. With eBPF, you can leverage additional context to make these changes in the kernel so that packets can bypass complex routing and simply arrive at their final destination, that is sought-after for redirection datapath. Moreover, eBPF will provide the same or better control in datapath compared with iptables while providing the end of user experience that we are looking for.

## How it works

The eBPF program attached to the traffic control ingress and egress hook has been compiled into istio-cni component.  The istio-cni component will watch pod events and attach/detach the eBPF program to related network interface when the pod is moved into/out of the ambient mode. A detailed picture is as below:

{{< image width="100%"
    link="ambient-ebpf.png"
    caption="ambient eBPF architecture"
    >}}

## How to enable eBPF redirection in Istio ambient mode

Follow the [get-started-ambient](/blog/2022/get-started-ambient/) to set up the cluster. When to install Istio,  set the `values.cni.ambient.redirectMode` configuration parameter with the following command:

{{< text bash >}}
$ istioctl install --set profile=ambient  --set values.cni.ambient.redirectMode="ebpf"
{{< /text >}}

Grab the istio-cni logs to confirm eBPF redirection is on:

{{< text plain >}}
ambient Writing ambient config: {"ztunnelReady":true,"redirectMode":"eBPF"}
{{< /text >}}

## Performance gains

The latency for eBPF mode is bit better than IPtables mode especially when client and server located within the same node. The following test cases are run in a kind cluster which
consists of a Fortio client sending requests to a Fortio server with both of them running in ambient mode(with debug log turned off in eBPF).

{{< image width="90%" link="./Latency-same-node.png" alt="Latency(ms) for client-server located in the same node" title="Latency(ms) for client-server located in the same node" caption="Latency(ms) for client-server located in the same node" >}}

{{< image width="90%" link="./Latency-different-node.png" alt="Latency(ms) for client-server located in different node" title="Latency(ms) for client-server located in different node" caption="Latency(ms) for client-server located in different node" >}}

{{< image width="90%" link="./MaxQPS-same-node.png" alt="Max QPS for client-server located in the same node" title="Max QPS for client-server located in the same node" caption="Max QPS for client-server located in the same node" >}}

{{< image width="90%" link="./MaxQPS-different-node.png" alt="Max QPS for client-server located in different node" title="Max QPS for client-server located in different node" caption="Max QPS for client-server located in different node" >}}
