---
title: 跨网络安装主从集群
description: 跨网络、跨主从集群安装 Istio 网格。
weight: 40
keywords: [kubernetes,multicluster]
test: no
owner: istio/wg-environments-maintainers
---

按照本指南，在 `cluster1` {{< gloss "primary cluster" >}}主集群{{< /gloss >}}安装
Istio 控制平面，并配置 `cluster2`
{{< gloss "remote cluster" >}}从集群{{< /gloss >}}指向 `cluster1` 的控制平面。
集群 `cluster1` 在 `network1` 网络上，而集群 `cluster2` 在 `network2` 网络上。
所以跨集群边界的 Pod 之间，网络不能直接连通。

继续安装之前，请确保完成了[准备工作](/zh/docs/setup/install/multicluster/before-you-begin)中的步骤。

{{< boilerplate multi-cluster-with-metallb >}}

在此配置中，集群 `cluster1` 将监测两个集群 API Server 的服务端点。
以这种方式，控制平面就能为两个集群中的工作负载提供服务发现。

跨集群边界的服务负载，通过专用的东西向流量网关，以间接的方式通讯。
每个集群中的网关必须可以从其他集群访问。

`cluster2` 中的服务将通过相同的东西向网关访问 `cluster1` 控制平面。

{{< image width="75%"
    link="arch.svg"
    caption="跨网络的主从集群"
    >}}

## 为 `cluster1` 设置默认网络 {#set-the-default-network-for-cluster1}

创建命名空间 istio-system 之后，我们需要设置集群的网络：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
{{< /text >}}

## 将 `cluster1` 设为主集群 {#configure-cluster1-as-a-primary}

为 `cluster1` 创建 `istioctl` 配置：

