---
title: IBM Cloud Private
description: Example multicluster mesh over two IBM Cloud Private clusters.
weight: 70
keywords: [kubernetes,multicluster]
---

This example demonstrates how to setup network connectivity between two
[IBM Cloud Private](https://www.ibm.com/cloud/private) clusters
and then compose them into a multicluster mesh using a
[single control plane with VPN connectivity](/docs/concepts/multicluster-deployments/#single-control-plane-with-vpn-connectivity)
topology.

## Create the IBM Cloud Private Clusters

1.  [Install two IBM Cloud Private clusters](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/installing/installing.html).

    {{< warning >}}
    Make sure individual cluster Pod CIDR ranges and service CIDR ranges are unique and do not overlap
    across the multicluster environment and may not overlap. This can be configured by `network_cidr` and
    `service_cluster_ip_range` in `cluster/config.yaml`.
    {{< /warning >}}

    {{< text plain >}}
    ## Network in IPv4 CIDR format
    network_cidr: 10.1.0.0/16
    ## Kubernetes Settings
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  After IBM Cloud Private cluster install finishes, validate `kubectl` access to each cluster. In this example, consider
    two clusters `cluster-1` and `cluster-2`.

    1.  [Configure `cluster-1` with `kubectl`](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/manage_cluster/cfc_cli.html).

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
in the cluster. You need two steps:

1.  Add IP routers from `cluster-1` to `cluster-2`.

1.  Add IP routers from `cluster-2` to `cluster-1`.

You can check how to add IP routers from `cluster-1` to `cluster-2` to validate pod to pod communication
across clusters. With Node-to-Node Mesh mode, each node will have IP routers connecting to peer nodes in
the cluster. In this example, both clusters have three nodes.

The `hosts` file for `cluster-1`:

{{< text plain >}}
9.111.255.21 gyliu-icp-1
9.111.255.129 gyliu-icp-2
9.111.255.29 gyliu-icp-3
{{< /text >}}

The `hosts` file for `cluster-2`:

{{< text plain >}}
9.111.255.152 gyliu-ubuntu-3
9.111.255.155 gyliu-ubuntu-2
9.111.255.77 gyliu-ubuntu-1
{{< /text >}}

1.  Obtain routing information on all nodes in `cluster-1` with the command `ip route | grep bird`.

    {{< text bash >}}
    $ ip route | grep bird
    10.1.43.0/26 via 9.111.255.29 dev tunl0 proto bird onlink
    10.1.158.192/26 via 9.111.255.129 dev tunl0 proto bird onlink
    blackhole 10.1.198.128/26 proto bird
    {{< /text >}}

    {{< text bash >}}
    $ ip route | grep bird
    10.1.43.0/26 via 9.111.255.29 dev tunl0  proto bird onlink
    blackhole 10.1.158.192/26  proto bird
    10.1.198.128/26 via 9.111.255.21 dev tunl0  proto bird onlink
    {{< /text >}}

    {{< text bash >}}
    $ ip route | grep bird
    blackhole 10.1.43.0/26  proto bird
    10.1.158.192/26 via 9.111.255.129 dev tunl0  proto bird onlink
    10.1.198.128/26 via 9.111.255.21 dev tunl0  proto bird onlink
    {{< /text >}}

1.  There are three IP routers total for those three nodes in `cluster-1`.

    {{< text plain >}}
    10.1.158.192/26 via 9.111.255.129 dev tunl0  proto bird onlink
    10.1.198.128/26 via 9.111.255.21 dev tunl0  proto bird onlink
    10.1.43.0/26 via 9.111.255.29 dev tunl0  proto bird onlink
    {{< /text >}}

1.  Add those three IP routers to all nodes in `cluster-2` by the command to follows:

    {{< text bash >}}
    $ ip route add 10.1.158.192/26 via 9.111.255.129
    $ ip route add 10.1.198.128/26 via 9.111.255.21
    $ ip route add 10.1.43.0/26 via 9.111.255.29
    {{< /text >}}

1.  You can use the same steps to add all IP routers from `cluster-2` to `cluster-1`. After configuration
    is complete, all the pods in those two different clusters can communication with each other.

1.  Verify across pod communication by pinging pod IP in `cluster-2` from `cluster-1`. The following is a pod
     from `cluster-2` with pod IP as `20.1.47.150`.

    {{< text bash >}}
    $ kubectl get pods -owide  -n kube-system | grep platform-ui
    platform-ui-lqccp                                             1/1       Running     0          3d        20.1.47.150     9.111.255.77
    {{< /text >}}

1.  From a node in `cluster-1` ping the pod IP which should succeed.

    {{< text bash >}}
    $ ping 20.1.47.150
    PING 20.1.47.150 (20.1.47.150) 56(84) bytes of data.
    64 bytes from 20.1.47.150: icmp_seq=1 ttl=63 time=0.759 ms
    {{< /text >}}

The steps in this section enables Pod communication across clusters by configuring a full IP routing mesh
across all nodes in the two IBM Cloud Private Clusters.

## Install Istio for multicluster

[Follow the VPN-based multicluster installation steps](/docs/setup/kubernetes/multicluster-install/vpn/) to install and configure
local Istio control plane and Istio remote on `cluster-1` and `cluster-2`.

This example uses `cluster-1` as the local Istio control plane and `cluster-2` as the Istio remote.

## Deploy the Bookinfo example across clusters

The following example enables [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection).

1.  Install `bookinfo` on the first cluster `cluster-1`. Remove `reviews-v3` deployment to deploy on remote:

    {{< text bash >}}
    $ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    $ kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
    $ kubectl delete deployment reviews-v3
    {{< /text >}}

1.  Create the `reviews-v3.yaml` manifest for deployment on the remote:

    {{< text yaml plain "reviews-v3.yaml" >}}
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
    spec:
      ports:
      - port: 9080
        name: http
      selector:
        app: reviews
    ---
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: reviews-v3
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            app: reviews
            version: v3
        spec:
          containers:
          - name: reviews
            image: istio/examples-bookinfo-reviews-v3:1.5.0
            imagePullPolicy: IfNotPresent
            ports:
            - containerPort: 9080
    {{< /text >}}

    _Note:_ The `ratings` service definition is added to the remote cluster because `reviews-v3` is a
    client of `ratings` and creating the service object creates a DNS entry.  The Istio sidecar in the
    `reviews-v3` pod will determine the proper `ratings` endpoint after the DNS lookup is resolved to a
    service address.  This would not be necessary if a multicluster DNS solution were additionally set up, e.g. as
    in a federated Kubernetes environment.

1.  Install the `reviews-v3` deployment on the remote `cluster-2`.

    {{< text bash >}}
    $ kubectl apply -f $HOME/reviews-v3.yaml
    {{< /text >}}

1.  [Determine the ingress IP and ports](/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports)
    for `istio-ingressgateway`'s `INGRESS_HOST` and `INGRESS_PORT` variables for accessing the gateway.

    Access `http://<INGRESS_HOST>:<INGRESS_PORT>/productpage` repeatedly and each version of `reviews` should be equally load balanced,
    including `reviews-v3` in the remote cluster (red stars). It may take several accesses (dozens) to demonstrate the equal load balancing
    between `reviews` versions.
