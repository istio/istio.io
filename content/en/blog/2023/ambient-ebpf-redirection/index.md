---
title: "Leverage eBPF for traffic redirection in Istio ambient mode"
description: An alternative approach to redirect application pod traffic to ztunnel in Istio ambient mode.
publishdate: 2023-03-15
attribution: "Iris Ding (Intel), Chun Li (Intel)"
keywords: [istio,ambient,ztunnel,eBPF]
---

The istio-cni component running on each Kubernetes worker node is responsible for redirecting application pod traffics to ztunnel on that node. By default it relies on iptables and
[Geneve](https://www.rfc-editor.org/rfc/rfc8926.html) tunnel to achieve this redirection.  Now a new approach which is based on eBPF is also available in Istio ambient mode for this purpose.

## Why eBPF

In the context of Istio ambient mode redirection, although performance is undoubtedly important, it is imperative to recognize that, programmability or possibility takes precedence. With eBPF, you can leverage additional context to make these changes in the kernel so that packets can bypass complex routing and simply arrive at their final destination, that is sought-after for redirection datapath. Moreover, eBPF will provide the same or better control in datapath compared with iptables while providing the end of user experience that we are looking for.

## How it works

The eBPF program attached to the [traffic control](https://man7.org/linux/man-pages/man8/tc-bpf.8.html) ingress and egress hook has been compiled into istio-cni component. The istio-cni component will watch pod events and attach/detach the eBPF program to related network interface when the pod is moved into/out of the ambient mode.

{{< image width="55%"
    link="ambient-ebpf.png"
    caption="ambient eBPF architecture"
    >}}

Utilizing eBPF program(instead of iptables) means eliminating encapsulating(for Geneve) tasks and shifting routing tasks to be customized in the kernel space, which yields gains in performance and flexibilities in routing. In summary, all traffic from/to the application pod will be intercepted and redirected to the corresponding ztunnel pod. On ztunnel side, proper redirection will be performed based connection lookup result within eBPF program. This would provide a more precise level of control over the network traffic between application and ztunnel.

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

The latency and throughput(QPS) for eBPF mode is bit better than IPtables mode. The following test cases are run in a kind cluster which
consists of a Fortio client sending requests to a Fortio server with both of them running in ambient mode(with debug log turned off in eBPF and client/server located in the same k8s node).

{{< image width="90%" link="./MaxQPS.png" alt="Max QPS with different connection numbers " title="Max QPS with different connection numbers" caption="Max QPS with different connection numbers" >}}

The above metrics are tested with following command:

{{< text bash >}}
$ fortio load -t 60s -qps 0 -c <connection_nums> http://<fortio-svc-name>:8080
{{< /text >}}

{{< image width="90%" link="./Latency-with-8000-qps.png" alt="Latency(ms) for QPS 8000 with different connection numbers" title="Latency(ms) for QPS 8000 with different connection numbers" caption="Latency(ms) for QPS 8000 with different connection numbers" >}}

The above metrics are tested with following command:

{{< text bash >}}
$ fortio load -t 60s -qps 8000 -c <connection_nums> http://<fortio-svc-name>:8080
{{< /text >}}

## Wrapping up

Both eBPF and iptables have their own advantages and disadvantages when it comes to traffic redirection. eBPF is a modern, flexible, and powerful alternative that allows for more customization in rule creation and offers better performance. However, it does require a modern kernel version (4.20 or later for redirection case) which may not be available on some systems. On the other hand, iptables is widely used and compatible with most Linux distributions, even those with older kernels. However, it lacks the flexibility and extensibility of eBPF and may have lower performance.

Ultimately, the choice between eBPF and iptables for traffic redirection will depend on the specific needs and requirements of the system, as well as the user's level of expertise in using each tool. Some users may prefer the simplicity and compatibility of iptables, while others may require the flexibility and performance of eBPF.

There is still plenty of work to be done, including integration with various CNI plugins, and contributions to improve the ease of use would be greatly welcomed.
