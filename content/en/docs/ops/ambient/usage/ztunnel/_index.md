---
title: Ztunnel Networking - L4 & M-TLS
description: User guide for ztunnel networking.
weight: 2
owner: istio/wg-networking-maintainers
test: n/a
---

## Introduction 

This guide describes the functionality and usage of the Ztunnel proxy and Layer-4 networking functions using Istio Ambient mesh. We use a sample user journey to describe these functions. 

The Ztunnel (Zero Trust Tunnel) component is a purpose-built per-node proxy for Istio ambient mesh. It is responsible for securely connecting and authenticating workloads within ambient mesh. Ztunnel is designed to focus on a small set of features for your workloads in ambient mesh such as mTLS, authentication, L4 authorization and telemetry, without terminating workload HTTP traffic or parsing workload HTTP headers. The ztunnel ensures traffic is efficiently and securely transported to the waypoint proxies, where the full suite of Istio’s functionality, such as HTTP telemetry and load balancing, is implemented.  Sometimes the term "Secure Overlay Networking" is also used informally to collectively describe the set of L4 networking functions implemented in an Ambient mesh via the Ztunnel proxy.

It is expected that some production use cases of Istio in Ambient mode may be addressed solely via the L4 Secure overlay networking features whereas other use cases will additionally need advanced traffic management and L7 networking features for which the additional Waypoint proxies will need to be deployed. This is summarized in the following table. This guide focusses on functionality related to the baseline L4 and mTLS networking using ztunnel proxies. Other guides cover the advanced L7 networking functions that additionally require waypoint proxies. 


| Application Deployment Use Case | Istio Ambient Mesh Configuration |
| ------------- | ------------- |
| Zero Trust networking via mutual-TLS, encrypted and tunneled data transport of all IP protocols, L4 authorization,  L4 telemetry | Baseline Ambient Mesh with ztunnel proxy networking |
| Application requires L4 Mutual-TLS plus advanced Istio traffic management features (incl L4/ L7 VirtualService, L7 telemetry, L7 Authorization) | Full Istio Ambient Mesh configuration both ztunnel proxy and waypoint proxy based networking |


