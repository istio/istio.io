---
title: ZTunnel Inpod traffic redirection 
description: User guide for details on the ZTunnel inpod traffic redirection function.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

## Introduction {#introsection}

This guide is a supplement to the [Istio Ambient L4 Networking guide](/docs/ops/ambient/usage/ztunnel) and provides additional detail on the traffic redirection mechanism between endpoints and ZTunnel proxies. It is recommended to read that guide prior to reading this one.

## Ambient traffic redirection

In the context of Istio Ambient, the term traffic redirection refers to data plane functionality that intercepts traffic sent to and from endpoints that ambient enabled and the proxies that handle the core data path in the ambient mesb. Sometimes the term "traffic capture" is also used equivalently, in this guide we will stick with the term "traffic redirection". 

{{< tip >}}
{{< boilerplate ambient-alpha-warning >}}

Inpod traffic redirection is shipped as the default ambient capture mechanism for Ambient from Istio version 1.21.0 onwards.

Previous releases of Istio shipping alpha implementations of ambient used a different method, which has been removed and replaced.  As with all alpha features, no backwards compatibility is guaranteed, documentation only refers to the current implementation, and bugs should only be reported against the latest alpha release.
{{< /tip >}}

### Inpod traffic redirection model

The core design principle behind the new inpod traffic redirection function is that the ztunnel proxy has the ability to perform all its data path required functionality directly inside the linux network namespace of an ambient endpoint/ pod. This is achieved via a combination of new functionality added to the `istio-cni` node agent and the ztunnel proxy components from the 1.21.0 release onwards.  A key benefit of this model is that it enables Istio Ambient to work alongside any Kubernetes CNI plugin transparently and without impacting kubernetes networking features. 

The following figure illustrates the sequence of events when a new workload pod is started in (or added to) an ambient-enabled namespace.

{{< image width="100%"
link="./pod-added-to-ambient.svg"
alt="pod added to the ambient mesh flow"
>}}

The `istio-cni` node agent is informed of pod lifecycle events such as creation and deletion and also watches the underlying Kubernetes api server for events such as the ambient label being attached to a pod or its namespace. The `istio-cni` is a CNI plugin that is secondary to the primary CNI plugin within that Kubernetes cluster. Its purpose is only to setup traffic redirection and istio specific functions while letting the primary Kubernetes CNI plugin handle core L3 networking setup that is needed independent of istio. Once the `istio-cni` node agent is informed of sych an event that requires it to be added to the ambient mesh, the following sequence of operations is performed.
i
- The `istio-cni` node agent enters the pod’s network namespace and establishes network redirection rules inside the pod network namespace, such that packets entering and leaving the pod are intercepted and transparently redirected to the node-local ztunnel proxy instance listening on [well-known ports](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008, 15006, 15001).
- The `istio-cni` node agent then informs the node ztunnel over a Unix domain socket that it should establish local proxy
listening ports inside the pod’s network namespace, (on 15008, 15006, and 15001), and provides ztunnel with a low-level
Linux [file descriptor](https://en.wikipedia.org/wiki/File_descriptor) representing the pod’s network namespace.
  - While typically sockets are created within a Linux network namespace by the process actually running inside that
network namespace, it is perfectly possible to leverage Linux’s low-level socket API to allow a process running in one
network namespace to create listening sockets in another network namespace, assuming the target network namespace is known
at creation time.
- The node-local ztunnel internally spins up a new proxy instance and listen port set, dedicated to the newly-added pod.
- Once the in-Pod redirect rules are in place and the ztunnel has established the listen ports, the pod is added in the
mesh and traffic begins flowing thru the node-local ztunnel, as before.
 
Once the pod is successfully added to the ambient mesh, traffic to and from pods in the mesh will be fully encrypted with mTLS by default, as always with Istio.

Traffic will now enter and leave the pod network namespace as encrypted traffic - it will look like every pod in the ambient mesh has the ability to enforce mesh policy and securely encrypt traffic, even though the user application running in the pod
has no awareness of either.

Here’s a diagram to illustrate how encrypted traffic flows between pods in the ambient mesh in the new model:

{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="HBONE traffic flows between pods in the ambient mesh"
    >}}

### Observing the inpod traffic redirection in an ambient mesh

If Istio Ambient traffic is not working correctly, there are some quick checks that can be made to help narrow down the problem.  In order to observe inpod traffic redirection in action, first follow the steps described in the [ztunnel L4 networking guide](/docs/ops/ambient/usage/ztunnel) including deployment of istio ambient mesh on a Kubernetes Kind cluster and the deployment of the `httpbin` and `sleep` deployments in the namespaced tagged for ambient operation as described in that guide. Once it is verified that the application is successfully running in the ambient mesh, use the following steps to observe the inpod traffic redirection.

