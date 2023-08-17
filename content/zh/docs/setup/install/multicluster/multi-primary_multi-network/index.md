---
title: 跨网络多主架构的安装 
description: 跨网络、多主架构的 Istio 网格安装。
weight: 30
icon: setup
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---

按照本指南，在 `cluster1` 和 `cluster2` 两个集群上，安装 Istio 控制平面，
且将两者均设置为主集群（{{< gloss >}}primary cluster{{< /gloss >}}）。
集群 `cluster1` 在 `network1` 网络上，而集群 `cluster2` 在 `network2` 网络上。
这意味着这些跨集群边界的 Pod 之间，网络不能直接连通。

继续安装之前，请确保完成了[准备工作](/zh/docs/setup/install/multicluster/before-you-begin)中的步骤。

{{< boilerplate multi-cluster-with-metallb >}}

在此配置中，`cluster1` 和 `cluster2` 均监测两个集群 API Server 的服务端点。

跨集群边界的服务负载通过专用的[东西向](https://en.wikipedia.org/wiki/East-west_traffic)网关，
以间接的方式通讯。每个集群中的网关在其他集群必须可以访问。

{{< image width="75%"
    link="arch.svg"
    caption="跨网络的多主集群"
    >}}

## 为 `cluster1` 设置缺省网络 {#set-the-default-network-for-cluster1}

创建命名空间 `istio-system` 之后，我们需要设置集群的网络：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## 将 `cluster1` 设为主集群 {#configure-cluster1-as-a-primary}

为 `cluster1` 创建 Istio 配置文件：

{{< text bash >}}
$ cat <<EOF > cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF
{{< /text >}}

将配置文件应用到 `cluster1`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

## 在 `cluster1` 安装东西向网关  {#install-the-east-west-gateway-in-cluster1}

在 `cluster1` 安装专用的
[东西向](https://en.wikipedia.org/wiki/East-west_traffic)网关。
默认情况下，此网关将被公开到互联网上。
生产系统可能需要添加额外的访问限制（即：通过防火墙规则）来防止外部攻击。
咨询您的云服务商，了解可用的选择。

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --mesh mesh1 --cluster cluster1 --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
如果控制面已经安装了一个修订版，可以在 `gen-eastwest-gateway.sh` 命令中添加
`--revision rev` 标志。
{{< /warning >}}

等待东西向网关被分配外部 IP 地址：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## 开放 `cluster1` 中的服务 {#expose-services-in-cluster1}

因为集群位于不同的网络中，所以我们需要在两个集群东西向网关上开放所有服务（*.local）。
虽然此网关在互联网上是公开的，但它背后的服务只能被拥有可信 mTLS 证书、工作负载 ID 的服务访问，
就像它们处于同一网络一样。

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

## 为 `cluster2` 设置缺省网络 {#set-the-default-network-for-cluster2}

命名空间 istio-system 创建完成后，我们需要设置集群的网络：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
{{< /text >}}

## 将 cluster2 设为主集群 {#configure-cluster2-as-a-primary}

为 `cluster2` 创建 Istio 配置文件：

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
EOF
{{< /text >}}

将配置文件应用到 `cluster2`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

## 在 `cluster2` 安装东西向网关 {#install-the-east-west-gateway-in-cluster2}

仿照上面 `cluster1` 的操作，在 `cluster2` 安装专用于东西向流量的网关。

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --mesh mesh1 --cluster cluster2 --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -
{{< /text >}}

等待东西向网关被分配外部 IP 地址：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
{{< /text >}}

## 开放 `cluster2` 中的服务 {#expose-services-in-cluster2}

仿照上面 `cluster1` 的操作，通过东西向网关开放服务。

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

## 启用端点发现 {#enable-endpoint-discovery}

在 `cluster2` 中安装一个提供 `cluster1` API Server 访问权限的远程 Secret。

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"
{{< /text >}}

在 `cluster1` 中安装一个提供 `cluster2` API Server 访问权限的远程 Secret。

{{< text bash >}}
$ istioctl create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**恭喜!** 您在跨网络多主架构的集群上，成功的安装了 Istio 网格。

## 后续步骤 {#next-steps}

现在，您可以[验证此次安装](/zh/docs/setup/install/multicluster/verify)。

## 清理 {#cleanup}

1. 卸载 `cluster1` 中的 Istio：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
    $ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
    {{< /text >}}

1. 卸载 `cluster2` 中的 Istio：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
    $ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
    {{< /text >}}