[//]: # (There are additional subtle details on how functionality is split between the ztunnel and the waypoint proxies. These are described in later sections of this guide and other guides.)
[//]: # ( As an example, if an Istio Authorization policy includes strictly L4 rules, then it is handled completely by ztunnel but if a policy includes only L7 rules or both L4 and L7 rules then it is handled by a Waypoint proxy. However when it comes to a VirtualService it is always handled by Waypoint proxies regardless of whether it has purely L4 rules, purely L7 rules or a mix of L4 and L7 rules. Other details on the functionality split between ztunnel and waypoint proxies will be described in later sections of this and other guides.) 

## Installation

### Pre-requisites & Supported Topologies

Ztunnel proxies are automatically installed when one of the supported installation methods is used to install Istio Ambient mesh.  The minimum Istio version required for the functionality described in this guide is 1.18.0. At this time, the ambient mode is only supported for deployment on Kubernetes clusters, support for deployment on non-Kubernetes endpoints such as Virtual machines is expected to be a future capability. Additionally, only single cluster deployments are supported for Ambient mode.  Some limited multi-cluster scenarios may work currently in ambient mode but the behavior is not guaranteed and official support for multi-cluster operation is a future capability. Finally note that Ztunnel based L4 networking is primnarily focused on East-West mesh networking and can work with all of Istio's North-South networking options including Istio-native ingress and egress gateways as well as Kubernetes native Gateway API implementation. 

{{< tip >}}
A single Istio mesh can include pods and endpoints some of which operate using the sidecar proxy mode while others use the node level proxy of the Ambient architecture. 
{{< /tip >}}

### Understanding the Ztunnel Default Configuration

<< Consider breaking this out into bullets for easier reading TODO >>

One of the goals for the ztunnel proxy design is to provide a usable configuration out of the box with a fixed feature set and that does not require much, or any, custom configuration. Hence currently there are no configuration options that need to be set other than the `ambient` profile setting. Once this profile is used, this in turn sets sets 2 internal configuration parameters (as illustrated in the examples below) within the istioOperator which eventually set the configuration of the `ambient` mesh. In future there may be some additional limited configurability for ztunnel proxies. For now, the pod to ztunnel proxy networking (sometimes also called ztunnel redirection), ztunnel proxy to ztunnel proxy networking as well as ztunnel to other sidecar proxy networing all use a fixed default configuration which is not customizable. In particular, currently, the only option for pod to ztunnel networking setup is currently via the `istio-cni` and only via an internal ipTables based ztunnel traffic redirect option. There is no option to use `init-containers` unlike with sidecar proxies. Alternate forms of ztunnel traffic redirect such as ebpf are also not currently supported, although may be supported in future. Of course, once the baseline `ambient` mesh is installed, features such as Authorization policy (both L4 and L7) as well as other istio functions such as PeerAuthentication options for mutual-TLS are fully configurable similar to standard Istio.  In future release versions, some limited configurability may also be added to the ztunnel proxy layer. 

For the examples in this guide, we used a deployment of Istio Ambient on a `kind` cluster, although these should apply for any Kubernetes cluster version 1.18.0 or later. Refer to the Getting started guide on how to download the `istioctl` client and how to deploy a `kind` cluster. It would be recommended to have a cluster with more than 1 worker node in order to fully exercise the examples described in this guide. 

### Installation using istioctl

Setting Istio profile to `ambient` during installation is all that is needed to enable installation of Ztunnel and Layer-4 networking functionality. An instance of Istio mesh cannot be dynamically switched between sidecar mode and `ambient` mode. A prior instance of istio must be uninstalled before re-innstalling istio in `ambient` for the same set of user application endpoints and namespaces. 

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl install --set profile=ambient --set components.ingressGateways[0].enabled=true --set components.ingressGateways[0].name=istio-ingressgateway --skip-confirmation
{{< /text >}}

After running the above command, you’ll get the following output that indicates
five components (including {{< gloss "ztunnel" >}}Ztunnel{{< /gloss >}}) have been installed successfully!

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ingress gateways installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

After running the above command, you’ll get the following output that indicates
four components (including {{< gloss "ztunnel" >}}Ztunnel{{< /gloss >}}) have been installed successfully!

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Installation using Helm charts

An alternative to using istioctl is to use Helm based install of Istio Ambient.
<<< Add sequence of helm charts and values to be used for ambient install >>> 
<<<< TODO CONTENT ON HELM BASED INSTALL TO BE ADDED >>>>


### Verifying Installation

Verify the installed components using the following commands:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl verify-install
{{< /text >}}

{{< text syntax=plain snip_id=none >}}
1 Istio control planes detected, checking --revision "default" only
✔ ClusterRole: istiod-istio-system.istio-system checked successfully
--snip--
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
Checked 15 custom resource definitions
Checked 1 Istio Deployments
✔ Istio is installed and verified successfully
{{< /text >}}

{{< text bash >}}
$ istioctl verify-install | grep ztunnel
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-8kd8p      1/1     Running   0          6h32m
istio-cni-node-mtzmz      1/1     Running   0          6h32m
istio-cni-node-smp7m      1/1     Running   0          6h32m
istiod-5c7f79574c-btwqx   1/1     Running   0          6h33m
ztunnel-2lb4n             1/1     Running   0          6h33m
ztunnel-wcqpp             1/1     Running   0          6h33m
ztunnel-zxrsx             1/1     Running   0          6h33m
{{< /text >}}

{{< text bash >}}
$ kubectl get daemonset -n istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   3         3         3       3            3           kubernetes.io/os=linux   6h34m
ztunnel          3         3         3       3            3           <none>                   6h35m
{{< /text >}}

{{< text bash >}}
$ kubectl get istiooperator/installed-state -n istio-system -o yaml
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
--snip--
profile: ambient
  tag: 1.18.0
  values:
    base:
      enableCRDTemplates: false
      validationURL: ""
    cni:
      ambient:
        enabled: true
--snip--
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl verify-install
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
1 Istio control planes detected, checking --revision "default" only
✔ ClusterRole: istiod-istio-system.istio-system checked successfully
--snip--
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
Checked 15 custom resource definitions
Checked 1 Istio Deployments
✔ Istio is installed and verified successfully
{{< /text >}}

{{< text bash >}}
$ istioctl verify-install | grep ztunnel
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
✔ DaemonSet: ztunnel.istio-system checked successfully
✔ ServiceAccount: ztunnel.istio-system checked successfully
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-8kd8p      1/1     Running   0          6h32m
istio-cni-node-mtzmz      1/1     Running   0          6h32m
istio-cni-node-smp7m      1/1     Running   0          6h32m
istiod-5c7f79574c-btwqx   1/1     Running   0          6h33m
ztunnel-2lb4n             1/1     Running   0          6h33m
ztunnel-wcqpp             1/1     Running   0          6h33m
ztunnel-zxrsx             1/1     Running   0          6h33m
{{< /text >}}

{{< text bash >}}
$ kubectl get daemonset -n istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   3         3         3       3            3           kubernetes.io/os=linux   6h34m
ztunnel          3         3         3       3            3           <none>                   6h35m
{{< /text >}}

{{< text bash >}}
$ kubectl get istiooperator/installed-state -n istio-system -o yaml
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
--snip--
profile: ambient
  tag: 1.18.0
  values:
    base:
      enableCRDTemplates: false
      validationURL: ""
    cni:
      ambient:
        enabled: true
    ztunnel:
      enabled: true
  hub: docker.io/istio
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_META_ENABLE_HBONE: "true"
--snip--
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

The output of `istioctl verify-install` should indicate all items installed successfully including some ztunnel components as indicated in the examples.

If `ambient` is installed correctly, you should see 1 instance of ztunnel proxy pod per node in RUNNING state in the cluster (including control plane nodes and worker nodes). You should also see 1 instance of the `istio-cni` pods per node and a single instance of the `istiod` controller pod per cluster, all in RUNNING state. 

Confirm from the `istioOperator` output that profile is normally set to `ambient` (unless a custom profile is being used), ztunnel is set to enabled,  cni is enabled for `ambient`. Notice also proxyMetaData field has ISTIO_META_ENABLE_HBONE set to true. If using a custom installation profile, these fields must be set as described to enable `ambient` mode within a custom profile. It is recommended to start with the built-in `ambient` profile before trying any custom variations.

[//]: # ( ## NOTE Before we go further, would be good to have a section on roles, RBAC, operational model )

## Functional Overview

The figure shows an architecture summary of the Ztunnel proxy function.

{{< image width="100%"
    link="ztunnel-architecture.png"
    caption="Ztunnel architecture"
    >}}

For additional architecture details, refer to the Ztunnel architecture guide. For now we mainly note that each instance of the ztunnel proxy uses the Envoy xDS apis to receive certificates, discovery and configuration information from the istio control plane (`istiod`) on behalf of all pods and endpoints associated with it. In particular the ztunnel proxy obtains M-TLS certificates for all Service accounts of all pods that are associated with it. Since a single ztunnel proxy performs both the data plane and the control plane operations across multiple service accounts, it is a multi-tenant component of the mesh infrastructure in contrast with Istio side car proxies that handle control plane and data plane operations on a per application endpoint or pod basis.

<< To add some content on the xDS api objects of relevance to Ambient/ ztunnel >>

## Deploying an Application

Normally, a user with Istio admin privileges will deploy the Istio mesh infrastructure. Once Istio is successfully deployed in `ambient` mode, it will be transparently available to applications deployed by all users in namespaces that have been annoted to use Istio `ambient` as illustrated in the examples below.  

Lets first deploy a simple http client server application without making it part of the Istio ambient mesh. We can pick from the apps in the samples folder of the istio repository. Execute the following examples from the top of a local Istio repository or istio folder created by downloading the istioctl client as described in istio guides.

{{< text bash >}}
$ kubectl create ns ambient-demo
$ kubectl apply -f samples/httpbin/httpbin.yaml -n ambient-demo
$ kubectl apply -f samples/sleep/sleep.yaml -n ambient-demo
$ kubectl apply -f samples/sleep/notsleep.yaml -n ambient-demo
$ kubectl scale deployment sleep --replicas=2 -n ambient-demo
{{< /text >}}

These manifests should deploy the sleep and notsleep pods which we shall use as clients for the httpbin service pod (for simplicity, the cli outputs have been deleted in the code samples above). We also create multiple replicas of the client deployment in order to exercise various scenarios. 

{{< text bash >}}
$ kubectl get pods -n ambient-demo
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-648cd984f8-7vg8w   1/1     Running   0          31m
notsleep-bb6696574-2tbzn   1/1     Running   0          31m
sleep-69cfb4968f-mhccl     1/1     Running   0          31m
sleep-69cfb4968f-rhhhp     1/1     Running   0          31m
{{< /text >}}

$ kubectl get svc httpbin -n ambient-demo
{{< text syntax=plain snip_id=none >}}
NAME      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
httpbin   ClusterIP   10.110.145.219   <none>        8000/TCP   28m
{{< /text >}}

Note that each application pod has just 1 container running in it (the "1/1" indicator) and that `httpbin` is an http service listening on `ClusterIP` service port 8000. We should now be able to `curl` this service from either client pod and confirm it returns the `httpbin` web page as shown below. At this point there is no `TLS` of any form being used.


{{< text bash >}}
$ kubectl exec -it deploy/sleep -n ambient-demo  -- curl httpbin:8000 -s | grep title -m 1
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
    <title>httpbin.org</title>
{{< /text >}}

We now enable `ambient` by simply adding a label to the application's namespace as shown below. 

{{< text bash >}}
$ kubectl label namespace ambient-demo istio.io/dataplane-mode=ambient
$ kubectl  get pods -n ambient-demo
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-648cd984f8-7vg8w   1/1     Running   0          78m
notsleep-bb6696574-2tbzn   1/1     Running   0          77m
sleep-69cfb4968f-mhccl     1/1     Running   0          78m
sleep-69cfb4968f-rhhhp     1/1     Running   0          78m
{{< /text >}}

Further, we see that after this, we still see only 1 container per application pod and the uptime of these pods indicates these were not restarted in order to enable `ambient` mode (unlike `sidecar` mode which does restart application pods when the sidecar proxies are injected). This results in better user experience and operational performance since `ambient` mode can seamlessly be enabled (or disabled) completely transparently as far as the application endpoints are concerned.  We can initiate a `curl` request again from one of the client pods to the service and again verify that this works now while in `ambient` mode.  
{{< text bash >}}
$ kubectl exec -it deploy/sleep -n ambient-demo  -- curl httpbin:8000 -s | grep title -m 1
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
    <title>httpbin.org</title>
{{< /text >}}

This indicates the traffic path is working.  In the next section we look at how to monitor the confuguration and data plane of the Ztunnel proxy to confirm that traffic is correctly using the Ztunnel proxy. 

## Monitoring the Ztunnel proxy 

### Viewing Ztunnel proxy state

As indicated previously, the `Ztunnel` proxy on each node gets configuration and discovery information from the `istiod` component via `xDS` APIs. Use the `istioctl proxy-config` command as shown below to view discovered ambient workloads as seen by a Ztunnel proxy as well as secrets holding the TLS certificates that the Ztunel proxy has received from the istiod control plane to use in m-tls signaling on behalf of the local workloads. 

In the first example, we see all the workloads and control plane components that the specific Ztunnel pod `ztunnel-gkldc` is tracking including information about the IP address and protocol to use when connecting to that component and whether there is a Waypoint proxy associated with that workload.

{{< text bash >}}
$ istioctl proxy-config workloads ztunnel-gkldc.istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
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

In the second example, we see the list of TLS certificates that this Ztunnel proxy instance has received from istiod to use in TLS signaling.

{{< text bash >}}
$ istioctl proxy-config secrets ztunnel-gkldc.istio-system
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
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

Using these cli commands, a user can check that ztunnel proxies are getting configured with all the expected workloads and TLS certificates and missing information can be used for troubleshooting to explain any potential observed networking errors. A user may also use the `all` option to view all parts of the proxy-config with a single cli command. 

{{< text bash >}}
$ istioctl proxy-config all ztunnel-gkldc.istio-system
{{< /text >}}

Note also that when used with a ztunnel proxy instance, not all cli options of the `istioctl proxy-config` cli are supported since some apply only to side car proxies. In future software versions, these cli options may be evolved to better separate options for display of  `sidecar` proxy information from `ztunnel` proxy information.  

### Verifying Ztunnel traffic logs

Let us send some traffic from a client `sleep` pod to the `httpbin` service.

{{< text bash >}}
$ kubectl -n ambient-demo exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://httpbin:8000/; done'
{{< /text >}}
The response displayed confirms the client pod receives responses from the service. 
{{< text syntax=plain snip_id=none >}}
HTTP/1.1 200 OK
Server: gunicorn/19.9.0
--snip--
{{< /text >}}

Now lets check logs of the `ztunnel` pods to confirm the traffic was sent over the `ztunnel`.

{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | egrep "inbound|outbound"
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
2023-08-14T09:15:46.542651Z  INFO outbound{id=7d344076d398339f1e51a74803d6c854}: ztunnel::proxy::outbound: proxying to 10.240.2.10:80 using node local fast path
2023-08-14T09:15:46.542882Z  INFO outbound{id=7d344076d398339f1e51a74803d6c854}: ztunnel::proxy::outbound: complete dur=269.272µs
--snip--
{{< /text >}}

These log messages confirm the traffic indeed used the `ztunnel` proxy in the datapath. Additional fine grained monitoring can be done by checking logs on the specific `ztunnel` proxy instances that are on the same nodes as the source and destination pods of traffic.  If these logs are not seen, then a possibility is that traffic redirection may not be working correctly and the next section has some information on checking for that scenario. Note that with `ambient` traffic always traverses the `ztunnel` pod even when the source and destination of the traffic are on the same compute node. 

### Checking for ztunnel traffic redirection
In case the traffic logs for the `ztunnel` proxy do not indicate forwarding of traffic, you can check whether traffic redirection has been set up correctly. In this section we do not go into the full details of how traffic redirection is performed, but we provide some quick pointers to check.

In the current release, only iptables based traffic redirection is supported as indicated previously, hence this is what we can check. We can first check to confirm that the `ipset` has been created in each worker node and contains the IPs of pods on that node that are in the ambient mesh. For this we require `iptables` to be installed on the worker nodes of our cluster.  Since for this document we are using `kind` clusters for running our examples thw worker nodes are running as Docker or podman containers, we can alternately also run the iptables from the underlying physical machine within the Docker containers being used as cluster workers. THis is shown in the examples below where we use the `Pid` of the DOcker containers and then use the Linux `nsenter` utulity from the underlying machine to run `iptables` and `ipset` on the `kind` worker nodes. Here we see that the `ipset` is indeed created on the worker node and the list of pod IPs in this set corresponds to the IPs of `ambient` pods on that worker node. We can similarly check for each worker node to confirm the `ipsets` are correctly created on each worker node.


{{< text bash >}}
$ docker ps -a
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
CONTAINER ID   IMAGE                  COMMAND                  CREATED      STATUS      PORTS                      NAMES
c871caa23449   kindest/node:v1.24.0   "/usr/local/bin/entr…"   2 days ago   Up 2 days   0.0.0.0:32000->32000/tcp   amb1-worker2
272b83bc90b0   kindest/node:v1.24.0   "/usr/local/bin/entr…"   2 days ago   Up 2 days   127.0.0.1:42509->6443/tcp  amb1-control-plane
149b51542edc   kindest/node:v1.24.0   "/usr/local/bin/entr…"   2 days ago   Up 2 days                              amb1-worker
{{< /text >}}
{{< text bash >}}
$ docker container inspect -f '{{ .State.Pid}}' amb1-worker2
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
1019984
{{< /text >}}
{{< text bash >}}
$ sudo nsenter -t 1019984  -n ipset list
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
Name: ztunnel-pods-ips
Type: hash:ip
Revision: 0
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 344
References: 1
Number of entries: 2
Members:
10.240.1.20
10.240.1.21
{{< /text >}}

Similarly we can also check that `iptables` rules are being installed on the nodes similar to the example below. If these are not seen, it could indicate an issue with the traffic redirection setup. Note that there are additional `iptables` and `ip route` rules that get added in order for the complete traffic redirection function. In future releases additional forms of traffic redirection will also be supported and the internal details will be described in other documents. A typical user does not need to review every such rule in detail hence these are out of scope for this guide. 


{{< text bash >}}
$ sudo nsenter -t 1019984  -n iptables -t mangle -L ztunnel-PREROUTING
{{< /text >}}
{{< text syntax=plain snip_id=none >}}
Chain ztunnel-PREROUTING (1 references)
target     prot opt source               destination
MARK       all  --  anywhere             anywhere             MARK or 0x200
RETURN     all  --  anywhere             anywhere
MARK       all  --  anywhere             anywhere             MARK or 0x200
RETURN     all  --  anywhere             anywhere
RETURN     udp  --  anywhere             anywhere             udp dpt:geneve
MARK       all  --  anywhere             anywhere             connmark match  0x220/0x220 MARK or 0x200
RETURN     all  --  anywhere             anywhere             mark match 0x200/0x200
MARK       all  --  anywhere             anywhere             connmark match  0x210/0x210 MARK or 0x40
RETURN     all  --  anywhere             anywhere             mark match 0x40/0x40
MARK       all  -- !10.240.1.17          anywhere             MARK or 0x210
RETURN     all  --  anywhere             anywhere             mark match 0x200/0x200
MARK       all  --  anywhere             anywhere             MARK or 0x220
MARK       udp  --  anywhere             anywhere             MARK or 0x220
RETURN     all  --  anywhere             anywhere             mark match 0x200/0x200
MARK       tcp  --  anywhere             anywhere             match-set ztunnel-pods-ips src MARK or 0x100
{{< /text >}}


### Verifying ztunnel load balancing

The Ztunnel proxy automatically performs client-side load balancing if the destination is a service with multiple endpoints. No additional configuration is needed.  The Ztunnel load balancing algorithm is an internally fixed L4 Round Robin algorithm that distributes traffic based on L4 connection state and is not user configurable. 

Lets repeat the previous example with multiple replicas of the service pod and verify that client traffic is load balanced across the service replicas. 

{{< text bash >}}
$ kubectl -n ambient-demo scale deployment httpbin --replicas=2
{{< /text >}}
{{< text bash >}}
$ kubectl -n ambient-demo exec deploy/sleep -- sh -c 'for i in $(seq 1 10); do curl -s -I http://httpbin:8000/; done'
{{< /text >}}
{{< text bash >}}
$ kubectl -n istio-system logs -l app=ztunnel | egrep "inbound|outbound"
{{< /text >}}

{{< text syntax=plain snip_id=none >}}
2023-08-14T09:33:24.969996Z  INFO inbound{id=ec177a563e4899869359422b5cdd1df4 peer_ip=10.240.2.16 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.240.1.11:80
2023-08-14T09:33:25.028601Z  INFO inbound{id=1ebc3c7384ee68942bbb7c7ed866b3d9 peer_ip=10.240.2.16 peer_id=spiffe://cluster.local/ns/ambient-demo/sa/sleep}: ztunnel::proxy::inbound: got CONNECT request to 10.240.1.11:80

--snip--

2023-08-14T09:33:25.226403Z  INFO outbound{id=9d99723a61c9496532d34acec5c77126}: ztunnel::proxy::outbound: proxy to 10.240.1.11:80 using HBONE via 10.240.1.11:15008 type Direct
2023-08-14T09:33:25.273268Z  INFO outbound{id=9d99723a61c9496532d34acec5c77126}: ztunnel::proxy::outbound: complete dur=46.9099ms
2023-08-14T09:33:25.276519Z  INFO outbound{id=cc87b4de5ec2ccced642e22422ca6207}: ztunnel::proxy::outbound: proxying to 10.240.2.10:80 using node local fast path
2023-08-14T09:33:25.276716Z  INFO outbound{id=cc87b4de5ec2ccced642e22422ca6207}: ztunnel::proxy::outbound: complete dur=231.892µs

--snip--
{{< /text >}}

Here we note the logs from the ztunnel proxies first indicating the http CONNECT request to the new destination pod (10.240.1.11) which indicates the setup of ztunnel to the node hosting the additional destination service pod. This is then followed by logs indicating the client traffic being sent to both 10.240.1.11 and 10.240.2.280 which are the two destination pods providing the service. Also note that the data path is performing client-side load balancing in this case and not depending on Kubernetes service load balancing. 

This is a Round robin load balancing algorithm and is separate from and independent of any load balancing algorithm that may be configured within a VirtualService's TrafficPolicy field, since as discussed previously, all aspects of VirtualService api objects are instantiated on the Waypoint proxies and not the ztunnel proxies. 



### Pod selection logic for Ambient and Sidecar modes
Istio with sidecar proxies can co-exist with `ambient` based node level proxies within the same compute cluster. Since there are multiple configuration parameters and resource annotations that govern whether a given pod will be setup to use a sidecar proxy or an ambient node proxy, the logic to make this decision is as follows.

1. The `istio-cni` plugin configuration exclude list configured in `cni.values.excludeNamespaces` is used to skipnamespaces in the exclude list.
2. `ambient` mode is used for a pod if 
- The namespace has label "istio.io/dataplane-mode" == "ambient" 
- The annotation "sidecar.istio.io/status" is not present on the pod
- "ambient.istio.io/redirection" is not "disabled"


Add the text from the CNI README that describes the pod selection logic. Add note that it would be preferrable to use PeerAuthentication resource for such mixed scenarios rather than pod soec annotations.


## Section on data plane encapsulation


## Understanding Mutual-TLS in Istio Ambient

- Which aspects are different from sidecar based m-tls ? 
- PeerAuthentication policy ?
- Monitoring m-tls signaling/ state ?
- 

## L4 Authorization Policy
TODO

## Monitoring and Telemetry with Ztunnel
TODO

## Co-existence of Ambient/ Ztunnels with Side car proxies
TODO

