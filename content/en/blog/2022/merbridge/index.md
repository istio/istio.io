---
title: "Merbridge - Accelerate your mesh with eBPF"
description: "Replacing iptables rules with eBPF to allow data being transported directly from inbound sockets to outbound sockets to shorten the datapath between sidecars and services."
publishdate: 2022-01-25
attribution: "Kebe Liu (DaoCloud), Xiaopeng Han (DaoCloud), Hui Li (DaoCloud)"
keywords: [Istio,ebpf,iptables,sidecar]
---

## Overview

Currently, service mesh technologies lead by Istio are attracting more and more attention of enterprises. The secret of Istio’s abilities of traffic management, security, observability and policy is all in the Envoy. Istio uses Envoy as the sidecar to intercept service traffic with the help of iptables technology in order to do all the functionalities.

However, there are shortcomings in using iptables to do the interception. Since it’s highly versatile to filter packets, several routing rules are applied to form the filter chain before reaching to the destination socket. Due to the need to intercept both the inbound and the outbound traffic, when adding the sidecar part to the data-path, the original path needs to be processed twice in the kernel mode now becomes four times. As a result, the performance will be lost a lot since the data-path is long and being doubled. If the application requires high-performance, it will obviously be impacted.

In the past two years, eBPF becomes a hot-trending technology, and many projects based on eBPF have been raised to the community. Projects like Cilium, [px.dev](http://px.dev) provides us with great cases of eBPF in observability and network packet processing. With eBPF’s `sockops` and `redir` capabilities, data packets can be processed efficiently by directly being transported from the inbound socket to the outbound socket. In Istio scenarios, it will be possible to use eBPF to replace iptables rules to accelerate the data-plane traffic by shorten the data-path.

Now that we have open sourced the Merbridge project, and by applying the following command to your Istio-managed cluster, you will directly get the eBPF ability to achieve network acceleration.

{{< text bash >}}
$ kubectl apply -f https://raw.githubusercontent.com/merbridge/merbridge/main/deploy/all-in-one.yaml
{{< /text >}}

{{< warning >}}
Attention：Currently only support kernel version ≥ 5.15. Please check your kernel version to make sure eBPF functions properly.
{{< /warning >}}

### Utilize eBPF `sockops` for performance optimization

Network connection is essentially socket communication. eBPF provides us with a function `bpf_msg_redirect_hash`, to directly forward the packets sent by the application in the inbound socket to the outbound socket, which can noticeably optimize the processing of the packets in the kernel.

Here the `sock_map` is the crucial part to record the socket rules because an existing socket connection needs to be selected from the `sock_map` according to the current data packet information. Therefore, the socket information needs to be stored to the map at the hook of `sockops` or somewhere else, and being provided according to the key formed by given information(usually quadruple).

## Approaches

Next, we will introduce the detailed design and implementation principles of Merbridge step by step according to the actual scene, to give you a preliminary understanding of Merbridge and eBPF.

### Istio sidecar traffic interception based on iptables

{{< image link="./1.png" caption="Istio Sidecar Traffic Interception Based on Iptables" >}}

As shown above, when external traffic accesses certain application’s ports, it will be intercepted by PREROUTING rule in iptables, forwarded to port 15001 of the sidecar container, and handed over to Envoy for processing(Like the red path of 1, 2, 3, 4 in the graph above).

Envoy processes the traffic by using the policies the control plane issued. After finishing processing, the traffic will be sent to the actual container port of the application container.

When the application tries to access other services, it will be intercepted by OUTPUT rule in iptables, and then be forwarded to port 15006(Which Envoy is listening to) of the sidecar container. (Like the red path of 9, 10, 11, 12, which is similar to the inbound traffic processing)

It is obviously to see that the original route directly to the application port now needs to be forwarded to the sidecar, and then be sent to the application port from the sidecar port, which undoubtedly increases the overhead. Moreover, although iptables is versatile in many cases, its versatility determines that its performance is not always ideal because it inevitably adds delays to the whole link with different filtering rules.

If we use `sockops` to directly connect the sidecar’s socket to the application’s socket, the traffic will not go through iptables, and the performance will be improved.

### Processing outbound traffic

As mentioned above, we would like to use eBPF’s `sockops` to bypass iptables to accelerate network requests. At the same time, we also try not to modify any parts of Istio to make it fully adaptive to the community version. As a result, we need to simulate what iptables does in eBPF.

When we look back at iptables itself, the traffic redirection part utilizes its DNAT function. When trying to simulate the capabilities of iptables using eBPF, to implement the capabilities similar to iptables DNAT is the key part, and there are two main parts:

1. Modify the destination address when the connection is initiated so that traffic can be sent to the new interface.
1. Enable Envoy to identify the original destination address to be able to identify the specific traffic.

For the first part, we can use eBPF’s `connect` program to process it, by modifying `user_ip` and `user_port`.

For the second part, we need to understand the concept of `ORIGINAL_DST` which belongs to the `netfilter` module in the kernel.

The key point is that: when the application (including Envoy) receives the connection, it will call `get_sockopt` function to obtain `ORIGINAL_DST`. If going through the iptables DNAT process, iptables will set this parameter with the value `original IP + port` value to the current socket. Thus, the application can get the original destination address according to the connection.

Then, we have to modify this call process through eBPF’s `get_sockopts` function. (`bpf_setsockopt` is not used here because this parameter does not currently support the optname of `SO_ORIGINAL_DST`).

Referring to the figure below, when an application initiates a request, it will go through the following steps:

1. When the application initiates a connection, the `connect` program will modify the destination address to `127.x.y.z:15001`, and use `cookie_original_dst` to save the original destination address.
1. In the `sockops` program, the current socket information and the quadruple are saved in `sock_pair_map`. At the same time, the same quadruple and its corresponding original destination address will be written to `pair_original_dest` (Cookie is not used here because it cannot be obtained in the `get_sockopt` program).
1. After envoy receives the connection, it will call `get_sockopt` function to read the destination address of the current connection. `get_sockopt` function will extract and return the original destination address from `pair_original_dst` according to the quadruple information. Thus, the connection is completely established.
1. In the data transportation step, the `redir` program will read the sock information from `sock_pair_map` according to the quadruple information, and then forward it directly through `bpf_msg_redirect_hash` to speed up the request.

{{< image link="./2.png" caption="Processing Outbound Traffic" >}}

The reason to set the destination address to `127.x.y.z` instead of `127.0.0.1` is: when different pods are existing, there might be conflicting quadruples, and this way will gracefully avoid the conflicting condition. (Pods' IPs are different, and they will not be in the conflicting condition at any time.)

### Inbound traffic processing

The processing of inbound traffic is basically similar to outbound traffic, with the only difference: revising the port of the destination to 15006.

However, it should be noted that since eBPF cannot take effect in the specified namespace like iptables, the change will be global, which means that if we use a Pod that is not originally managed by Istio, or an external IP address, serious problems will be encountered like the connection not being established at all.

As a result, we designed a tiny control plane here (deployed in DaemonSet), which watches all pods, similar to kubelet’s watching to the pod lists of the node, to write the pod IP addresses that have been injected into the sidecar to the `local_pod_ips` map.

When processing the inbound traffic, if the destination address is not in the map, we will not do anything to the traffic to make the traffic being processed more flexibly and simply.

Otherwise, the steps are the same as for outbound traffic.

{{< image link="./3.png" caption="Processing Inbound Traffic" >}}

### Same-node acceleration

Theoretically, acceleration between Envoy sidecars on the same node can be achieved directly through inbound traffic processing. However, Envoy will raise an error when accessing the application of the current pod in this scenario.

In Istio, Envoy accesses the application by using the current pod IP and port number. With the above scenario, we realized that the pod ip is existing in the `local_pod_ips` as well, and the traffic will be redirected to the pod IP and 15006 port again because it is the same address that the inbound traffic comes from. Redirecting to the same inbound address will cause infinite recursion loop.

Here comes the question: are there any ways to get the IP address in the current namespace with eBPF?

The answer is Yes! We have designed a feedback mechanism:

When Envoy tries to establish the connection, we do redirect it to port 15006. However, in the `sockops` step, we will determine if the source IP and the destination IP are the same. If yes, it means the wrong request is sent, and we will discard this connection in the `sockops` process. In the meantime, the current `ProcessID` and `IP` information will be written into the `process_ip` map, to allow eBPF to support the correspondence between processes and IPs.

When the next request is sent, the same process above will not be performed anymore. We will check directly from the `process_ip` map if the destination address is the same as the current IP address.

{{< warning >}}
Envoy will retry when the request fails, and this retry process will only occur once, which means the subsequent requests will be super fast.
{{< /warning >}}

{{< image link="./4.png" caption="Same-node acceleration" >}}

### Connection relationship

Before applying eBPF using Merbridge, the data-path between pods is like:

{{< image link="./5.png" caption="Iptables's Data-path" >}}

After applying Merbridge(eBPF), the outbound traffic will skip many kernel modules like the graph below to improve the performance:

{{< image link="./6.png" caption="EBPF's Data-path" >}}

If two pods are on the same machine, the connection can even be faster:

{{< image link="./7.png" caption="EBPF's Datapath on The Same Machine" >}}

As above, using eBPF to process the traffic on the machine can greatly reduce the number of processes performed in the kernel, and the communication quality can be improved as well.

## Performance test

{{< warning >}}
Currently the tests below are basic, and not tested in production yet.
{{< /warning >}}

The graph below shows the overall latency after using eBPF instead of iptables (lower is better):

{{< image link="./8.png" caption="Latency vs Client Connections Graph" >}}

The graph below shows the overall QPS after using eBPF (higher is better): the test results are generated through `wrk` tests.

{{< image link="./9.png" caption="QPS vs Client Connections Graph" >}}

## Merbridge

In this blog, the core ideas of Merbridge are introduced. By replacing iptables with eBPF, the data transportation process can be accelerated imperceptibly like iptables in the mesh scenario. At the same time, the Istio will not be revised at all. This means if you do not want to use eBPF any more, just delete the DaemonSet, and the datapath will be recovered to the traditional iptables method without any problems.

Merbridge is a completely independent open source project. It is still in the early stage, and we are looking forward to having more users and developers to get engaged. It will be greatly appreciated if you can get this new technology tried to accelerate your mesh, and provide us with some feedback!

Project address: [https://github.com/merbridge/merbridge](https://github.com/merbridge/merbridge)

Reference:

[https://github.com/merbridge/merbridge](https://github.com/merbridge/merbridge)

[https://developpaper.com/kubecon-2021-｜-using-ebpf-instead-of-iptables-to-optimize-the-performance-of-service-grid-data-plane/](https://developpaper.com/kubecon-2021-%EF%BD%9C-using-ebpf-instead-of-iptables-to-optimize-the-performance-of-service-grid-data-plane/)

[https://developpaper.com/go.php?go=aHR0cHM6Ly9qaW1teXNvbmcuaW8vYmxvZy9zaWRlY2FyLWluamVjdGlvbi1pcHRhYmxlcy1hbmQtdHJhZmZpYy1yb3V0aW5n](https://developpaper.com/go.php?go=aHR0cHM6Ly9qaW1teXNvbmcuaW8vYmxvZy9zaWRlY2FyLWluamVjdGlvbi1pcHRhYmxlcy1hbmQtdHJhZmZpYy1yb3V0aW5n)

[Envoy doc](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/original_dst_filter)

[https://ebpf.io/](https://ebpf.io/)

[https://cilium.io/](https://cilium.io/)
