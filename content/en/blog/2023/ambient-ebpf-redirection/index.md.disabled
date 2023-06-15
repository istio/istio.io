---
title: "Using eBPF for traffic redirection in Istio ambient mode"
description: An alternative approach to redirecting application pod traffic to the per-node ztunnel.
publishdate: 2023-03-29

attribution: "Iris Ding (Intel), Chun Li (Intel)"
keywords: [istio,ambient,ztunnel,eBPF]
---

In Istio's new [ambient mode](/blog/2022/introducing-ambient-mesh/), the `istio-cni` component running on each Kubernetes worker node is responsible for redirecting application traffic to the zero-trust tunnel (ztunnel) on that node. By default it relies on iptables and
[Generic Network Virtualization Encapsulation (Geneve)](https://www.rfc-editor.org/rfc/rfc8926.html) overlay tunnels to achieve this redirection. We have now added support for an eBPF-based method of traffic redirection.

## Why eBPF

Although performance considerations are essential in the implementation of Istio ambient mode redirection, it's also important to consider ease of programmability, to enable the implementation of versatile and customized requirements. With eBPF, you can leverage additional context in the kernel to bypass complex routing and simply send packets to their final destination.

Furthermore, eBPF enables deeper visibility and additional context for packets in the kernel, allowing for more efficient and flexible management of data flow compared with iptables.

## How it works

An eBPF program, attached to the [traffic control](https://man7.org/linux/man-pages/man8/tc-bpf.8.html) ingress and egress hook, has been compiled into the Istio CNI component. `istio-cni` will watch pod events and attach/detach the eBPF program to other related network interfaces when the pod is moved into or out of ambient mode.

Using an eBPF program (instead of iptables) eliminates the need to encapsulate tasks (for Geneve), allowing the routing tasks to be customized in kernel space instead. This yields both gains in performance, and additional flexibility, in routing.

{{< image width="55%"
    link="ambient-ebpf.png"
    caption="ambient eBPF architecture"
    >}}

All traffic to/from the application pod will be intercepted by eBPF and redirected to the corresponding ztunnel pod. On the ztunnel side, proper redirection will be performed based on connection lookup results within the eBPF program. This provides more efficient control of the network traffic between the application and ztunnel.

## How to enable eBPF redirection in Istio ambient mode

Follow the instructions in [Getting Started with Ambient Mesh](/blog/2022/get-started-ambient/) to set up your cluster, with a small change: when you install Istio, set the `values.cni.ambient.redirectMode` configuration parameter to `ebpf`.

{{< text bash >}}
$ istioctl install --set profile=ambient --set values.cni.ambient.redirectMode="ebpf"
{{< /text >}}

Check the `istio-cni` logs to confirm eBPF redirection is on:

{{< text plain >}}
ambient Writing ambient config: {"ztunnelReady":true,"redirectMode":"eBPF"}
{{< /text >}}

## Performance gains

The latency and throughput (QPS) for eBPF redirection are somewhat better than using iptables. The following tests were run in a `kind` cluster with
a Fortio client sending requests to a Fortio server, both running in ambient mode (with eBPF debug logging disabled) and on the same Kubernetes worker node.

{{< text bash >}}
$ fortio load -uniform -t 60s -qps 0 -c <num_connections> http://<fortio-svc-name>:8080
{{< /text >}}

{{< image width="90%" link="./MaxQPS.png" alt="Max QPS with varying number of connections" title="Max QPS with varying number of connections" caption="Max QPS, with varying number of connections" >}}

{{< text bash >}}
$ fortio load -uniform -t 60s -qps 8000 -c <num_connections> http://<fortio-svc-name>:8080
{{< /text >}}

{{< image width="90%" link="./P75-Latency-with-8000-qps.png" alt="Latency (ms) for QPS 8000 with varying number of connections" title="P75 Latency (ms) for 8000 QPS, with varying number of connections" caption="P75 Latency (ms) for QPS 8000 with varying number of connections" >}}

## Wrapping up

Both eBPF and iptables have their own advantages and disadvantages when it comes to traffic redirection. eBPF is a modern, flexible, and powerful alternative that allows for more customization in rule creation and offers better performance. However, it does require a modern kernel version (4.20 or later for redirection case) which may not be available on some systems. On the other hand, iptables is widely used and compatible with most Linux distributions, even those with older kernels. However, it lacks the flexibility and extensibility of eBPF and may have lower performance.

Ultimately, the choice between eBPF and iptables for traffic redirection will depend on the specific needs and requirements of the system, as well as the user's level of expertise in using each tool. Some users may prefer the simplicity and compatibility of iptables, while others may require the flexibility and performance of eBPF.

There is still plenty of work to be done, including integration with various CNI plugins, and contributions to improve the ease of use would be greatly welcomed. Please join us in #ambient on the [Istio slack](https://slack.istio.io/).
