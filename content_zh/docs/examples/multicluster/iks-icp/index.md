---
title: IBM Kubernetes 云服务 & IBM 私有云
description: IBM Kubernetes 云服务和 IBM 私有云之间的多集群示例。
weight: 75
keywords: [kubernetes,multicluster,hybrid]
---

本文示例演示了如何使用 Istio 多集群功能，借助 [Istio 多集群设置](/zh/docs/setup/kubernetes/multicluster-install/)将[IBM Cloud Private](https://www.ibm.com/cloud/private) 和 [IBM Cloud Kubernetes Service](https://console.bluemix.net/docs/containers/container_index.html) 两个集群连接起来。

## 设置两个集群

1.  [Install One IBM Cloud Private cluster](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0.3/installing/installing.html).
    __NOTE__: You can configure Pod CIDR ranges and service CIDR ranges by `network_cidr` and
    `service_cluster_ip_range` in `cluster/config.yaml` for IBM Cloud Private.

    {{< text plain >}}
    ## Network in IPv4 CIDR format
    network_cidr: 10.1.0.0/16
    ## Kubernetes Settings
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  [请求一个 IBM Cloud Kubernetes 服务集群](https://console.bluemix.net/docs/containers/container_index.html)。 
__NOTE__：默认情况下，配置 IBM Cloud Kubernetes 服务群集时，CIDR 如下所示。

    {{< text plain >}}
    pod subnet CIDR: 172.30.0.0/16.
    service subnet CIDR: 172.21.0.0/16.
    {{< /text >}}

## 跨 IBM Kubernetes 云服务和 IBM 私有云配置 pod 通信

由于这两个集群处于隔离的网络环境中，我们需要在它们之间建立 VPN 连接。

1.  在 IBM Cloud Kubernetes 服务集群中设置 strongSwan：

    1.  按照[这些说明](https://console.bluemix.net/docs/containers/cs_integrations.html)在 IBM Cloud Kubernetes 服务中设置 helm。

    1.  按照[这些说明](https://console.bluemix.net/docs/containers/cs_vpn.html)，使用 helm 图安装 strongSwan ，来自 `config.yaml` 的示例配置参数：

        {{< text plain >}}
        ipsec.auto: add
        remote.subnet: 10.0.0.0/24,10.1.0.0/16
        {{< /text >}}

    1.  获取 `vpn-strongswan` 服务的外部IP：

        {{< text bash >}}
        $ kubectl get svc vpn-strongswan
        {{< /text >}}

1.  在 IBM Cloud Private 中设置 strongSwan：

    1.  按照[这些说明](https://www.ibm.com/support/knowledgecenter/SS2L37_2.1.0.3/cam_strongswan.html)完成 IBM Cloud Private 的strongSwan变通办法。

    1.  按照[这些说明](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/app_center/create_release.html)，从管理控制台中的目录安装strongSwan，示例配置参数：

        {{< text plain >}}
        Namespace: default
        Operation at startup: start
        Local subnets: 10.0.0.0/24,10.1.0.0/16
        Remote gateway: Public IP of IKS vpn-strongswan service that you get earlier
        Remote subnets: 172.30.0.0/16,172.21.0.0/16
        Privileged authority for VPN pod: checked
        {{< /text >}}

    1.  通过在 IBM Cloud Kubernetes 服务集群上运行以下命令，验证 IBM Cloud Private 是否可以连接到 IBM Cloud Kubernetes 服务：

        {{< text bash >}}
        $ export STRONGSWAN_POD=$(kubectl get pod -l app=strongswan,release=vpn -o jsonpath='{ .items[0].metadata.name }')
        $ kubectl exec $STRONGSWAN_POD -- ipsec status
        {{< /text >}}

1.  确认 pod 可以通过从 IBM Cloud Kubernetes Service  ping  IBM Cloud Private 中的pod IP 来进行通信。

    {{< text bash >}}
    $ ping 10.1.14.30
    PING 10.1.14.30 (10.1.14.30) 56(84) bytes of data.
    64 bytes from 10.1.14.30: icmp_seq=1 ttl=59 time=51.8 ms
    {{< /text >}}

## 安装 Istio 用于多集群

[按照多集群安装步骤](/zh/docs/setup/kubernetes/multicluster-install/)进行安装和配置
IBM Cloud Private 和 IBM Cloud Kubernetes Service 上的本地 Istio 控制平面和 Istio 远程控制。

此示例使用 IBM Cloud Private 作为 Istio 本地控制平面，使用IBM Cloud Kubernetes Service 作为 Istio 远程控制平面。

按照[这些说明](/zh/docs/examples/multicluster/icp/)在集群中部署 Bookinfo 示例
