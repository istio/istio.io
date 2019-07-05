---
title: IBM Cloud Private
description: Example multicluster mesh over two IBM Cloud Private clusters.
weight: 70
keywords: [kubernetes,multicluster]
aliases:
    - /docs/tasks/multicluster/icp/
---

This example demonstrates how to setup network connectivity between two
[IBM Cloud Private](https://www.ibm.com/cloud/private) clusters
and then compose them into a multicluster mesh using a
[single-network shared control plane](/docs/concepts/multicluster-deployments/#single-network-shared-control-plane)
topology.

## Create the IBM Cloud Private Clusters

1.  [Install two IBM Cloud Private clusters](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/installing/install.html).

    {{< warning >}}
    Make sure individual cluster Pod CIDR ranges and service CIDR ranges are unique and do not overlap
    across the multicluster environment and may not overlap. This can be configured by `network_cidr` and
    `service_cluster_ip_range` in `cluster/config.yaml`.
    {{< /warning >}}

    {{< text plain >}}
    # Default IPv4 CIDR is 10.1.0.0/16
    # Default IPv6 CIDR is fd03::0/112
    network_cidr: 10.1.0.0/16

    ## Kubernetes Settings
    # Default IPv4 Service Cluster Range is 10.0.0.0/16
    # Default IPv6 Service Cluster Range is fd02::0/112
    service_cluster_ip_range: 10.0.0.0/16
    {{< /text >}}

1.  After IBM Cloud Private cluster install finishes, validate `kubectl` access to each cluster. In this example, consider
    two clusters `cluster-1` and `cluster-2`.

    1.  [Configure `cluster-1` with `kubectl`](https://www.ibm.com/support/knowledgecenter/SSBS6K_3.2.0/manage_cluster/install_kubectl.html).

    1.  Check the cluster status:

        {{< text bash >}}
        $ kubectl get nodes
        $ kubectl get pods --all-namespaces
        {{< /text >}}

    1.  Repeat above two steps to validate `cluster-2`.

## Configure Pod Communication Across IBM Cloud Private Clusters

IBM Cloud Private uses Calico Node-to-Node Mesh by default to manage container networks. The BGP client
on each node distributes the IP router information to all nodes.

To ensure pods can communicate across different clusters, you need to configure IP routers on all nodes
across the two clusters. In summary, you need the following two steps to configure pod communication across
two IBM Cloud Private Clusters:

1.  Add IP routers from `cluster-1` to `cluster-2`.

1.  Add IP routers from `cluster-2` to `cluster-1`.

{{< warning >}}
This approach works if all the nodes within the multiple IBM Cloud Private clusters are located in the same subnet. It is unable to add BGP routers directly for nodes located in different subnets because the IP addresses must be reachable with a single hop. Alternatively, you can use a VPN for pod communication across clusters. Refer to [this article](https://medium.com/ibm-cloud/setup-pop-to-pod-communication-across-ibm-cloud-private-clusters-add0b079ebf3) for more details.
{{< /warning >}}

You can check how to add IP routers from `cluster-1` to `cluster-2` to validate pod to pod communication
across clusters. With Node-to-Node Mesh mode, each node will have IP routers connecting to peer nodes in
the cluster. In this example, both clusters have three nodes.

The `hosts` file for `cluster-1`:

{{< text plain >}}
172.16.160.23 micpnode1
172.16.160.27 micpnode2
172.16.160.29 micpnode3
{{< /text >}}

The `hosts` file for `cluster-2`:

{{< text plain >}}
172.16.187.14 nicpnode1
172.16.187.16 nicpnode2
172.16.187.18 nicpnode3
{{< /text >}}

1.  Obtain routing information on all nodes in `cluster-1` with the command `ip route | grep bird`.

    {{< text bash >}}
    $ ip route | grep bird
    blackhole 10.1.103.128/26  proto bird
    10.1.176.64/26 via 172.16.160.29 dev tunl0  proto bird onlink
    10.1.192.0/26 via 172.16.160.27 dev tunl0  proto bird onlink
    {{< /text >}}

    {{< text bash >}}
    $ ip route | grep bird
    10.1.103.128/26 via 172.16.160.23 dev tunl0  proto bird onlink
    10.1.176.64/26 via 172.16.160.29 dev tunl0  proto bird onlink
    blackhole 10.1.192.0/26  proto bird
    {{< /text >}}

    {{< text bash >}}
    $ ip route | grep bird
    10.1.103.128/26 via 172.16.160.23 dev tunl0  proto bird onlink
    blackhole 10.1.176.64/26  proto bird
    10.1.192.0/26 via 172.16.160.27 dev tunl0  proto bird onlink
    {{< /text >}}

1.  There are three IP routers total for those three nodes in `cluster-1`.

    {{< text plain >}}
    10.1.176.64/26 via 172.16.160.29 dev tunl0  proto bird onlink
    10.1.103.128/26 via 172.16.160.23 dev tunl0  proto bird onlink
    10.1.192.0/26 via 172.16.160.27 dev tunl0  proto bird onlink
    {{< /text >}}

1.  Add those three IP routers to all nodes in `cluster-2` by the command to follows:

    {{< text bash >}}
    $ ip route add 10.1.176.64/26 via 172.16.160.29
    $ ip route add 10.1.103.128/26 via 172.16.160.23
    $ ip route add 10.1.192.0/26 via 172.16.160.27
    {{< /text >}}

1.  You can use the same steps to add all IP routers from `cluster-2` to `cluster-1`. After the configuration
    is complete, all the pods in those two different clusters can communicate with each other.

1.  Verify across pod communication by pinging pod IP in `cluster-2` from `cluster-1`. The following is a pod
     from `cluster-2` with pod IP as `20.1.58.247`.

    {{< text bash >}}
    $ kubectl -n kube-system get pod -owide | grep dns
    kube-dns-ksmq6                                                1/1     Running             2          28d   20.1.58.247      172.16.187.14   <none>
    {{< /text >}}

1.  From a node in `cluster-1` ping the pod IP which should succeed.

    {{< text bash >}}
    $ ping 20.1.58.247
    PING 20.1.58.247 (20.1.58.247) 56(84) bytes of data.
    64 bytes from 20.1.58.247: icmp_seq=1 ttl=63 time=1.73 ms
    {{< /text >}}

The steps above in this section enables pod communication across the two clusters by configuring a full IP routing mesh
across all nodes in the two IBM Cloud Private Clusters.

## Install Istio for multicluster

[Follow the VPN-based multicluster installation steps](/docs/setup/kubernetes/install/multicluster/shared-vpn/) to install and configure
local Istio control plane and Istio remote on `cluster-1` and `cluster-2`.

In this guide, it is assumed that the local Istio control plane is deployed in `cluster-1`, while the Istio remote is deployed in `cluster-2`.

## Deploy the Bookinfo example across clusters

The following example enables [automatic sidecar injection](/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection).

1.  Install `bookinfo` on the first cluster `cluster-1`. Remove the `reviews-v3` deployment which will be deployed on cluster `cluster-2` in the following step:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    $ kubectl delete deployment reviews-v3
    {{< /text >}}

1.  Deploy the `reviews-v3` service along with any corresponding services on the remote `cluster-2` cluster:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    ---
    ##################################################################################################
    # Ratings service
    ##################################################################################################
    apiVersion: v1
    kind: Service
    metadata:
      name: ratings
      labels:
        app: ratings
        service: ratings
    spec:
      ports:
      - port: 9080
        name: http
    ---
    ##################################################################################################
    # Reviews service
    ##################################################################################################
    apiVersion: v1
    kind: Service
    metadata:
      name: reviews
      labels:
        app: reviews
        service: reviews
    spec:
      ports:
      - port: 9080
        name: http
      selector:
        app: reviews
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: reviews-v3
      labels:
        app: reviews
        version: v3
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: reviews
          version: v3
      template:
        metadata:
          labels:
            app: reviews
            version: v3
        spec:
          containers:
          - name: reviews
            image: istio/examples-bookinfo-reviews-v3:1.12.0
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    ---
    EOF
    {{< /text >}}

    _Note:_ The `ratings` service definition is added to the remote cluster because `reviews-v3` is client
    of `ratings` service, thus a DNS entry for `ratings` service is required for `reviews-v3`. The Istio sidecar
    in the `reviews-v3` pod will determine the proper `ratings` endpoint after the DNS lookup is resolved to a
    service address. This would not be necessary if a multicluster DNS solution were additionally set up, e.g. as
    in a federated Kubernetes environment.

1.  [Determine the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
    for `istio-ingressgateway`'s `INGRESS_HOST` and `INGRESS_PORT` variables to access the gateway.

    Access `http://<INGRESS_HOST>:<INGRESS_PORT>/productpage` repeatedly and each version of `reviews` should be equally load balanced,
    including `reviews-v3` in the remote cluster (red stars). It may take several accesses (dozens) to demonstrate the equal load balancing
    between `reviews` versions.
