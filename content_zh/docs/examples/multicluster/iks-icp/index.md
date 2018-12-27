---
title: IBM Cloud Kubernetes Service & IBM Cloud Private 
description: IBM Cloud Kubernetes Service 和 IBM Cloud Private 之间的多集群示例。
weight: 75
keywords: [kubernetes,多集群,hybrid]
---

本文示例演示了如何使用 Istio 多集群功能，借助 [基于 VPN 的多集群设置](/zh/docs/setup/kubernetes/multicluster-install/vpn/)将 [IBM Cloud Private](https://www.ibm.com/cloud/private) 和 [IBM Cloud Kubernetes Service](https://console.bluemix.net/docs/containers/container_index.html) 两个集群连接起来。

## 设置两个集群

1.  [安装一个 IBM Cloud Private 集群](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/installing/installing.html).
    __注意__:  确保各个集群的 Pod CIDR ranges 和 service CIDR ranges 是相互独立的、没有重叠。这可以通过配置文件 `cluster/config.yaml`中的 `network_cidr` 和 `service_cluster_ip_range` 配置。

    {{< text plain >}}
    ## IPv4 CIDR 格式的网络
    network_cidr: 10.1.0.0/16
    ## Kubernetes 设置
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  [创建一个 IBM Cloud Kubernetes Service 集群](https://console.bluemix.net/docs/containers/container_index.html)。
    __注意__：默认情况下，配置 IBM Cloud Kubernetes 服务群集时，CIDR 如下所示。

    {{< text plain >}}
    pod subnet CIDR: 172.30.0.0/16.
    service subnet CIDR: 172.21.0.0/16.
    {{< /text >}}

## 配置跨 IBM Cloud Kubernetes Service 和 IBM Cloud Private  pod 的集群通信

由于这两个集群处于隔离的网络环境中，我们需要在它们之间建立 VPN 连接。

1.  在 IBM Cloud Kubernetes Service 集群中设置 strongSwan：

    1.  按照[在 IBM Cloud Kubernetes Service 中设置 Helm](https://console.bluemix.net/docs/containers/cs_integrations.html)。

    1.  按照[使用 helm 图安装 strongSwan](https://console.bluemix.net/docs/containers/cs_vpn.html) ，来自 `config.yaml` 的示例配置参数：

        {{< text plain >}}
        ipsec.auto: add
        remote.subnet: 10.0.0.0/24,10.1.0.0/16
        {{< /text >}}

    1.  获取 `vpn-strongswan` 服务的外部 IP：

        {{< text bash >}}
        $ kubectl get svc vpn-strongswan
        {{< /text >}}

1.  在 IBM Cloud Private 中设置 strongSwan：

    1.  按照[IBM Cloud Private 的 strongSwan 安装](https://www.ibm.com/support/knowledgecenter/SS2L37_2.1.0.3/cam_strongswan.html)办法完成。

    1.  按照[在目录中部署 Helm 图表](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/app_center/create_release.html)的方法，从管理控制台中的目录安装 strongSwan，示例配置参数：

        {{< text plain >}}
        Namespace: default
        Operation at startup: start
        Local subnets: 10.0.0.0/24,10.1.0.0/16
        Remote gateway: Public IP of IKS vpn-strongswan service that you get earlier
        Remote subnets: 172.30.0.0/16,172.21.0.0/16
        Privileged authority for VPN pod: checked
        {{< /text >}}

    1.  通过在 IBM Cloud Kubernetes Service 集群上运行以下命令，验证 IBM Cloud Private 是否可以连接到 IBM Cloud Kubernetes Service ：

        {{< text bash >}}
        $ export STRONGSWAN_POD=$(kubectl get pod -l app=strongswan,release=vpn -o jsonpath='{ .items[0].metadata.name }')
        $ kubectl exec $STRONGSWAN_POD -- ipsec status
        {{< /text >}}

1.  确认 pod 可以通过从 IBM Cloud Kubernetes Service  ping  IBM Cloud Private 中的 pod IP 来进行通信。

    {{< text bash >}}
    $ ping 10.1.14.30
    PING 10.1.14.30 (10.1.14.30) 56(84) bytes of data.
    64 bytes from 10.1.14.30: icmp_seq=1 ttl=59 time=51.8 ms
    {{< /text >}}

## 多集群安装 Istio

按照[基于 VPN 的多集群安装步骤](/zh/docs/setup/kubernetes/multicluster-install/vpn/)进行安装和配置
IBM Cloud Private 和 IBM Cloud Kubernetes Service 上的本地 Istio 控制平面和 Istio 远程控制。

此示例使用 IBM Cloud Private 作为 Istio 本地控制平面，使用 IBM Cloud Kubernetes Service 作为 Istio 远程控制平面。

按照[IBM Cloud Private](/zh/docs/examples/multicluster/icp/)在集群中部署 Bookinfo 示例
