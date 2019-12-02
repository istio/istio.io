---
title: IBM Cloud Private
description: 跨两个 IBM Cloud Private 集群的多集群网格示例。
weight: 70
keywords: [kubernetes,multicluster]
aliases:
    - /zh/docs/tasks/multicluster/icp/
    - /zh/docs/examples/multicluster/icp/
---

本例演示了如何在两个 [IBM Cloud Private](https://www.ibm.com/cloud/private) 集群之间设置网络连接并使用[单网络部署](/zh/docs/ops/prep/deployment-models/#single-network)以将它们组成一个多集群网格。

## 创建 IBM Cloud Private 集群{#create-the-IBM-Cloud-Private-clusters}

1. [安装两个 IBM Cloud Private 集群](https://www.ibm.com/support/knowledgecenter/zh/SSBS6K_3.2.0/installing/install.html).

    {{< warning >}}
    确保每个集群的 Pod CIDR 范围和服务 CIDR 范围都是唯一的，并且在多集群环境中不会重叠。
    这可以通过 `cluster/config.yaml` 文件中的 `network_cidr` 和 `service_cluster_ip_range` 来配置。
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

1. 在 IBM Cloud Private 集群安装完成后，验证 `kubectl` 可以访问这些集群。在本例中，我们将两个集群命名为 `cluster-1` 和 `cluster-2`。

    1. [使用 `kubectl` 配置 `cluster-1`](https://www.ibm.com/support/knowledgecenter/zh/SSBS6K_3.2.0/manage_cluster/install_kubectl.html)。

    1. 检查集群状态：

        {{< text bash >}}
        $ kubectl get nodes
        $ kubectl get pods --all-namespaces
        {{< /text >}}

    1. 重复以上两步来验证 `cluster-2`。

## 配置 pod 通过 IBM Cloud Private 集群通信{#configure-pod-communication-across-IBM-Cloud-Private-clusters}

IBM Cloud Private 默认使用 Calico Node-to-Node Mesh 来管理容器网络。
每个节点上的 BGP 客户端会将 IP 路由信息分发到所有节点。

为了确保 pods 可以跨不同集群通信，您需要在两个集群的所有节点上都配置 IP 路由。
综上所述，您需要以下两步以配置 pod 跨两个 IBM Cloud Private 集群通信：

1. 添加从 `cluster-1` 到 `cluster-2` 的 IP 路由。

1. 添加从 `cluster-2` 到 `cluster-1` 的 IP 路由。

{{< warning >}}
只有多个 IBM Cloud Private 集群中的所有节点都位于同一子网中，这个方法才有效。
直接为位于不同子网中的节点添加 BGP 路由器是行不通的，因为 IP 地址必须通过单跳就能访问。
另外，您可以使用 VPN 实现 pod 跨集群通信。请参考[这篇文章](https://medium.com/ibm-cloud/setup-pop-to-pod-communication-across-ibm-cloud-private-clusters-add0b079ebf3)以获取更多细节。
{{< /warning >}}

您可以检查如何添加从 `cluster-1` 到 `cluster-2` 的 IP 路由以验证 pod 之间的跨集群通信。
在 Node-to-Node Mesh 模式下，每个节点都将具有连接到群集中对等节点的 IP 路由。
在本例中，每个集群有三个节点。

`cluster-1` 的 `hosts` 文件：

{{< text plain >}}
172.16.160.23 micpnode1
172.16.160.27 micpnode2
172.16.160.29 micpnode3
{{< /text >}}

`cluster-2` 的 `hosts` 文件：

{{< text plain >}}
172.16.187.14 nicpnode1
172.16.187.16 nicpnode2
172.16.187.18 nicpnode3
{{< /text >}}

1. 在 `cluster-1` 的所有节点上使用命令 `ip route | grep bird` 获取路由信息。

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

1. `cluster-1` 中的这三个节点一共有三个 IP 路由。

    {{< text plain >}}
    10.1.176.64/26 via 172.16.160.29 dev tunl0  proto bird onlink
    10.1.103.128/26 via 172.16.160.23 dev tunl0  proto bird onlink
    10.1.192.0/26 via 172.16.160.27 dev tunl0  proto bird onlink
    {{< /text >}}

1. 使用以下命令将这三个 IP 路由添加到 `cluster-2` 的所有节点：

    {{< text bash >}}
    $ ip route add 10.1.176.64/26 via 172.16.160.29
    $ ip route add 10.1.103.128/26 via 172.16.160.23
    $ ip route add 10.1.192.0/26 via 172.16.160.27
    {{< /text >}}

1. 您可以使用相同的步骤以添加从 `cluster-2` 到 `cluster-1` 的所有 IP 路由。配置完成后，这两个不同集群中的所有 pods 都可以互相通信了。

1. 从 `cluster-1` ping `cluster-2` 中的 pod IP 以验证 pod 之间的通信。下面是一个 `cluster-2` 中的 pod，其 IP 为 `20.1.58.247`。

    {{< text bash >}}
    $ kubectl -n kube-system get pod -owide | grep dns
    kube-dns-ksmq6                                                1/1     Running             2          28d   20.1.58.247      172.16.187.14   <none>
    {{< /text >}}

1. 从 `cluster-1` 的一个节点上 ping 该 pod IP，应该会成功。

    {{< text bash >}}
    $ ping 20.1.58.247
    PING 20.1.58.247 (20.1.58.247) 56(84) bytes of data.
    64 bytes from 20.1.58.247: icmp_seq=1 ttl=63 time=1.73 ms
    {{< /text >}}

本节中的这些步骤，通过在两个 IBM Cloud Private 集群中的所有节点之间配置完整的 IP 路由网格，使得 pod 可以在两个集群之间通信。

## 为多集群安装 Istio{#install-Istio-for-multicluster}

按照[单网络共享控制平面说明](/zh/docs/setup/install/multicluster/shared-vpn/)在 `cluster-1` 和 `cluster-2` 上安装并配置本地 Istio 控制平面和远程 Istio。

在本指南中，假定本地 Istio 控制平面部署在 `cluster-1`，远程 Istio 部署在 `cluster-2`。

## 跨集群部署 Bookinfo 示例{#deploy-the-Bookinfo-example-across-clusters}

下面的例子启用了[自动注入 sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)。

1. 在集群 `cluster-1` 上安装 `bookinfo`。删掉 `reviews-v3` deployment，它将在接下来的步骤中被部署到集群 `cluster-2` 上：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    $ kubectl delete deployment reviews-v3
    {{< /text >}}

1. 在远程 `cluster-2` 集群上部署 `reviews-v3` 服务以及其它相关服务：

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

    _请注意：_ `ratings` 服务定义也添加到远程集群是因为 `reviews-v3` 是 `ratings` 服务的客户端，因此 `reviews-v3` 需要 `ratings` 服务的 DNS 条目。
    `reviews-v3` pod 里的 Istio sidecar 将在 DNS 解析为服务地址后确定适当的 `ratings` 端点。
    如果另外设置了多群集 DNS 解决方案，例如在联邦 Kubernetes 环境中，这些就不是必须的了。

1. 为 `istio-ingressgateway` [确定它的 IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)为 `INGRESS_HOST` 和 `INGRESS_PORT` 变量以访问网关。

    重复访问 `http://<INGRESS_HOST>:<INGRESS_PORT>/productpage`，每个版本的 `reviews` 都应负载均衡，包括远程集群上的 `reviews-v3`（红色星级）。
    可能需要几次访问（数十次）才能证明 `reviews` 版本之间是负载均衡的。
