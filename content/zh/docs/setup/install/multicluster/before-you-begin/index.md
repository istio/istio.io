---
title: 准备工作
description: 在多个集群上安装 Istio 之前的初始步骤。
weight: 1
icon: setup
keywords: [kubernetes,multicluster]
test: n/a
owner: istio/wg-environments-maintainers
---

在开始多集群安装之前，回顾[部署模型指南](/zh/docs/ops/deployment/deployment-models)，
了解本指南中使用的基本概念。

另外，检查需求并执行以下初始步骤。

## 需求 {#requirements}

### 集群 {#cluster}

本指南需要您具备两个 Kubernetes 集群，且版本需为
[Kubernetes 支持的版本：](/zh/docs/releases/supported-releases#support-status-of-istio-releases){{< supported_kubernetes_versions >}}。

{{< tip >}}
如果您正在 `kind` 测试多集群设置，则可以使用脚本
`samples/kind-lb/setupkind.sh` 快速设置具有负载均衡器支持的集群：

{{< text bash >}}
$ @samples/kind-lb/setupkind.sh@ --cluster-name cluster-1 --ip-space 254
$ @samples/kind-lb/setupkind.sh@ --cluster-name cluster-2 --ip-space 255
{{< /text >}}

{{< /tip >}}

### API 服务器访问 {#api-server-access}

每个集群中的 API 服务器必须能被网格中其他集群访问。
很多云服务商通过网络负载均衡器（NLB）开放 API 服务器的公网访问。
如果 API 服务器不能被直接访问，则需要调整安装流程以放开访问。
例如，用于多网络、主从架构配置的[东西向](https://en.wikipedia.org/wiki/East-west_traffic)网关就可以用来开启
API 服务器的访问。

## 环境变量 {#environment-variables}

本指南将引用 `cluster1` 和 `cluster2` 两个集群。
以下环境变量将在整个过程中被使用，以简化说明：

| 变量           | 描述                                                                                                                                                   |
|----------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `CTX_CLUSTER1` | [Kubernetes 配置文件](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的默认上下文名称，用于访问集群 `cluster1`。 |
| `CTX_CLUSTER2` | [Kubernetes 配置文件](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的默认上下文名称，用于访问集群 `cluster2`。 |

继续之前，设置这两个环境变量：

{{< text syntax=bash snip_id=none >}}
$ export CTX_CLUSTER1=<your cluster1 context>
$ export CTX_CLUSTER2=<your cluster2 context>
{{< /text >}}

{{< tip >}}

如果您使用 `kind`，请设置以下上下文：

{{< text bash >}}
$ export CTX_CLUSTER1=$(kubectl config get-contexts -o name | grep kind-cluster-1)
$ export CTX_CLUSTER2=$(kubectl config get-contexts -o name | grep kind-cluster-2)
{{< /text >}}

{{< /tip >}}

## 配置信任关系 {#configure-trust}

多集群服务网格部署要求您在网格中的所有集群之间建立信任关系。
基于您的系统需求，可以有多个建立信任关系的选择。
参阅[证书管理](/zh/docs/tasks/security/cert-management/)，
以了解所有可用选项的详细描述和说明。根据您选择的方式，
Istio 的安装说明可能略有变化。

{{< tip >}}
如果您计划仅部署一个主集群（即采用本地——远程部署的方式），
您将只有一个 CA（即使用 `cluster1` 上的 `istiod`）为两个集群颁发证书。
在这种情况下，您可以跳过以下 CA 证书生成步骤，
并且只需使用默认自签名的 CA 进行安装。
{{< /tip >}}

本指南假设您使用一个公共根来为每个主集群生成中间证书。
请按照[说明](/zh/docs/tasks/security/cert-management/plugin-ca-cert/)，
生成并分别推送 CA 证书的秘钥给 `cluster1` 和 `cluster2`。

{{< tip >}}
如果您当前有一个自签名 CA 的独立集群（就像[入门](/zh/docs/setup/getting-started/)中描述的那样），
您需要用一个[证书管理](/zh/docs/tasks/security/cert-management/)中介绍的方法，来改变 CA。
改变 CA 通常需要重新安装 Istio。
以下安装说明可能必须根据您对 CA 的选择进行更改。
{{< /tip >}}

{{< tip >}}
如果您使用 `kind`，则可以使用提供的 Makefile
为您的集群快速生成自签名 CA 证书：

{{< text bash >}}
$ make -f @tools/certs/Makefile.selfsigned.mk@ \
    ROOTCA_CN="Root CA" \
    ROOTCA_ORG=istio.io \
    root-ca
$ make -f @tools/certs/Makefile.selfsigned.mk@ \
    INTERMEDIATE_CN="Cluster 1 Intermediate CA" \
    INTERMEDIATE_ORG=istio.io \
    cluster1-cacerts
$ make -f @tools/certs/Makefile.selfsigned.mk@ \
    INTERMEDIATE_CN="Cluster 2 Intermediate CA" \
    INTERMEDIATE_ORG=istio.io \
    cluster2-cacerts
{{< /text >}}

这将为每个集群创建一个根 CA 和中间 CA 证书，
然后您可以使用它们在集群之间建立信任。

要在每个集群中创建 `cacerts` Secret，请在生成证书后使用以下命令：

{{< text bash >}}
$ kubectl --context="${CTX_CLUSTER1}" create namespace istio-system
$ kubectl --context="${CTX_CLUSTER1}" create secret generic cacerts -n istio-system \
    --from-file=ca-cert.pem=cluster1/ca-cert.pem \
    --from-file=ca-key.pem=cluster1/ca-key.pem \
    --from-file=root-cert.pem=cluster1/root-cert.pem \
    --from-file=cert-chain.pem=cluster1/cert-chain.pem
$ kubectl --context="${CTX_CLUSTER2}" create namespace istio-system
$ kubectl --context="${CTX_CLUSTER2}" create secret generic cacerts -n istio-system \
    --from-file=ca-cert.pem=cluster2/ca-cert.pem \
    --from-file=ca-key.pem=cluster2/ca-key.pem \
    --from-file=root-cert.pem=cluster2/root-cert.pem \
    --from-file=cert-chain.pem=cluster2/cert-chain.pem
{{< /text >}}

这将在每个集群的 `istio-system` 命名空间中创建 `cacerts` Secret，
从而允许 Istio 使用您的自定义 CA 证书。

{{< /tip >}}

## 后续步骤 {#next-steps}

您现在已经准备好，可以跨越多个集群安装 Istio 网格了。
具体的安装步骤取决于您对网络和控制平面拓扑结构的需求。

选择最适合您需要的安装方式：

- [多主架构的安装](/zh/docs/setup/install/multicluster/multi-primary)

- [主从架构的安装](/zh/docs/setup/install/multicluster/primary-remote)

- [在不同的网络上，多主架构的安装](/zh/docs/setup/install/multicluster/multi-primary_multi-network)

- [在不同的网络上，主从架构的安装](/zh/docs/setup/install/multicluster/primary-remote_multi-network)

{{< tip >}}
如果您计划使用 Helm 安装 Istio 多集群，请首先遵循 Helm 安装指南中的
[Helm 先决条件](/zh/docs/setup/install/helm/#prerequisites)。
{{< /tip >}}

{{< tip >}}
对于跨越两个以上集群的网格，您可能需要使用一个以上的选项。
例如，每个 Region 一个主集群（即：多主）。每个 Zone 一个从集群，并使用 Region 主集群（即：主从）的控制平面。

更多信息，参阅[部署模型](/zh/docs/ops/deployment/deployment-models)。
{{< /tip >}}