In order to confirm that the mesh is using Inpod redirection, once Ambient has been enabled in an application pod, check the ztunnel proxy logs. As shown in the example below, the ztunnel logs related to inpod indicate that inpod mode is enabled and ztunnel proxy has received the netns information about an ambient application pod and has started proxying for it. 

{{< text bash >}}
$ kubectl logs ds/ztunnel -n istio-system  | grep inpod
Found 3 pods, using pod/ztunnel-hl94n
inpod_enabled: true
inpod_uds: /var/run/ztunnel/ztunnel.sock
inpod_port_reuse: true
inpod_mark: 1337
2024-02-21T22:01:49.916037Z  INFO ztunnel::inpod::workloadmanager: handling new stream
2024-02-21T22:01:49.919944Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("1e054806-e667-4109-a5af-08b3e6ba0c42") received netns, starting proxy
2024-02-21T22:01:49.925997Z  INFO ztunnel::inpod::statemanager: pod received snapshot sent
2024-02-21T22:03:49.074281Z  INFO ztunnel::inpod::statemanager: pod delete request, draining proxy
2024-02-21T22:04:58.446444Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("1e054806-e667-4109-a5af-08b3e6ba0c42") received netns, starting proxy
{{< /text >}}

You should also be able to confirm that sockets are open and in listening state on ports 15001, 15006 and 15008 within an application's network namespace as follows.

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=sleep -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it -n ambient-demo  --image nicolaka/netshoot  -- ss -ntlp
Defaulting debug container name to debugger-nhd4d.
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      128        127.0.0.1:15080      0.0.0.0:*
LISTEN 0      128                *:15006            *:*
LISTEN 0      128                *:15001            *:*
LISTEN 0      128                *:15008            *:*
{{< /text >}}

In order to view the iptables rules setup inside one of the application pods, execute the command shown in the following example. The command output shows that additional Istio specific chains are added into the NAT and Mangle tables in netfilter/ iptables within the application pod's network namespace and traffic that is coming into the pod on TCP port 15008 or 15006 is redirected into the ztunnel proxy for ingress Ambient processing whereas traffic leaving the pod is redirected to ztunnel's port 15001 for egress processing prior to being sent out by ztunnel using HBONE encapsulation.

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=sleep -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it --image gcr.io/istio-release/base --profile=netadmin -n ambient-demo -- iptables-save

Defaulting debug container name to debugger-m44qc.
# Generated by iptables-save v1.8.7 on Wed Feb 21 20:38:16 2024
*mangle
:PREROUTING ACCEPT [320:53261]
:INPUT ACCEPT [23753:267657744]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [23352:134432712]
:POSTROUTING ACCEPT [23352:134432712]
:ISTIO_OUTPUT - [0:0]
:ISTIO_PRERT - [0:0]
-A PREROUTING -j ISTIO_PRERT
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -m connmark --mark 0x111/0xfff -j CONNMARK --restore-mark --nfmask 0xffffffff --ctmask 0xffffffff
-A ISTIO_PRERT -m mark --mark 0x539/0xfff -j CONNMARK --set-xmark 0x111/0xfff
-A ISTIO_PRERT -s 169.254.7.127/32 -p tcp -m tcp -j ACCEPT
-A ISTIO_PRERT ! -d 127.0.0.1/32 -i lo -p tcp -j ACCEPT
-A ISTIO_PRERT -p tcp -m tcp --dport 15008 -m mark ! --mark 0x539/0xfff -j TPROXY --on-port 15008 --on-ip 0.0.0.0 --tproxy-mark 0x111/0xfff
-A ISTIO_PRERT -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A ISTIO_PRERT ! -d 127.0.0.1/32 -p tcp -m mark ! --mark 0x539/0xfff -j TPROXY --on-port 15006 --on-ip 0.0.0.0 --tproxy-mark 0x111/0xfff
COMMIT
# Completed on Wed Feb 21 20:38:16 2024
# Generated by iptables-save v1.8.7 on Wed Feb 21 20:38:16 2024
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [175:13694]
:POSTROUTING ACCEPT [205:15494]
:ISTIO_OUTPUT - [0:0]
-A OUTPUT -j ISTIO_OUTPUT
-A ISTIO_OUTPUT -d 169.254.7.127/32 -p tcp -m tcp -j ACCEPT
-A ISTIO_OUTPUT -p tcp -m mark --mark 0x111/0xfff -j ACCEPT
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -o lo -j ACCEPT
-A ISTIO_OUTPUT ! -d 127.0.0.1/32 -p tcp -m mark ! --mark 0x539/0xfff -j REDIRECT --to-ports 15001
COMMIT
{{< /text >}}

