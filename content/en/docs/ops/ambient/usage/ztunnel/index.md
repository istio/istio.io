---
title: L4 Networking & mTLS with Ztunnel
description: User guide for Istio Ambient L4 networking and mTLS using ztunnel proxy.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

{{< boilerplate ambient-alpha-warning >}}

## Introduction {#introsection}

This guide describes in-depth the functionality and usage of the ztunnel proxy and Layer-4 networking functions in Istio ambient mesh. To simply try out Istio ambient mesh, follow the [Ambient Quickstart](/docs/ops/ambient/getting-started/) instead. This guide follows a user journey and works through multiple examples to detail the design and architecture of Istio ambient. It is highly recommended to follow the topics linked below in sequence.

* [Introduction](#introsection)
* [Current Caveats](#caveats)
* [Functional Overview](#functionaloverview)
* [Deploying an Application](#deployapplication)
* [Monitoring the ztunnel proxy & L4 networking](#monitoringzt)
* [L4 Authorization Policy](#l4auth)
* [Ambient Interoperability with non-Ambient endpoints](#interop)

The ztunnel (Zero Trust Tunnel) component is a purpose-built per-node proxy for Istio ambient mesh. Since workload pods no longer require proxies running in sidecars in order to participate in the mesh, Istio in ambient mode is informally also referred to as "sidecar-less" mesh.

{{< tip >}}
Pods/workloads using sidecar proxies can co-exist within the same mesh as pods that operate in ambient mode. Mesh pods that use sidecar proxies can also interoperate with pods in the same Istio mesh that are running in ambient mode. The term ambient mesh refers to an Istio mesh that has a superset of the capabilities and hence can support mesh pods that use either type of proxying.
{{< /tip >}}

The ztunnel node proxy is responsible for securely connecting and authenticating workloads within the ambient mesh. The ztunnel proxy is written in Rust and is intentionally scoped to handle L3 and L4 functions in the ambient mesh such as mTLS, authentication, L4 authorization and telemetry. Ztunnel does not terminate workload HTTP traffic or parse workload HTTP headers. The ztunnel ensures L3 and L4 traffic is efficiently and securely transported to **waypoint proxies**, where the full suite of Istio’s L7 functionality, such as HTTP telemetry and load balancing, is implemented. The term "Secure Overlay Networking" is used informally to collectively describe the set of L4 networking functions implemented in an ambient mesh via the ztunnel proxy. At the transport layer, this is implemented via an HTTP CONNECT-based traffic tunneling protocol called HBONE which is described in a [later section](#hbonesection) of this guide.

Some use cases of Istio in ambient mode may be addressed solely via the L4 secure overlay networking features, and will not need L7 features thereby not requiring deployment of a waypoint proxy. Other use cases requiring advanced traffic management and L7 networking features will require deployment of a waypoint proxy. This guide focuses on functionality related to the L4 secure overlay network using ztunnel proxies. This guide refers to L7 only when needed to describe some L4 ztunnel function. Other guides are dedicated to cover the advanced L7 networking functions and the use of waypoint proxies in detail.

| Application Deployment Use Case | Istio Ambient Mesh Configuration |
| ------------- | ------------- |
| Zero Trust networking via mutual-TLS, encrypted and tunneled data transport of client application traffic, L4 authorization, L4 telemetry | Baseline Ambient Mesh with ztunnel proxy networking |
| Application requires L4 Mutual-TLS plus advanced Istio traffic management features (incl VirtualService, L7 telemetry, L7 Authorization) | Full Istio Ambient Mesh configuration both ztunnel proxy and waypoint proxy based networking |

## Current Caveats {#caveats}

Ztunnel proxies are automatically installed when one of the supported installation methods is used to install Istio ambient mesh. The minimum Istio version required for Istio ambient mode is `1.18.0`. In general Istio in ambient mode supports the existing Istio APIs that are supported in sidecar proxy mode. Since the ambient functionality is currently at an alpha release level, the following is a list of feature restrictions or caveats in the current release of Istio's ambient functionality (as of the `1.19.0` release). These restrictions are expected to be addressed/removed in future software releases as ambient graduates to beta and eventually General Availability.

1. **Kubernetes (K8s) only:** Istio in ambient mode is currently only supported for deployment on Kubernetes clusters. Deployment on non-Kubernetes endpoints such as virtual machines is not currently supported.

1. **No Istio multi-cluster support:** Only single cluster deployments are currently supported for Istio ambient mode.

1. **K8s CNI restrictions:** Istio in ambient mode does not currently work with every Kubernetes CNI implementation. Additionally, with some plugins, certain CNI functions (in particular Kubernetes `NetworkPolicy` and Kubernetes Service Load balancing features) may get transparently bypassed in the presence of Istio ambient mode. The exact set of supported CNI plugins as well as any CNI feature caveats are currently under test and will be formally documented as Istio's ambient mode approaches the beta release.

1. **TCP/IPv4 only:** In the current release, TCP over IPv4 is the only protocol supported for transport on an Istio secure overlay tunnel (this includes protocols such as HTTP that run between application layer endpoints on top of the TCP/ IPv4 connection).

1. **No dynamic switching to ambient mode:** ambient mode can only be enabled on a new Istio mesh control plane that is deployed using ambient profile or ambient helm configuration. An existing Istio mesh deployed using a pre-ambient profile for instance can not be dynamically switched to also enable ambient mode operation.

1. **Restrictions with Istio `PeerAuthentication`:** as of the time of writing, the `PeerAuthentication` resource is not supported by all components (i.e. waypoint proxies) in Istio ambient mode. Hence it is recommended to only use the `STRICT` mTLS mode currently. Like many of the other alpha stage caveats, this shall be addressed as the feature moves toward beta status.

1. **istioctl CLI gaps:** There may be some minor functional gaps in areas such as Istio CLI output displays when it comes to displaying or monitoring Istio's ambient mode related information. These will be addressed as the feature matures.

### Environment used for this guide

The examples in this guide used a deployment of Istio version `1.19.0` on a `kind` cluster of version `0.20.0` running Kubernetes version `1.27.3`.

The minimum Istio version needed for ambient functions is 1.18.0 and the minimum Kubernetes version needed is `1.24.0`. The examples below require a cluster with more than 1 worker node in order to explain how cross-node traffic operates. Refer to the [installation user guide](/docs/ops/ambient/install/) or [getting started guide](/docs/ops/ambient/getting-started/) for information on installing Istio in ambient mode on a Kubernetes cluster.

## Functional Overview {#functionaloverview}

The functional behavior of the ztunnel proxy can be divided into its data plane behavior and its interaction with the Istio control plane. This section takes a brief look at these two aspects - detailed description of the internal design of the ztunnel proxy is out of scope for this guide.

### Control plane overview

The figure shows an overview of the control plane related components and flows between ztunnel proxy and the `istiod` control plane.

{{< image width="100%"
link="ztunnel-architecture.png"
caption="Ztunnel architecture"
>}}

The ztunnel proxy uses xDS APIs to communicate with the Istio control plane (`istiod`). This enables the fast, dynamic configuration updates required in modern distributed systems. The ztunnel proxy also obtains mTLS certificates for the Service Accounts of all pods that are scheduled on its Kubernetes node using xDS. A single ztunnel proxy may implement L4 data plane functionality on behalf of any pod sharing it's node which requires efficiently obtaining relevant configuration and certificates. This multi-tenant architecture contrasts sharply with the sidecar model where each application pod has its own proxy.

It is also worth noting that in ambient mode, a simplified set of resources are used in the xDS APIs for ztunnel proxy configuration. This results in improved performance (having to transmit and process a much smaller set of information that is sent from istiod to the ztunnel proxies) and improved troubleshooting.

### Data plane overview

This section briefly summarizes key aspects of the data plane functionality.

#### Ztunnel to ztunnel datapath

The first scenario is ztunnel to ztunnel L4 networking. This is depicted in the following figure.

{{< image width="100%"
link="ztunnel-datapath-1.png"
caption="Basic ztunnel L4-only datapath"
>}}

The figure depicts ambient pod workloads running on two nodes W1 and W2 of a Kubernetes cluster. There is a single instance of the ztunnel proxy on each node. In this scenario, application client pods C1, C2 and C3 need to access a service provided by pod S1 and there is no requirement for advanced L7 features such as L7 traffic routing or L7 traffic management so no Waypoint proxy is needed.

The figure shows that pods C1 and C2 running on node W1 connect with pod S1 running on node W2 and their TCP traffic is tunneled through a single shared HBONE tunnel instance that has been created between the ztunnel proxy pods of each node. Mutual TLS (mTLS) is used for encryption as well as mutual authentication of traffic being tunneled. SPIFFE identities are used to identify the workloads on each side of the connection. The term `HBONE` (for HTTP Based Overlay Network Encapsulation) is used in Istio ambient to refer to a technique for transparently and securely tunneling TCP packets encapsulated within HTTPS packets. Some brief additional notes on HBONE are provided in a following subsection.

Note that the figure shows that local traffic - from pod C3 to destination pod S1 on worker node W2 - also traverses the local ztunnel proxy instance so that L4 traffic management functions such as L4 Authorization and L4 Telemetry are enforced identically on traffic, whether or not it crosses a node boundary.

#### Ztunnel datapath via waypoint

The next figure depicts the data path for a use case which requires advanced L7 traffic routing, management or policy handling. Here ztunnel uses HBONE tunneling to send traffic to a waypoint proxy for L7 processing. After processing, the waypoint sends traffic via a second HBONE tunnel to the ztunnel on the node hosting the selected service destination pod. In general the waypoint proxy may or may not be located on the same nodes as the source or destination pod.

{{< image width="100%"
link="ztunnel-waypoint-datapath.png"
caption="Ztunnel datapath via an interim waypoint"
>}}

#### Ztunnel datapath hair-pinning

{{< warning >}}
As noted earlier, some ambient functions may change as the project moves to beta status and beyond. This feature (hair-pinning) is an example of a feature that is currently available in the alpha version of ambient and under review for possible modification as the project evolves.
{{< /warning >}}

It was noted earlier that traffic is always sent to a destination pod by first sending it to the ztunnel proxy on the same node as the destination pod. But what if the sender is either completely outside the Istio ambient mesh and hence does not initiate HBONE tunnels to the destination ztunnel first? What if the sender is malicious and trying to send traffic directly to an ambient pod destination, bypassing the destination ztunnel proxy?

There are two scenarios here, both of which are depicted in the following figure:

1. Traffic stream B1 is being received by node W2 outside of any HBONE tunnel and directly addressed to ambient pod S1's IP address for some reason (possibly because the traffic source is not an ambient pod). As shown in the figure, the ztunnel traffic redirection logic intercepts such traffic and redirects it via the local ztunnel proxy for destination-side proxy processing and possible filtering based on AuthorizationPolicy prior to sending it into pod S1.
1. Traffic stream G1 is being received by the ztunnel proxy of node W2 (possibly over an HBONE tunnel). However, the ztunnel proxy checks that the destination service requires waypoint processing and yet the source sending this traffic is not a waypoint or is not associated with this destination service. In this case, the ztunnel proxy hairpins the traffic towards one of the waypoints associated with the destination service from where it can then be delivered to any pod implementing the destination service (possibly to pod S1 itself, as shown in the figure).

{{< image width="100%"
link="ztunnel-hairpin.png"
caption="Ztunnel traffic hair-pinning"
>}}

### Note on HBONE {#hbonesection}

HBONE (HTTP Based Overlay Network Encapsulation) is an Istio-specific term. It refers to the use of standard HTTP tunneling via the [HTTP CONNECT](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/CONNECT) method to transparently tunnel application packets/ byte streams. In its current implementation within Istio, it transports TCP packets only by tunneling these transparently using the HTTP CONNECT method, uses [HTTP/2](https://httpwg.org/specs/rfc7540.html), with encryption and mutual authentication provided by [mutual TLS](https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/) and the HBONE tunnel itself runs on TCP port 15008. The overall HBONE packet format from IP layer onwards is depicted in the following figure.

{{< image width="100%"
link="hbone-packet.png"
caption="HBONE L3 packet format"
>}}

In future Istio Ambient may also support [HTTP/3 (QUIC)](https://datatracker.ietf.org/doc/html/rfc9114) based transport and will be used to transport all types of L3 and L4 packets including native IPv4, IPv6, UDP by leveraging new standards such as CONNECT-UDP and CONNECT-IP being developed as part of the [IETF MASQUE](https://ietf-wg-masque.github.io/) working group. Such additional use cases of HBONE and HTTP tunneling in Istio's ambient mode are currently for further investigation.

## Deploying an Application {#deployapplication}

Normally, a user with Istio admin privileges will deploy the Istio mesh infrastructure. Once Istio is successfully deployed in ambient mode, it will be transparently available to applications deployed by all users in namespaces that have been annotated to use Istio ambient as illustrated in the examples below.

### Basic application deployment without Ambient

First, deploy a simple HTTP client server application without making it part of the Istio ambient mesh. Execute the following examples from the top of a local Istio repository or Istio folder created by downloading the istioctl client as described in Istio guides.

{{< text bash >}}
$ kubectl create ns ambient-demo
$ kubectl apply -f samples/httpbin/httpbin.yaml -n ambient-demo
$ kubectl apply -f samples/sleep/sleep.yaml -n ambient-demo
$ kubectl apply -f samples/sleep/notsleep.yaml -n ambient-demo
$ kubectl scale deployment sleep --replicas=2 -n ambient-demo
{{< /text >}}

These manifests deploy multiple replicas of the `sleep` and `notsleep` pods which will be used as clients for the httpbin service pod (for simplicity, the command-line outputs have been deleted in the code samples above).

{{< text bash >}}
$ kubectl wait -n ambient-demo --for=condition=ready pod --selector=app=httpbin --timeout=90s
pod/httpbin-648cd984f8-7vg8w condition met
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n ambient-demo
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-648cd984f8-7vg8w   1/1     Running   0          31m
notsleep-bb6696574-2tbzn   1/1     Running   0          31m
sleep-69cfb4968f-mhccl     1/1     Running   0          31m
sleep-69cfb4968f-rhhhp     1/1     Running   0          31m
{{< /text >}}

{{< text bash >}}
$ kubectl get svc httpbin -n ambient-demo
NAME      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
httpbin   ClusterIP   10.110.145.219   <none>        8000/TCP   28m
{{< /text >}}

Note that each application pod has just 1 container running in it (the "1/1" indicator) and that `httpbin` is an http service listening on `ClusterIP` service port 8000. You should now be able to `curl` this service from either client pod and confirm it returns the `httpbin` web page as shown below. At this point there is no `TLS` of any form being used.

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo  -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

### Enabling ambient for an application

You can now enable ambient for the application deployed in the prior subsection by simply adding the label `istio.io/dataplane-mode=ambient` to the application's namespace as shown below. Note that this example focuses on a fresh namespace with new, sidecar-less workloads captured via ambient mode only. Later sections will describe how conflicts are resolved in hybrid scenarios that mix sidecar mode and ambient mode within the same mesh.

{{< text bash >}}
$ kubectl label namespace ambient-demo istio.io/dataplane-mode=ambient
$ kubectl  get pods -n ambient-demo
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-648cd984f8-7vg8w   1/1     Running   0          78m
notsleep-bb6696574-2tbzn   1/1     Running   0          77m
sleep-69cfb4968f-mhccl     1/1     Running   0          78m
sleep-69cfb4968f-rhhhp     1/1     Running   0          78m
{{< /text >}}

Note that after ambient is enabled for the namespace, every application pod still only has 1 container, and the uptime of these pods indicates these were not restarted in order to enable ambient mode (unlike `sidecar` mode which does restart application pods when the sidecar proxies are injected). This results in better user experience and operational performance since ambient mode can seamlessly be enabled (or disabled) completely transparently as far as the application pods are concerned.

Initiate a `curl` request again from one of the client pods to the service to verify that traffic continues to flow while ambient mode.

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo  -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

This indicates the traffic path is working. The next section looks at how to monitor the configuration and data plane of the ztunnel proxy to confirm that traffic is correctly using the ztunnel proxy.

## Monitoring the ztunnel proxy & L4 networking {#monitoringzt}

This section describes some options for monitoring the ztunnel proxy configuration and data path. This information can also help with some high level troubleshooting and in identifying information that would be useful to collect and provide in a bug report if there are any problems. Additional advanced monitoring of ztunnel internals and advanced troubleshooting is out of scope for this guide.

### Viewing ztunnel proxy state

As indicated previously, the ztunnel proxy on each node gets configuration and discovery information from the istiod component via xDS APIs. Use the `istioctl proxy-config` command shown below to view discovered workloads as seen by a ztunnel proxy as well as secrets holding the TLS certificates that the ztunnel proxy has received from the istiod control plane to use in mTLS signaling on behalf of the local workloads.

In the first example, you see all the workloads and control plane components that the specific ztunnel pod is currently tracking including information about the IP address and protocol to use when connecting to that component and whether there is a Waypoint proxy associated with that workload. This example can repeated with any of the other ztunnel pods in the system to display their current configuration.

{{< text bash >}}
$ export ZTUNNEL=$(kubectl get pods -n istio-system -o wide | grep ztunnel -m 1 | sed 's/ .*//')
$ echo "$ZTUNNEL"
{{< /text >}}

{{< text bash >}}
$ istioctl proxy-config workloads "$ZTUNNEL".istio-system
NAME                                   NAMESPACE          IP         NODE               WAYPOINT PROTOCOL
coredns-6d4b75cb6d-ptbhb               kube-system        10.240.0.2 amb1-control-plane None     TCP
coredns-6d4b75cb6d-tv5nz               kube-system        10.240.0.3 amb1-control-plane None     TCP
httpbin-648cd984f8-2q9bn               ambient-demo       10.240.1.5 amb1-worker        None     HBONE
httpbin-648cd984f8-7dglb               ambient-demo       10.240.2.3 amb1-worker2       None     HBONE
istiod-5c7f79574c-pqzgc                istio-system       10.240.1.2 amb1-worker        None     TCP
local-path-provisioner-9cd9bd544-x7lq2 local-path-storage 10.240.0.4 amb1-control-plane None     TCP
notsleep-bb6696574-r4xjl               ambient-demo       10.240.2.5 amb1-worker2       None     HBONE
sleep-69cfb4968f-mwglt                 ambient-demo       10.240.1.4 amb1-worker        None     HBONE
sleep-69cfb4968f-qjmfs                 ambient-demo       10.240.2.4 amb1-worker2       None     HBONE
ztunnel-5jfj2                          istio-system       10.240.0.5 amb1-control-plane None     TCP
ztunnel-gkldc                          istio-system       10.240.1.3 amb1-worker        None     TCP
ztunnel-xxbgj                          istio-system       10.240.2.2 amb1-worker2       None     TCP
{{< /text >}}

In the second example, you see the list of TLS certificates that this ztunnel proxy instance has received from istiod to use in TLS signaling.

{{< text bash >}}
$ istioctl proxy-config secrets "$ZTUNNEL".istio-system
NAME                                                  TYPE           STATUS        VALID CERT     SERIAL NUMBER                        NOT AFTER                NOT BEFORE
spiffe://cluster.local/ns/ambient-demo/sa/httpbin     CA             Available     true           edf7f040f4b4d0b75a1c9a97a9b13545     2023-09-20T19:02:00Z     2023-09-19T19:00:00Z
spiffe://cluster.local/ns/ambient-demo/sa/httpbin     Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/ambient-demo/sa/sleep       CA             Available     true           3b9dbea3b0b63e56786a5ea170995f48     2023-09-20T19:00:44Z     2023-09-19T18:58:44Z
spiffe://cluster.local/ns/ambient-demo/sa/sleep       Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/istio-system/sa/istiod      CA             Available     true           885ee63c08ef9f1afd258973a45c8255     2023-09-20T18:26:34Z     2023-09-19T18:24:34Z
spiffe://cluster.local/ns/istio-system/sa/istiod      Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
spiffe://cluster.local/ns/istio-system/sa/ztunnel     CA             Available     true           221b4cdc4487b60d08e94dc30a0451c6     2023-09-20T18:26:35Z     2023-09-19T18:24:35Z
spiffe://cluster.local/ns/istio-system/sa/ztunnel     Cert Chain     Available     true           ec30e0e1b7105e3dce4425b5255287c6     2033-09-16T18:26:19Z     2023-09-19T18:26:19Z
{{< /text >}}

Using these CLI commands, a user can check that ztunnel proxies are getting configured with all the expected workloads and TLS certificates and missing information can be used for troubleshooting to explain any potential observed networking errors. A user may also use the `all` option to view all parts of the proxy-config with a single CLI command and the JSON output formatter as shown in the example below to display the complete set of available state information.

{{< text bash >}}
$ istioctl proxy-config all "$ZTUNNEL".istio-system -o json | jq
{{< /text >}}

Note that when used with a ztunnel proxy instance, not all options of the `istioctl proxy-config` CLI are supported since some apply only to sidecar proxies.

An advanced user may also view the raw configuration dump of a ztunnel proxy via a `curl` to the endpoint inside a ztunnel proxy pod as shown in the following example.

{{< text bash >}}
$ kubectl exec ds/ztunnel -n istio-system  -- curl http://localhost:15000/config_dump | jq .
{{< /text >}}

### Viewing Istiod state for ztunnel xDS resources

Sometimes an advanced user may want to view the state of ztunnel proxy config resources as maintained in the istiod control plane, in the format of the xDS API resources defined specially for ztunnel proxies. This can be done by exec-ing into the istiod pod and obtaining this information from port 15014 for a given ztunnel proxy as shown in the example below. This output can then also be saved and viewed with a JSON pretty print formatter utility for easier browsing (not shown in the example).

{{< text bash >}}
$ kubectl exec -n istio-system deploy/istiod -- curl localhost:15014/debug/config_dump?proxyID="$ZTUNNEL".istio-system | jq
{{< /text >}}

### Verifying ztunnel traffic logs

Send some traffic from a client `sleep` pod to the `httpbin` service.

{{< text bash >}}
$ kubectl -n ambient-demo exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://httpbin:8000/; done'
HTTP/1.1 200 OK
Server: gunicorn/19.9.0
--snip--
{{< /text >}}

The response displayed confirms the client pod receives responses from the service. Now check logs of the ztunnel pods to confirm the traffic was sent over the HBONE tunnel.

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
2023-08-14T09:15:46.542651Z  INFO outbound{id=7d344076d398339f1e51a74803d6c854}: ztunnel::proxy::outbound: proxying to 10.240.2.10:80 using node local fast path
2023-08-14T09:15:46.542882Z  INFO outbound{id=7d344076d398339f1e51a74803d6c854}: ztunnel::proxy::outbound: complete dur=269.272µs
--snip--
{{< /text >}}

These log messages confirm the traffic indeed used the ztunnel proxy in the datapath. Additional fine-grained monitoring can be done by checking logs on the specific ztunnel proxy instances that are on the same nodes as the source and destination pods of traffic. If these logs are not seen, then a possibility is that traffic redirection may not be working correctly. Detailed description of monitoring and troubleshooting of the traffic redirection logic is out of scope for this guide. Note that as mentioned previously, with ambient traffic always traverses the ztunnel pod even when the source and destination of the traffic are on the same compute node.

### Monitoring and Telemetry via Prometheus, Grafana, Kiali

In addition to checking ztunnel logs and other monitoring options noted above, one can also use normal Istio monitoring and telemetry functions to monitor application traffic within an Istio Ambient mesh.
The use of Istio in ambient mode does not change this behavior. Since this functionality is largely unchanged in Istio ambient mode from Istio sidecar mode, these details are not repeated in this guide. Please refer to:

* [Prometheus installation](/docs/ops/integrations/prometheus/#installation)
* [Kiali installation](/docs/ops/integrations/kiali/#installation)
* [Istio metrics](/docs/reference/config/metrics/)
* [Querying Metrics from Prometheus](/docs/tasks/observability/metrics/querying-metrics/)

One point to note is that in case of a service that is only using ztunnel and L4 networking, the Istio metrics reported will currently only be the L4 TCP metrics (namely `istio_tcp_sent_bytes_total`, `istio_tcp_received_bytes_total`, `istio_tcp_connections_opened_total`, `istio_tcp_connections_closed_total`). The full set of Istio and Envoy metrics will be reported when a Waypoint proxy is involved.

### Verifying ztunnel load balancing

The ztunnel proxy automatically performs client-side load balancing if the destination is a service with multiple endpoints. No additional configuration is needed. The ztunnel load balancing algorithm is an internally fixed L4 Round Robin algorithm that distributes traffic based on L4 connection state and is not user configurable.

{{< tip >}}
If the destination is a service with multiple instances or pods and there is no Waypoint associated with the destination service, then the source ztunnel proxy performs L4 load balancing directly across these instances or service backends and then sends traffic via the remote ztunnel proxies associated with those backends. If the destination service does have a Waypoint deployment (with one or more backend instances of the Waypoint proxy) associated with it, then the source ztunnel proxy performs load balancing by distributing traffic across these Waypoint proxies and sends traffic via the remote ztunnel proxies associated with the Waypoint proxy instances.
{{< /tip >}}

Now repeat the previous example with multiple replicas of the service pod and verify that client traffic is load balanced across the service replicas. Wait for all pods in the ambient-demo namespace to go into Running state before continuing to the next step.

{{< text bash >}}
$ kubectl -n ambient-demo scale deployment httpbin --replicas=2 ; kubectl wait --for condition=available  deployment/httpbin -n ambient-demo
deployment.apps/httpbin scaled
deployment.apps/httpbin condition met
{{< /text >}}

{{< text bash >}}
$ kubectl -n ambient-demo exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://httpbin:8000/; done'
{{< /text >}}

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | grep -E "inbound|outbound"
--snip--

2023-08-14T09:33:24.969996Z  INFO inbound{id=ec177a563e4899869359422b5cdd1df4 peer_ip=10.240.2.16 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.240.1.11:80
2023-08-14T09:33:25.028601Z  INFO inbound{id=1ebc3c7384ee68942bbb7c7ed866b3d9 peer_ip=10.240.2.16 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.240.1.11:80

--snip--

2023-08-14T09:33:25.226403Z  INFO outbound{id=9d99723a61c9496532d34acec5c77126}: ztunnel::proxy::outbound: proxy to 10.240.1.11:80 using HBONE via 10.240.1.11:15008 type Direct
2023-08-14T09:33:25.273268Z  INFO outbound{id=9d99723a61c9496532d34acec5c77126}: ztunnel::proxy::outbound: complete dur=46.9099ms
2023-08-14T09:33:25.276519Z  INFO outbound{id=cc87b4de5ec2ccced642e22422ca6207}: ztunnel::proxy::outbound: proxying to 10.240.2.10:80 using node local fast path
2023-08-14T09:33:25.276716Z  INFO outbound{id=cc87b4de5ec2ccced642e22422ca6207}: ztunnel::proxy::outbound: complete dur=231.892µs

--snip--
{{< /text >}}

Here note the logs from the ztunnel proxies first indicating the http CONNECT request to the new destination pod (10.240.1.11) which indicates the setup of the HBONE tunnel to ztunnel on the node hosting the additional destination service pod. This is then followed by logs indicating the client traffic being sent to both 10.240.1.11 and 10.240.2.10 which are the two destination pods providing the service. Also note that the data path is performing client-side load balancing in this case and not depending on Kubernetes service load balancing. In your setup these numbers will be different and will match the pod addresses of the httpbin pods in your cluster.

This is a round robin load balancing algorithm and is separate from and independent of any load balancing algorithm that may be configured within a `VirtualService`'s `TrafficPolicy` field, since as discussed previously, all aspects of `VirtualService` API objects are instantiated on the Waypoint proxies and not the ztunnel proxies.

### Pod selection logic for ambient and sidecar modes

Istio with sidecar proxies can co-exist with ambient based node level proxies within the same compute cluster. It is important to ensure that the same pod or namespace does not get configured to use both a sidecar proxy and an ambient node-level proxy. However, if this does occur, currently sidecar injection takes precedence for such a pod or namespace.

Note that two pods within the same namespace could in theory be set to use different modes by labeling individual pods separately from the namespace label, however this is not recommended. For most common use cases it is recommended that a single mode be used for all pods within a single namespace.

The exact logic to determine whether a pod is set up to use ambient mode is as follows.

1. The `istio-cni` plugin configuration exclude list configured in `cni.values.excludeNamespaces` is used to skip namespaces in the exclude list.
1. `ambient` mode is used for a pod if

    * The namespace has label `istio.io/dataplane-mode=ambient`
    * The annotation `sidecar.istio.io/status` is not present on the pod
    * `ambient.istio.io/redirection` is not `disabled`

The simplest option to avoid a configuration conflict is for a user to ensure that for each namespace, it either has the label for sidecar injection (`istio-injection=enabled`) or for ambient data plane mode (`istio.io/dataplane-mode=ambient`) but never both.

## L4 Authorization Policy {#l4auth}

As mentioned previously, the ztunnel proxy performs Authorization policy enforcement when it requires only L4 traffic processing in order to enforce the policy in the data plane and there are no Waypoints involved. The actual enforcement point is at the receiving (or server side) ztunnel proxy in the path of a connection.

Apply a basic L4 Authorization policy for the already deployed `httpbin` application as shown in the example below.

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
EOF
{{< /text >}}

The behavior of the `AuthorizationPolicy` API has the same functional behavior in Istio ambient mode as in sidecar mode. When there is no `AuthorizationPolicy` provisioned, then the default action is `ALLOW`. Once the policy above is provisioned, pods matching the selector in the policy (i.e. app:httpbin) only allow traffic explicitly whitelisted which in this case is sources with principal (i.e. identity) of `cluster.local/ns/ambient-demo/sa/sleep`. Now as shown below, if you try the curl operation to the `httpbin` service from the `sleep` pods, it still works but the same operation is blocked when initiated from the `notsleep` pods.

Note that this policy performs an explicit `ALLOW` action on traffic from sources with principal (i.e. identity) of `cluster.local/ns/ambient-demo/sa/sleep` and hence traffic from all other sources will be denied.

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/notsleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

Note that there are no waypoint proxies deployed and yet this `AuthorizationPolicy` is getting enforced and this is because this policy only requires L4 traffic processing which can be performed by ztunnel proxies. These policy actions can be further confirmed by checking ztunnel logs and looking for logs that indicate RBAC actions as shown in the following example.

{{< text bash >}}
$ kubectl logs ds/ztunnel -n istio-system  | grep -E RBAC
-- snip --
2023-10-10T23:14:00.534962Z  INFO inbound{id=cc493da5e89877489a786fd3886bd2cf peer_ip=10.240.2.2 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/notsleep}: ztunnel::proxy::inbound: RBAC rejected conn=10.240.2.2(spiffe://cluster.local/ns/ambient-demo/sa/notsleep)->10.240.1.2:80
2023-10-10T23:15:33.339867Z  INFO inbound{id=4c4de8de802befa5da58a165a25ff88a peer_ip=10.240.2.2 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/notsleep}: ztunnel::proxy::inbound: RBAC rejected conn=10.240.2.2(spiffe://cluster.local/ns/ambient-demo/sa/notsleep)->10.240.1.2:80
{{< /text >}}

{{< warning >}}
If an `AuthorizationPolicy` has been configured that requires any traffic processing beyond L4, and if no waypoint proxies are configured for the destination of the traffic, then ztunnel proxy will simply drop all traffic as a defensive move. Hence, check to ensure that either all rules involve L4 processing only or else if non-L4 rules are unavoidable, then waypoint proxies are also configured to handle policy enforcement.
{{< /warning >}}

As an example, modify the `AuthorizationPolicy` to include a check for the HTTP GET method as shown below. Now notice that both `sleep` and `notsleep` pods are blocked from sending traffic to the destination `httpbin` service.

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/notsleep -n ambient-demo -- curl httpbin:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

You can also confirm by viewing logs of specific ztunnel proxy pods (not shown in the example here) that it is always the ztunnel proxy on the node hosting the destination pod that actually enforces the policy.

Go ahead and delete this `AuthorizationPolicy` before continuing with the rest of the examples in the guide.

{{< text bash >}}
$ kubectl delete AuthorizationPolicy allow-sleep-to-httpbin  -n ambient-demo
{{< /text >}}

## Ambient Interoperability with non-ambient endpoints {#interop}

In the use cases so far, the traffic source and destination pods are both ambient pods. This section covers some mixed use cases where ambient endpoints need to communicate with non-ambient endpoints. As with prior examples in this guide, this section covers use cases that do not require waypoint proxies.

1. [East-West non-mesh pod to ambient mesh pod (and use of `PeerAuthentication` resource)](#ewnonmesh)
1. [East-West Istio sidecar proxy pod to ambient mesh pod](#ewside2ambient)
1. [North-South Ingress Gateway to ambient backend pods](#nsingress2ambient)

### East-West non-mesh pod to ambient mesh pod (and use of PeerAuthentication resource) {#ewnonmesh}

In the example below, the same `httpbin` service which has already been set up in the prior examples is accessed via client `sleep` pods that are running in a separate namespace that is not part of the Istio mesh. This example shows that East-west traffic between ambient mesh pods and non mesh pods is seamlessly supported. Note that as described previously, this use case leverages the traffic hair-pinning capability of ambient. Since the non-mesh pods initiate traffic directly to the backend pods without going through HBONE or ztunnel, at the destination node, traffic is redirected via the ztunnel proxy at the destination node to ensure that ambient authorization policy is applied (this can be verified by viewing logs of the appropriate ztunnel proxy pod on the destination node; the logs are not shown in the example snippet below for simplicity).

{{< text bash >}}
$ kubectl create namespace client-a
$ kubectl apply -f samples/sleep/sleep.yaml -n client-a
$ kubectl wait --for condition=available  deployment/sleep -n client-a
{{< /text >}}

Wait for the pods to get to Running state in the client-a namespace before continuing.

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

As shown in the example below, now add a `PeerAuthentication` resource with mTLS mode set to `STRICT`, in the ambient namespace and confirm that the same client's traffic is now rejected with an error indicating the request was rejected. This is because the client is using simple HTTP to connect to the server instead of an HBONE tunnel with mTLS. This is a possible method that can be used to prevent non-Istio sources from sending traffic to Istio ambient pods.

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: peerauth
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
command terminated with exit code 56
{{< /text >}}

Change the mTLS mode to `PERMISSIVE` and confirm that the ambient pods can once again accept non-mTLS connections including from non-mesh pods in this case.

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: peerauth
spec:
  mtls:
    mode: PERMISSIVE
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-a  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

### East-West Istio sidecar proxy pod to ambient mesh pod {#ewside2ambient}

This use case is that of seamless East-West traffic interoperability between an Istio pod using a sidecar proxy and an ambient pod within the same mesh.

The same httpbin service from the previous example is used but now add a client to access this service from another namespace which is labeled for sidecar injection. This also works automatically and transparently as shown in the example below. In this case the sidecar proxy running with the client automatically knows to use the HBONE control plane since the destination has been discovered to be an HBONE destination. The user does not need to do any special configuration to enable this.

{{< tip >}}
For sidecar proxies to use the HBONE/mTLS signaling option when communicating with ambient destinations, they need to be configured with `ISTIO_META_ENABLE_HBONE` set to true in the proxy metadata. This is automatically set for the user as default in the `MeshConfig` when using the `ambient` profile, hence the user does not need to do anything additional when using this profile.
{{< /tip >}}

{{< text bash >}}
$ kubectl create ns client-b
$ kubectl label namespace client-b istio-injection=enabled
$ kubectl apply -f samples/sleep/sleep.yaml -n client-b
$ kubectl wait --for condition=available  deployment/sleep -n client-b
{{< /text >}}

Wait for the pods to get to Running state in the client-b namespace before continuing.

{{< text bash >}}
$ kubectl exec deploy/sleep -n client-b  -- curl httpbin.ambient-demo.svc.cluster.local:8000 -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

Again, it can further be verified from viewing the logs of the ztunnel pod (not shown in the example) at the destination node that traffic does in fact use the HBONE and CONNECT based path from the sidecar proxy based source client pod to the ambient based destination service pod. Additionally, although not shown, it can also be verified that unlike the previous subsection, in this case even if you apply a `PeerAuthentication` resource to the namespace tagged for ambient mode, communication continues between client and service pods since both use the HBONE control and data planes relying on mTLS.

### North-South Ingress Gateway to ambient backend pods {#nsingress2ambient}

This section describes a use case for North-South traffic with an Istio Gateway exposing the httpbin service via the Kubernetes Gateway API. The gateway itself is running in a non-Ambient namespace and may be an existing gateway that is also exposing other services that are provided by non-ambient pods. Hence, this example shows that ambient workloads can also interoperate with Istio gateways that need not themselves be running in namespaces tagged for ambient mode of operation.

For this example, you can use `metallb` to provide a load balancer service on an IP addresses that is reachable from outside the cluster. The same example also works with other forms of North-South load balancing options. The example below assumes that you have already installed `metallb` in this cluster to provide the load balancer service including a pool of IP addresses for `metallb` to use for exposing services externally. Refer to the [`metallb` guide for kind](https://kind.sigs.k8s.io/docs/user/loadbalancer/) for instructions on setting up `metallb` on kind clusters or refer to the instructions from the [`metallb` documentation](https://metallb.universe.tf/installation/) appropriate for your environment.

This example uses the Kubernetes Gateway API for configuring the N-S gateway. Since this API is not currently provided as default in Kubernetes and kind distributions, you have to install the API CRDs first as shown in the example.

An instance of `Gateway` using the Kubernetes Gateway API CRDs will then be deployed to leverage this `metallb` load balancer service. The instance of Gateway runs in the istio-system namespace in this example to represent an existing Gateway running in a non-ambient namespace. Finally, an `HTTPRoute` will be provisioned with a backend reference pointing to the existing httpbin service that is running on an ambient pod in the ambient-demo namespace.

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.6.1" | kubectl apply -f -; }
{{< /text >}}

{{< tip >}}
{{< boilerplate gateway-api-future >}}
{{< boilerplate gateway-api-choose >}}
{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply -n ambient-demo -f - << EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
    namespace: istio-system
  rules:
  - backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

Next find the external service IP address on which the Gateway is listening and then access the httpbin service on this IP address (172.18.255.200 in the example below) from outside the cluster as shown below.

{{< text bash >}}
$ kubectl get service httpbin-gateway-istio -n istio-system
NAME                    TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                        AGE
httpbin-gateway-istio   LoadBalancer   10.110.30.25   172.18.255.200   15021:32272/TCP,80:30159/TCP   121m
{{< /text >}}

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service httpbin-gateway-istio  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ echo "$INGRESS_HOST"
172.18.255.200
{{< /text >}}

{{< text bash >}}
$ curl  "$INGRESS_HOST" -s | grep title -m 1
    <title>httpbin.org</title>
{{< /text >}}

These examples illustrate multiple options for interoperability between ambient pods and non-ambient endpoints (which can be either Kubernetes application pods or Istio gateway pods with both Istio native gateways and Kubernetes Gateway API instances). Interoperability is also supported between Istio ambient pods and Istio Egress Gateways as well as scenarios where the ambient pods run the client-side of an application with the service side running outside of the mesh of on a mesh pod that uses the sidecar proxy mode. Hence, users have multiple options for seamlessly integrating ambient and non-ambient workloads within the same Istio mesh, allowing for phased introduction of ambient capability as best suits the needs of Istio mesh deployments and operations.
