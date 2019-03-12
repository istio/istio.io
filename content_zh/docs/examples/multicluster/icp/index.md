---
title: IBM Cloud Private
description: 多 IBM Cloud Private 集群安装 Istio 示例。
weight: 70
keywords: [kubernetes,multicluster]
---

此示例演示了如何在[基于 VPN 的多集群安装指导](/zh/docs/setup/kubernetes/install/multicluster/vpn/) 的帮助下使用 Istio 的多集群功能连接两个
[IBM Cloud Private](https://www.ibm.com/cloud/private) 集群。

## 创建 IBM Cloud Private 集群

1.  [安装两个 IBM Cloud Private 集群](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/installing/installing.html).
    __注意__: 确保各个集群的 Pod CIDR ranges 和 service CIDR ranges 是相互独立的、没有重叠。这可以通过配置文件 `cluster/config.yaml` 中的 `network_cidr` 和
    `service_cluster_ip_range` 配置。

    {{< text plain >}}
    ## Network in IPv4 CIDR format
    network_cidr: 10.1.0.0/16
    ## Kubernetes Settings
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  在 IBM Cloud Private 集群安装完成后，验证是否能通过 `kubectl` 访问集群。在此示例中使用的两个集群名称分别假定为 `cluster-1` 和 `cluster-2`。

    1.  [使用 `kubectl` 配置 `cluster-1`](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/manage_cluster/cfc_cli.html).

    1.  检查集群状态:

        {{< text bash >}}
        $ kubectl get nodes
        $ kubectl get pods --all-namespaces
        {{< /text >}}

    1.  重复以上两个步骤以验证 `cluster-2` 集群。

## 配置跨 IBM Cloud Private 集群 Pod 通信

IBM Cloud Private 默认使用 Calico Node-to-Node Mesh 来管理容器网络。在各个节点上的 BGP 客户端分发 IP 路由信息到所有节点。

为了确保 pod 可以跨集群通信，你需要配置集群中所有节点的 IP 路由信息。这需要两个步骤：

1.  添加从 `cluster-1` 到 `cluster-2` 的路由信息。

1.  添加从 `cluster-2` 到 `cluster-1` 的路由信息。

你可以查看如何添加从 `cluster-1` 到 `cluster-2` 的 IP 路由来验证跨集群间 pod 通信。在 Node-to-Node Mesh 模式下，集群中的每个节点都会有连接到其他同级节点的 IP 路由信息。在此示例中，两个集群都有三个节点。

`cluster-1` 的 `hosts` 文件：

{{< text plain >}}
9.111.255.21 gyliu-icp-1
9.111.255.129 gyliu-icp-2
9.111.255.29 gyliu-icp-3
{{< /text >}}

`cluster-2` 的 `hosts` 文件：

{{< text plain >}}
9.111.255.152 gyliu-ubuntu-3
9.111.255.155 gyliu-ubuntu-2
9.111.255.77 gyliu-ubuntu-1
{{< /text >}}

1.  使用命令 `ip route | grep bird` 在 `cluster-1` 集群的所有节点上获取路由信息。

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

1.  在 `cluster-1` 中的三个节点总共有三条 IP 路由信息。

    {{< text plain >}}
    10.1.158.192/26 via 9.111.255.129 dev tunl0  proto bird onlink
    10.1.198.128/26 via 9.111.255.21 dev tunl0  proto bird onlink
    10.1.43.0/26 via 9.111.255.29 dev tunl0  proto bird onlink
    {{< /text >}}

1.  在 `cluster-2` 的三个节点上分别使用以下命令添加三条 IP 路由信息：

    {{< text bash >}}
    $ ip route add 10.1.158.192/26 via 9.111.255.129
    $ ip route add 10.1.198.128/26 via 9.111.255.21
    $ ip route add 10.1.43.0/26 via 9.111.255.29
    {{< /text >}}

1.  你可以使用同样的步骤添加从 `cluster-2` 到 `cluster-1` 的路由信息。配置完成后，这两个集群上的所有节点都可以相互通信。

1.  在 `cluster-1` 上 ping `cluster-2` 上的 pod 以验证跨 pod 通信。下面是一个在 `cluster-2` 上 IP 为 `20.1.47.150` 的 pod。

    {{< text bash >}}
    $ kubectl get pods -owide  -n kube-system | grep platform-ui
    platform-ui-lqccp                                             1/1       Running     0          3d        20.1.47.150     9.111.255.77
    {{< /text >}}

1.  从 `cluster-1` 的一个节点上 ping 此 IP 应该会成功。

    {{< text bash >}}
    $ ping 20.1.47.150
    PING 20.1.47.150 (20.1.47.150) 56(84) bytes of data.
    64 bytes from 20.1.47.150: icmp_seq=1 ttl=63 time=0.759 ms
    {{< /text >}}

此节中的这些步骤通过配置一个完整的 IP 路由 mesh，使跨两个 IBM Cloud Private 集群的所有节点的相互通信成为可能。

## 为多集群安装 Istio

[跟随基于 VPN 的多集群安装步骤](/zh/docs/setup/kubernetes/install/multicluster/vpn/) 来在 `cluster-1` 和 `cluster-2` 集群上分别安装并配置本地 Istio 控制平面和远程 Istio。

此示例使用 `cluster-1` 作为本地 Istio 控制平面，`cluster-2` 作为远程 Istio。

## 跨集群部署 Bookinfo 示例

__注意__: 以下示例启用了 [自动 sidecar 注入](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#sidecar-的自动注入).

1.  安装 `bookinfo` 在第一个集群 `cluster-1` 上。移除此集群上的 `reviews-v3` deployment 以便将其部署在 `cluster-2` 上：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    $ kubectl delete deployment reviews-v3
    {{< /text >}}

1.  创建 `reviews-v3.yaml` manifest 以便部署在 `cluster-2` 上：

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

    _注意：_ `ratings` service 的定义被添加到了 `cluster-2` 集群上因为 `reviews-v3` 服务会调用 `ratings` 服务，而添加一个 service 对象会添加一条 DNS 记录。在 `reviews-v3` pod 中的 Istio sidecar 在 DNS 解析出 service 地址后将会选择合适的 `ratings` 服务 endpoint。但是如果设置了另外的多集群 DNS 解析，那么这个步骤就不是必须的了，比如在一个 federated Kubernetes 环境中。

1.  安装 `reviews-v3` deployment 到 `cluster-2`。

    {{< text bash >}}
    $ kubectl apply -f $HOME/reviews-v3.yaml
    {{< /text >}}

1.  [ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/#确定入口-ip-和端口)，确定  `istio-ingressgateway` 的 `INGRESS_HOST` 和 `INGRESS_PORT` 变量以访问 gateway。

    重复地访问 `http://<INGRESS_HOST>:<INGRESS_PORT>/productpage` 会发现请求应该被均匀的分发到了各个版本的 `reviews` 服务上, 包括在 `cluster-2` 集群上的 `reviews-v3` 服务（红色星星）。可能需要访问许多次才能展示出请求确实是被均匀的分发到了所有版本的 `reviews` 服务上。
