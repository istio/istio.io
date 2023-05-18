---
title: 主从架构的安装
description: 跨主从集群，安装 Istio 网格。
weight: 20
icon: setup
keywords: [kubernetes,multicluster]
test: yes
owner: istio/wg-environments-maintainers
---

按照本指南，在 `cluster1` 主集群（{{< gloss >}}primary cluster{{< /gloss >}}）
安装 Istio 控制平面，并设置 `cluster2` 从集群（{{< gloss >}}remote cluster{{< /gloss >}}）
指向 `cluster1` 的控制平面。两个集群都运行在 `network1` 网络上,
所以两个集群的 Pod 之间，网络可直接连通。

继续安装之前，请先确认完成了[准备工作](/zh/docs/setup/install/multicluster/before-you-begin)中的步骤。

{{< boilerplate multi-cluster-with-metallb >}}

在此配置中，集群 `cluster1` 将监测两个集群 API Server 的服务端点。
以这种方式，控制平面就能为两个集群中的工作负载提供服务发现。

服务的工作负载（ Pod 到 Pod ）可跨集群边界直接通讯。

`cluster2` 中的服务将通过专用的[东西向](https://en.wikipedia.org/wiki/East-west_traffic)网关流量访问
`cluster1` 的控制平面。

{{< image width="75%"
    link="arch.svg"
    caption="同一网络的主从集群"
    >}}

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
$ istioctl install --set values.pilot.env.EXTERNAL_ISTIOD=true --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

需要注意的是，当 `values.pilot.env.EXTERNAL_ISTIOD` 被设置为 `true` 时，
安装在 `cluster1` 上的控制平面也可以作为其他远程集群的外部控制平面。
当这个功能被启用时，`istiod` 将试图获得领导权锁，并因此管理将附加到它的并且带有
[适当注解的](#set-the-control-plane-cluster-for-cluster2)远程集群
（本例中为 `cluster2`）。

## 在 `cluster1` 安装东西向网关 {#install-the-east-west-gateway-in-cluster1}

在 `cluster1` 中安装东西向流量专用网关，默认情况下，此网关将被公开到互联网上。
生产环境可能需要增加额外的准入限制（即：通过防火墙规则）来防止外部攻击。
咨询您的云供应商，了解可用的选项。

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --mesh mesh1 --cluster cluster1 --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
如果控制面已经安装了一个修订版，可在 `gen-eastwest-gateway.sh` 命令中添加
`--revision rev` 标志。
{{< /warning >}}

等待东西向网关获取外部 IP 地址：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## 在 `cluster1` 中开放控制平面 {#expose-the-control-plane-in-cluster1}

在安装 `cluster2` 之前，我们需要开放 `cluster1` 的控制平面，
以便 `cluster2` 中的服务能访问到服务发现：

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -f \
    @samples/multicluster/expose-istiod.yaml@
{{< /text >}}

## 设置集群 `cluster2` 的控制平面 {#set-the-control-plane-cluster-for-cluster2}

我们需要通过为 `istio-system` 命名空间添加注解来识别应管理集群
`cluster2` 的外部控制平面：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" create namespace istio-system
$ kubectl --context="${CTX_CLUSTER2}" annotate namespace istio-system topology.istio.io/controlPlaneClusters=cluster1
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
      network: network1
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

{{< tip >}}
为了便于演示，在这里我们使用 `injectionPath` 和 `remotePilotAddress` 参数配置控制平面的位置。
但在生产环境中，建议改为使用正确签名的 DNS 证书配置 `injectionURL` 参数，
类似于[外部控制平面说明](/zh-cn/docs/setup/install/external-controlplane/#register-the-new-cluster)中的显示配置。
{{< /tip >}}

将此配置应用到 `cluster2`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

## 附加 `cluster2` 作为 `cluster1` 的从集群 {#attach-cluster2-as-a-remote-cluster-of-cluster1}

为了将远程集群连接到它的控制平面，我们让 `cluster1`
中的控制平面访问 `cluster2` 中的 API 服务器。
这将执行以下操作：

- 使控制平面能够验证来自在 `cluster2` 中运行的工作负载的连接请求。
  如果没有 API Server 访问权限，控制平面将拒绝请求。

- 启用在 `cluster2` 中运行的服务端点发现。

因为它已包含在 `topology.istio.io/controlPlaneClusters` 命名空间注解中
`cluster1` 上的控制平面也将：

- 修补 `cluster2` 中 Webhook 中的证书。

- 启动命名空间控制器，在 `cluster2` 的命名空间中写入 ConfigMap。

为了能让 API 服务器访问 `cluster2`，
我们生成一个远程 Secret 并将其应用于 `cluster1`：

{{< text bash >}}
$ istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

**恭喜!** 您已经成功地安装了跨主从集群的 Istio 网格！

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