{{< tabset category-name="multicluster-primary-remote-install-type-primary-cluster" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

使用 istioctl 和 `IstioOperator` API 在 `cluster1` 中将 Istio 安装为主节点。

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
      externalIstiod: true
EOF
{{< /text >}}

将配置应用到 `cluster1`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
{{< /text >}}

请注意，`values.global.externalIstiod` 设置为 `true`。
这将启用安装在 `cluster1` 上的控制平面，使其也用作其他从集群的外部控制平面。
启用此特性后，`istiod` 将尝试获取领导选举锁，
并因此管理会附加到它的并且带有[适当注解的](#set-the-control-plane-cluster-for-cluster2)从集群
（本例中为 `cluster2`）。

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

使用以下 Helm 命令在 `cluster1` 中将 Istio 安装为主节点：

在 `cluster1` 中安装 `base` Chart：

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

然后，使用以下多集群设置在 `cluster1` 中安装 `istiod` Chart：

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.externalIstiod=true --set global.multiCluster.clusterName=cluster1 --set global.network=network1
{{< /text >}}

请注意，`values.global.externalIstiod` 设置为 `true`。
这使得安装在 `cluster1` 上的控制平面也可以用作其他远程集群的外部控制平面。
启用此功能后，`istiod` 将尝试获取领导锁，
从而管理连接到它的[适当注释的](#set-the-control-plane-cluster-for-cluster2)远程集群（在本例中为 `cluster2`）。

{{< /tab >}}

{{< /tabset >}}

## 在 `cluster1` 安装东西向网关 {#install-the-east-west-gateway-in-cluster1}

在 `cluster1` 安装专用的东西向流量网关。
默认情况下，此网关将被公开到互联网上。
生产系统可能需要额外的访问限制（即通过防火墙规则）来防止外部攻击。
咨询您的云服务商，了解可用的选择。

{{< tabset category-name="east-west-gateway-install-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
{{< /text >}}

{{< warning >}}
如果控制平面已随着版本修正一起安装，请在 `gen-eastwest-gateway.sh` 命令中添加
`--revision rev` 标志。
{{< /warning >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

使用以下 Helm 命令在 `cluster1` 中安装东西网关：

{{< text bash >}}
$ helm install istio-eastwestgateway istio/gateway -n istio-system --kube-context "${CTX_CLUSTER1}" --set name=istio-eastwestgateway --set networkGateway=network1
{{< /text >}}

{{< warning >}}
如果控制平面是使用修订版安装的，则必须在 Helm 安装命令中添加
`--set revision=<my-revision>` 标志。
{{< /warning >}}

{{< /tab >}}

{{< /tabset >}}

等待东西向网关获取外部 IP 地址：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
{{< /text >}}

## 开放 `cluster1` 控制平面 {#expose-the-control-plane-in-cluster1}

安装 `cluster2` 之前，我们需要先开放 `cluster1` 的控制平面，
以便 `cluster2` 中的服务能访问服务发现。

{{< text bash >}}
$ kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f \
    @samples/multicluster/expose-istiod.yaml@
{{< /text >}}

{{< warning >}}
如果控制平面指定了版本 `rev`，需要改为执行以下命令：

{{< text bash >}}
$ sed 's/{{.Revision}}/rev/g' @samples/multicluster/expose-istiod-rev.yaml.tmpl@ | kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f -
{{< /text >}}

{{< /warning >}}

## 为 `cluster2` 设置控制平面集群 {#set-the-control-plane-cluster-for-cluster2}

命名空间 `istio-system` 创建之后，我们需要设置集群的网络：
我们需要通过为 `istio-system` 命名空间添加注解来识别应管理 `cluster2` 的外部控制平面集群：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" create namespace istio-system
$ kubectl --context="${CTX_CLUSTER2}" annotate namespace istio-system topology.istio.io/controlPlaneClusters=cluster1
{{< /text >}}

将 `topology.istio.io/controlPlaneClusters` 命名空间注解设置为
`cluster1` 将指示运行在 `cluster1` 上的相同命名空间（本例中为 istio-system）中的
`istiod` 管理[作为从集群接入](#attach-cluster2-as-a-remote-cluster-of-cluster1)的 `cluster2`。

## 为 `cluster2` 设置默认网络 {#set-the-default-network-for-cluster2}

通过向 `istio-system` 命名空间添加标签来设置 `cluster2` 的网络：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
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

{{< tabset category-name="multicluster-primary-remote-install-type-remote-cluster" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    istiodRemote:
      injectionPath: /inject/cluster/cluster2/net/network2
    global:
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
{{< /text >}}

将配置应用到 `cluster2`：

{{< text bash >}}
$ istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

使用以下 Helm 命令在 `cluster2` 中将 Istio 作为远程安装：

在 `cluster2` 中安装 `base` Chart：

{{< text bash >}}
$ helm install istio-base istio/base -n istio-system --set profile=remote --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

然后，使用以下多集群设置在 `cluster2` 中安装 `istiod` Chart：

{{< text bash >}}
$ helm install istiod istio/istiod -n istio-system --set profile=remote --set global.multiCluster.clusterName=cluster2 --set global.network=network2 --set istiodRemote.injectionPath=/inject/cluster/cluster2/net/network2  --set global.configCluster=true --set global.remotePilotAddress="${DISCOVERY_ADDRESS}" --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

{{< tip >}}

仅从 Istio 版本 1.24 开始，才可以使用 `base` 和 `istiod` Helm Chart 的 `remote` 配置文件。

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

{{< tip >}}
此处我们使用 `injectionPath` 和 `remotePilotAddress` 参数配置控制平面的位置。
仅为了便于演示，但在生产环境中，建议使用正确签名的 DNS 证书来配置 `injectionURL` 参数，
类似于[外部控制平面说明](/zh/docs/setup/install/external-controlplane/#register-the-new-cluster)所示的配置。
{{< /tip >}}

## 作为 `cluster1` 的从集群接入 `cluster2` {#attach-cluster2-as-a-remote-cluster-of-cluster1}

为了将从集群附加到其控制平面，我们让 `cluster1` 中的控制平面访问
`cluster2` 中的 API 服务器。这将执行以下操作：

- 使控制平面能够验证来自在 `cluster2` 中所运行的工作负载的连接请求。
  如果没有 API 服务器访问权限，则该控制平面将拒绝这些请求。

- 启用在 `cluster2` 中运行的服务端点的发现。

因为它已包含在 `topology.istio.io/controlPlaneClusters` 命名空间注解中
`cluster1` 上的控制平面也将：

- 修补 `cluster2` 中 Webhook 中的证书。

- 启动命名空间控制器，在 `cluster2` 的命名空间中写入 ConfigMap。

为了能让 API 服务器访问 `cluster2`，
我们生成一个从属 Secret 并将其应用于 `cluster1`：

{{< text bash >}}
$ istioctl create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
{{< /text >}}

## 在 `cluster2` 安装东西向网关 {#install-the-east-west-gateway-in-cluster2}

仿照上面 `cluster1` 的操作，在 `cluster2` 中安装专用于东西向流量的网关，并且开放用户服务。

{{< tabset category-name="east-west-gateway-install-type-cluster-2" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text bash >}}
$ @samples/multicluster/gen-eastwest-gateway.sh@ \
    --network network2 | \
    istioctl --context="${CTX_CLUSTER2}" install -y -f -
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

使用以下 Helm 命令在 `cluster2` 中安装东西网关：

{{< text bash >}}
$ helm install istio-eastwestgateway istio/gateway -n istio-system --kube-context "${CTX_CLUSTER2}" --set name=istio-eastwestgateway --set networkGateway=network2
{{< /text >}}

{{< warning >}}
如果控制平面是使用修订安装的，则必须在 Helm 安装命令中添加
`--set revision=<my-revision>`。
{{< /warning >}}

{{< /tab >}}

{{< /tabset >}}

等待东西向网关获取外部 IP 地址：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
{{< /text >}}

## 开放 `cluster2` 和 `cluster2` 中的服务 {#expose-services-in-cluster1-and-cluster2}

因为集群位于不同的网络，所以我们需要开放两个集群的东西向网关上的所有用户服务（*.local）。
虽然此网关被公开到互联网，但它背后的服务只能被拥有可信 mTLS 证书和工作负载 ID 的服务访问，
就像它们处于同一个网络一样。

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    @samples/multicluster/expose-services.yaml@
{{< /text >}}

{{< tip >}}
由于 `cluster2` 是使用远程配置文件安装的，
因此在主集群上开放服务将在两个集群的东西向网关上开放这些服务。
{{< /tip >}}

**恭喜!** 您成功跨网络、跨主从集群安装了 Istio 网格。

## 后续步骤 {#next-steps}

现在，您可以[验证安装结果](/zh/docs/setup/install/multicluster/verify)。

## 清理 {#cleanup}

使用与安装 Istio 相同的机制（istioctl 或 Helm）从
`cluster1` 和 `cluster2` 中卸载 Istio。

{{< tabset category-name="multicluster-uninstall-type-cluster-1" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

在 `cluster1` 中卸载 Istio：

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER1}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

在 `cluster2` 中卸载 Istio：

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall --context="${CTX_CLUSTER2}" -y --purge
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

从 `cluster1` 中删除 Istio Helm 安装：

{{< text syntax=bash >}}
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-eastwestgateway -n istio-system --kube-context "${CTX_CLUSTER1}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
{{< /text >}}

从 `cluster1` 中删除 `istio-system` 命名空间：

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
{{< /text >}}

从 `cluster2` 中删除 Istio Helm 安装：

{{< text syntax=bash >}}
$ helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-eastwestgateway -n istio-system --kube-context "${CTX_CLUSTER2}"
$ helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER2}"
{{< /text >}}

从 `cluster2` 中删除 `istio-system` 命名空间：

{{< text syntax=bash >}}
$ kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
{{< /text >}}

（可选）删除 Istio 安装的 CRD：

删除 CRD 会永久删除您在集群中创建的所有 Istio 资源。
要删除集群中安装的 Istio CRD，请执行以下操作：

{{< text syntax=bash snip_id=delete_crds >}}
$ kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
$ kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
