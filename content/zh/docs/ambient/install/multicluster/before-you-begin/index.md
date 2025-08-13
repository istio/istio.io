---
title: 开始之前
description: 在多个集群上安装 Istio 之前的初始步骤。
weight: 1
keywords: [kubernetes,multicluster,ambient]
test: n/a
owner: istio/wg-environments-maintainers
next: /zh/docs/ambient/install/multicluster/multi-primary_multi-network
prev: /zh/docs/ambient/install/multicluster
---

{{< boilerplate alpha >}}

在开始多集群安装之前，请查看[部署模型指南](/zh/docs/ops/deployment/deployment-models)，
其中介绍了本指南中使用的基础概念。

此外，请查看要求并执行以下初始步骤。

## 要求 {#requirements}

### 集群 {#cluster}

本指南要求您拥有两个 Kubernetes 集群，
并且在任意[支持的 Kubernetes 版本：](/zh/docs/releases/supported-releases#support-status-of-istio-releases) {{< supported_kubernetes_versions >}}上支持 LoadBalancer `Services`。

### API 服务器访问 {#api-server-access}

每个集群中的 API 服务器必须能够被网格中的其他集群访问。
许多云提供商通过网络负载均衡器 (NLB) 使 API 服务器可公开访问。
Ambient [东西](https://en.wikipedia.org/wiki/East-west_traffic)网关无法用于公开 API 服务器，
因为它仅支持双 HBONE 流量。可以使用非 Ambient 东西网关来启用对 API 服务器的访问。

## 环境变量 {#environment-variables}

本指南将涉及两个集群：`cluster1` 和 `cluster2`。为了简化说明，我们将始终使用以下环境变量：

变量 | 描述
-------- | -----------
`CTX_CLUSTER1` | 默认 [Kubernetes 配置文件](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中用于访问 `cluster1` 集群的上下文名称。
`CTX_CLUSTER2` | 默认 [Kubernetes 配置文件](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)中用于访问 `cluster2` 集群的上下文名称。

在继续之前设置两个变量：

{{< text syntax=bash snip_id=none >}}
$ export CTX_CLUSTER1=<your cluster1 context>
$ export CTX_CLUSTER2=<your cluster2 context>
{{< /text >}}

## 配置信任 {#configure-trust}

多集群服务网格部署需要在网格中的所有集群之间建立信任。根据系统需求，
可能有多种可用于建立信任的选项。请参阅[证书管理](/zh/docs/tasks/security/cert-management/)，
了解所有可用选项的详细说明和说明。根据您选择的选项，Istio 的安装说明可能会略有不同。

本指南假设您使用通用根为每个主集群生成中间证书。
请按照[说明](/zh/docs/tasks/security/cert-management/plugin-ca-cert/)生成 CA
证书密钥并将其推送到 `cluster1` 和 `cluster2` 集群。

{{< tip >}}
如果您当前有一个使用自签名 CA 的集群（如[入门指南](/zh/docs/setup/getting-started/)中所述），
则需要使用[证书管理](/zh/docs/tasks/security/cert-management/)中描述的方法之一更改 CA。
更改 CA 通常需要重新安装 Istio。以下安装说明可能需要根据您选择的 CA 进行调整。
{{< /tip >}}

## 下一步 {#next-steps}

现在您已准备好跨多个集群安装 Istio Ambient 网格。

- [在不同网络上安装多主集群](/zh/docs/ambient/install/multicluster/multi-primary_multi-network)

{{< tip >}}
如果您计划使用 Helm 安装 Istio 多集群，
请首先遵循 Helm 安装指南中的 [Helm 先决条件](/zh/docs/setup/install/helm/#prerequisites)。
{{< /tip >}}
