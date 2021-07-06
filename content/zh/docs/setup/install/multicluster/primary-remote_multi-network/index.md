---
title: 跨网络主-从架构的安装
description: 跨网络、主-从架构的 Istio 网格安装。
weight: 40
icon: setup
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---
按照本指南，在 `cluster1` 主集群（{{< gloss >}}primary cluster{{< /gloss >}}） 安装 Istio 控制平面，
并配置 `cluster2` 从集群（{{< gloss >}}remote cluster{{< /gloss >}}）指向 `cluster1` 的控制平面。
集群 `cluster1` 在  `network1` 网络上，而集群 `cluster2` 在  `network2` 网络上。
所以跨集群边界的 Pod 之间，网络不能直接连通。

继续安装之前，请确保完成了[准备工作](/zh/docs/setup/install/multicluster/before-you-begin)中的步骤。

在此配置中，集群 `cluster1` 将监测两个集群 API Server 的服务端点。
以这种方式，控制平面就能为两个集群中的工作负载提供服务发现。

跨集群边界的服务负载，通过专用的东西向流量网关，以间接的方式通讯。
每个集群中的网关必须可以从其他集群访问。

`cluster2` 中的服务将通过相同的的东西向网关访问 `cluster1` 控制平面。

{{< image width="75%"
    link="arch.svg"
    caption="Primary and remote clusters on separate networks"
    >}}

{{< tip >}}
目前，从集群配置文档在从集群中安装 Istio 服务器，该服务器用来为集群中的工作负载注入 CA 和 webhook。
但是，服务发现会被指向主集群的控制平面。

后续版本将完全消除在从集群中安装 Istiod 的需求。请保持关注！
{{< /tip >}}

## 为 `cluster1` 设置缺省网络 {#set-the-default-network-for-cluster1}

创建命名空间 istio-system 之后，我们需要设置集群的网络：

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

在 `cluster1` 安装专用的东西向流量网关。
默认情况下，此网关将被公开到互联网上。
生产系统可能需要额外的访问限制（即：通过防火墙规则）来防止外部攻击。
咨询你的云服务商，了解可用的选择。

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --mesh mesh1 --cluster cluster1 --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
如果随着版本修正已经安装控制面板，在 `gen-eastwest-gateway.sh` 命令中添加 `--revision rev` 标志。
{{< /warning >}}

等待东西向网关获取外部 IP 地址

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## 开放 `cluster1` 控制平面 {#expose-the-control-plane-in-cluster1}

安装 `cluster2` 之前，我们需要先开放 `cluster1` 的控制平面，以便 `cluster2` 中的服务能访问服务发现。

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -f \
    @samples/multicluster/expose-istiod.yaml@
{{< /text >}}

## 开放 `cluster1` 中的服务 {#expose-services-in-cluster1}

因为集群位于不同的网络，我们需要开放两个集群的东西向网关上的所有用户服务（*.local）。
虽然此网关被公开到互联网，但它背后的服务只能被拥有可信 mTLS 证书和工作负载 ID 的服务访问，
就像它们处于同一个网络一样。

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

## 为 `cluster2` 设置缺省网络 {#set-the-default-network-for-cluster2}

命名空间 istio-system 创建之后，我们需要设置集群的网络：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
{{< /text >}}

## 启用 API Server 访问 `cluster2` 配置 {#enable-access-to-cluster2}

在配置从集群之前，我们必须先把 `cluster2` API Server 的访问权限赋予 `cluster1` 控制平面。
这将执行以下操作：

- 开启控制平面的身份认证功能，以验证 `cluster2` 中工作负载的连接请求。如果没有 API Server 的访问权限，控制平面将会拒绝该请求。

- 在 `cluster2` 的服务端点开启服务发现。

为了能够访问 `cluster2` API Server，我们要生成一个远程 Secret，并把它应用到 `cluster1`。

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

## 将 `cluster2` 设为从集群 {#configure-cluster2-as-a-remote}

保存 `cluster1` 东西向网关的地址。

{{< text bash >}}
$ export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

现在，为 `cluster2` 创建一个从集群配置：

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

将此配置应用到 `cluster2`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

## 在 `cluster2` 安装东西向网关 {#install-the-east-west-gateway-in-cluster2}

仿照上面 `cluster1` 的操作，在 `cluster2` 中安装专用于东西向流量的网关，并且开放用户服务。

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --mesh mesh1 --cluster cluster2 --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -
{{< /text >}}

等待东西向网关获取外部 IP 地址：

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

**恭喜!** 你在跨网络、主-从架构的集群上，成功的安装了 Istio 网格。

## 后续步骤 {#next-steps}

现在，你可以[验证此次安装](/zh/docs/setup/install/multicluster/verify).
