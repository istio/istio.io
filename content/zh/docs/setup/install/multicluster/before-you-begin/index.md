---
title: 准备工作
description: 在多个集群上安装 Istio 之前的初始步骤。
weight: 1
icon: setup
keywords: [kubernetes,multicluster]
test: n/a
owner: istio/wg-environments-maintainers
---
在开始多集群安装之前，回顾[部署模型指南](/zh/docs/ops/deployment/deployment-models),
了解本指南中使用的基本概念。

另外，检查需求并执行以下初始步骤。

## 需求 {#requirements}

### 集群 {#cluster}

本指南需要你具备两个 Kubernetes 集群，且版本需为： {{< supported_kubernetes_versions >}}。

### API Server Access

每个集群中的 API 服务器必须能被网格中其他集群访问。
很多云服务商通过网络负载均衡器（NLB）开放 API 服务器的公网访问。
如果 API 服务器不能被直接访问，则需要调整安装流程以放开访问。
例如，用于多网络、主-从架构配置的
[东西向](https://en.wikipedia.org/wiki/East-west_traffic)网关
就可以用来开启 API 服务器的访问。

## 环境变量 {#environment-variables}

本指南将引用 `cluster1` 和 `cluster2` 两个集群。
以下环境变量将在整个过程中使用，以简化说明：

变量 | 描述
-------- | -----------
`CTX_CLUSTER1` | [Kubernetes 配置文件](https://kubernetes.io/zh/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的默认上下文名称，用于访问集群 `cluster1`。
`CTX_CLUSTER2` | [Kubernetes 配置文件](https://kubernetes.io/zh/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中的默认上下文名称，用于访问集群 `cluster2`。

继续之前，设置这两个变量：

{{< text syntax=bash snip_id=none >}}
$ export CTX_CLUSTER1=<your cluster1 context>
$ export CTX_CLUSTER2=<your cluster2 context>
{{< /text >}}

## 配置信任关系 {#configure-trust}

多集群服务网格部署要求你在网格中的所有集群之间建立信任关系。
基于你的系统需求，可以有多个建立信任关系的选择。
参阅[证书管理](/zh/docs/tasks/security/cert-management/)，以了解所有可用选项的详细描述和说明。
根据你选择的方式，Istio 的安装说明可能略有变化。

本指南假设你使用一个公共根，为每个集群生成中间证书。
按照[说明](/zh/docs/tasks/security/cert-management/plugin-ca-cert/)，
生成并分别推送 CA 证书 secret 给 `cluster1` 和 `cluster2`。

{{< tip >}}
如果你当前有一个自签名 CA 的独立集群
(就像 [入门](/zh/docs/setup/getting-started/) 中描述的那样)，
你需要用一个[证书管理](/zh/docs/tasks/security/cert-management/)中介绍的方法，来改变 CA。
改变 CA 通常需要重新安装 Istio。
以下安装说明可能必须根据你对 CA 的选择进行更改。
{{< /tip >}}

## 后续步骤 {#next-steps}

你现在已经准备好，可以跨越多个集群安装 Istio 网格了。
具体的安装步骤取决于你对网络和控制平面拓扑结构的需求。

选择最适合你需要的安装方式：

- [多主架构的安装](/zh/docs/setup/install/multicluster/multi-primary)

- [主-从架构的安装](/zh/docs/setup/install/multicluster/primary-remote)

- [在不同的网络上，多主架构的安装](/zh/docs/setup/install/multicluster/multi-primary_multi-network)

- [在不同的网络上，主-从架构的安装](/zh/docs/setup/install/multicluster/primary-remote_multi-network)

{{< tip >}}
对于跨越两个以上集群的网格，你可能需要使用一个以上的选项。
例如，每个 region 一个主集群（即：多主）。每个 zone 一个从集群，并使用 region 主集群（即：主从）的控制平面。

更多信息，参阅 [部署模型](/zh/docs/ops/deployment/deployment-models)。
{{< /tip >}}
