---
title: Ztunnel traffic redirection
description: Understand how traffic is redirected between pods and the ztunnel node proxy.
weight: 2
aliases:
  - /docs/ops/ambient/usage/traffic-redirection
  - /latest/docs/ops/ambient/usage/traffic-redirection
owner: istio/wg-networking-maintainers
test: no
---

In the context of ambient mode, _traffic redirection_ refers to data plane functionality that intercepts traffic sent to and from ambient-enabled workloads, routing it through the {{< gloss >}}ztunnel{{< /gloss >}} node proxies that handle the core data path. Sometimes the term _traffic capture_ is also used.

As ztunnel aims to transparently encrypt and route application traffic, a mechanism is needed to capture all traffic entering and leaving "in mesh" pods. This is a security critical task: if the ztunnel can be bypassed, authorization policies can be bypassed.

## Istio's in-pod traffic redirection model

The core design principle underlying ambient mode's in-pod traffic redirection is that the ztunnel proxy has the ability to perform data path capture inside the Linux network namespace of the workload pod. This is achieved via a cooperation of functionality between the [`istio-cni` node agent](/docs/setup/additional-setup/cni/) and the ztunnel node proxy. A key benefit of this model is that it enables Istio's ambient mode to work alongside any Kubernetes CNI plugin, transparently, and without impacting Kubernetes networking features.

The following figure illustrates the sequence of events when a new workload pod is started in (or added to) an ambient-enabled namespace.

{{< image width="100%"
link="./pod-added-to-ambient.svg"
alt="pod added to the ambient mesh flow"
>}}

The `istio-cni` node agent responds to CNI events such as pod creation and deletion, and also watches the underlying Kubernetes API server for events such as the ambient label being added to a pod or namespace.

The `istio-cni` node agent additionally installs a chained CNI plugin that is executed by the container runtime after the primary CNI plugin within that Kubernetes cluster executes. Its only purpose is to notify the `istio-cni` node agent when a new pod is created by the container runtime in a namespace that is already enrolled in ambient mode, and propagate the new pod context to `istio-cni`.

Once the `istio-cni` node agent is notified that a pod needs to be added to the mesh (either from the CNI plugin, if the pod is brand new, or from the Kubernetes API server, if the pod is already running but needs to be added), the following sequence of operations is performed:

- `istio-cni` enters the pod’s network namespace and establishes network redirection rules, such that packets entering and leaving the pod are intercepted and transparently redirected to the node-local ztunnel proxy instance listening on [well-known ports](https://github.com/istio/ztunnel/blob/master/ARCHITECTURE.md#ports) (15008, 15006, 15001).

- The `istio-cni` node agent then informs the ztunnel proxy, over a Unix domain socket, that it should establish local proxy listening ports inside the pod’s network namespace (on ports 15008, 15006, and 15001), and provides ztunnel with a low-level Linux [file descriptor](https://en.wikipedia.org/wiki/File_descriptor) representing the pod’s network namespace.
    - While typically sockets are created within a Linux network namespace by the process actually running inside that network namespace, it is perfectly possible to leverage Linux’s low-level socket API to allow a process running in one network namespace to create listening sockets in another network namespace, assuming the target network namespace is known at creation time.

- The node-local ztunnel internally spins up a new logical proxy instance and listen port set, dedicated to the newly-added pod. Note that this is still running within the same process, and is merely a dedicated task for the pod.

- Once the in-pod redirect rules are in place and the ztunnel has established the listen ports, the pod is added in the mesh and traffic begins flowing through the node-local ztunnel.

Traffic to and from pods in the mesh will be fully encrypted with mTLS by default.

Data will now enter and leave the pod network namespace encrypted. Every pod in the mesh has the ability to enforce mesh policy and securely encrypt traffic, even though the user application running in the pod has no awareness of either.

This diagram illustrates how encrypted traffic flows between pods in the ambient mesh in the new model:

{{< image width="100%"
    link="./traffic-flows-between-pods-in-ambient.svg"
    alt="HBONE traffic flows between pods in the ambient mesh"
    >}}

## Observing and debugging traffic redirection in ambient mode

If traffic redirection is not working correctly in ambient mode, some quick checks can be made to help narrow down the problem. We recommend that troubleshooting begin with the steps described in the [ztunnel debugging guide](/docs/ambient/usage/troubleshoot-ztunnel/).

### Check the ztunnel proxy logs

When an application pod is part of an ambient mesh, you can check the ztunnel proxy logs to confirm the mesh is redirecting traffic. As shown in the example below, the ztunnel logs related to `inpod` indicate that in-pod redirection mode is enabled, the proxy has received the network namespace (netns) information about an ambient application pod, and has started proxying for it.

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

### Confirm the state of sockets

Follow the steps below to confirm that the sockets on ports 15001, 15006, and 15008 are open and in the listening state.

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=curl -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it -n ambient-demo  --image nicolaka/netshoot  -- ss -ntlp
Defaulting debug container name to debugger-nhd4d.
State  Recv-Q Send-Q Local Address:Port  Peer Address:PortProcess
LISTEN 0      128        127.0.0.1:15080      0.0.0.0:*
LISTEN 0      128                *:15006            *:*
LISTEN 0      128                *:15001            *:*
LISTEN 0      128                *:15008            *:*
{{< /text >}}

### Check the iptables rules setup

To view the iptables rules setup inside one of the application pods, execute this command:

{{< text bash >}}
$ kubectl debug $(kubectl get pod -l app=curl -n ambient-demo -o jsonpath='{.items[0].metadata.name}') -it --image gcr.io/istio-release/base --profile=netadmin -n ambient-demo -- iptables-save

Defaulting debug container name to debugger-m44qc.
# Generated by iptables-save
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
# Completed
# Generated by iptables-save
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

The command output shows that additional Istio-specific chains are added to the NAT and Mangle tables in netfilter/iptables within the application pod's network namespace. All TCP traffic coming into the pod is redirected to the ztunnel proxy for ingress processing. If the traffic is plaintext (source port != 15008), it will be redirected to the in-pod ztunnel plaintext listening port 15006. If the traffic is HBONE (source port == 15008), it will be redirected to the in-pod ztunnel HBONE listening port 15008. Any TCP traffic leaving the pod is redirected to ztunnel's port 15001 for egress processing, before being sent out by ztunnel using HBONE encapsulation.
