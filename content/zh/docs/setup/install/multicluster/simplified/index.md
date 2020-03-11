---
title: 简化地多集群安装[实验性]
description: 配置一个跨多个 Kubernetes 集群的 Istio 网格。
weight: 1
keywords: [kubernetes,multicluster]
---

{{< boilerplate experimental-feature-warning >}}

本指南描述了如何使用一种简化的实验性方式来配置一个跨多个 Kubernetes 集群的 Istio 网格。
我们希望在将来的版本中继续开发这项功能，因此非常期待您对这个流程进行反馈。

在此我们集中讨论如何连接多集群网格的细节，有关其它背景信息，请参考[多集群部署模型](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)。
我们将展示如何将同一网络上的两个集群与另一个网络上的第三个集群连接起来。

使用本指南中展示的方法会导致 Istio 控制平面的实例部署在网格中的每个集群中。
尽管这是一种常见配置，但其他更复杂的拓扑也是可能的，只是需要使用一些手动的过程来完成，此处不再赘述。

## 开始之前{#before-you-begin}

此处我们描述的过程主要针对相对干净的未部署过 Istio 的集群。
我们在将来能将支持扩展到现有集群。

为了便于说明，本指南假定您已经创建了三个 Kubernetes 集群：

- 一个在 `network-east` 网络上的名为 `cluster-east-1` 的集群。
- 一个在 `network-east` 网络上的名为 `cluster-east-2` 的集群。
- 一个在 `network-west` 网络上的名为 `cluster-west-1` 的集群。

这些集群应当尚未安装 Istio。前两个集群在同一个网络，并可直连，而第三个集群在另一个网络。
请查看[平台设置说明](/zh/docs/setup/platform-setup)，以了解针对您的特定环境的任何特殊说明。

## 初步准备{#initial-preparations}

您需要执行一些一次性步骤才能设置多集群网格：

1. 确保您的所有集群都被包含在您的 [Kubernetes 配置文件](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#define-clusters-users-and-contexts)中，并为它们创建了上下文配置。完成后，您的配置文件应该包含类似如下内容：

    {{< text syntax="yaml" downloadas="kubeconfig.yaml" >}}
    kind: Config
    apiVersion: v1
    clusters:
    - cluster:
      name: cluster-east-1
    - cluster:
      name: cluster-east-2
    - cluster:
      name: cluster-west-1
    contexts:
    - context:
        cluster: cluster-east-1
      name: context-east-1
    - context:
        cluster: cluster-east-2
      name: context-east-2
    - context:
        cluster: cluster-west-1
      name: context-west-1
    {{< /text >}}

1. 决定您的多集群网格的名字。推荐使用一些短小好记的：

    {{< text bash >}}
    $ export MESH_ID=mymeshname
    {{< /text >}}

1. 决定组织名以用于创建用来让集群互相通信的根证书和中间证书。这通常可以从您的组织的 DNS 名中得来：

    {{< text bash >}}
    $ export ORG_NAME=mymeshname.mycompanyname.com
    {{< /text >}}

1. 创建一个工作目录，用于存储在集群启动过程中产生的若干文件：

    {{< text bash >}}
    $ export WORKDIR=mydir
    $ mkdir -p ${WORKDIR}
    $ cd ${WORKDIR}
    {{< /text >}}

1. 下载[设置脚本]({{<github_file >}}/samples/multicluster/setup-mesh.sh) 到您的工作目录。
该脚本负责创建必要的证书以启用跨集群通信，它为您准备了默认配置文件，并将在每个集群中部署和配置 Istio。

1. 最后，运行下载的脚本以准备网格。这会创建一个将用于保护网格中群集之间的通信安全的根密钥和证书，以及用于控制所有群集上部署的 Istio 的配置的 `base.yaml` 文件：

    {{< text bash >}}
    $ ./setup-mesh.sh prep-mesh
    {{< /text >}}

    请注意此步骤不会对集群产生任何影响，它只是在您的工作目录里创建了若干文件。

## 定制 Istio{#customizing-Istio}

上面的网格准备工作在您的工作目录里创建了一个名为 `base.yaml` 的文件。
这个文件定义了基本的 [`IstioControlPlane`](/zh/docs/reference/config/istio.operator.v1alpha12.pb/#IstioControlPlane) 配置，它用于将 Istio 部署到您的集群中（下面就会提到）。
您可以[定制 `base.yaml`](/zh/docs/setup/install/istioctl/#configure-the-feature-or-component-settings) 文件，以精确控制 Istio 将被如何部署到所有的集群中。

只有这些值不应该被修改：

{{< text plain >}}
values.gateway.istio-ingressgateway.env.ISTIO_MESH_NETWORK
values.global.controlPlaneSecurityEnabled
values.global.multiCluster.clusterName
values.global.network
values.global.meshNetworks
values.pilot.meshNetworks=
{{< /text >}}

这些值是通过以下步骤自动设置的，任何手动设置都会导致数据丢失。

## 创建网格{#creating-the-mesh}

通过编辑在您的工作目录中的 `topology.yaml` 文件来指定哪些集群将被包含在网格中。
为这三个集群都添加一个条目，使文件如下所示：

{{< text yaml >}}
mesh_id: mymeshname
contexts:
  context-east-1:
    network: network-east
  context-east-2:
    network: network-east
  context-west-1:
    network: network-west
{{< /text >}}

该拓扑文件保存了网格的名字，以及网络的上下文映射。当文件保存后，您就可以开始创建网格了。
这将部署 Istio 到每个集群，并配置每个势力以互相安全通信：

{{< text bash >}}
$ ./setup-mesh.sh apply
{{< /text >}}

想要往网格中添加或删除集群，只需要对应地更新该拓扑文件并重新应用这些更改。

{{< warning >}}
每当您使用 `setup-mesh.sh apply` 时，都会在您的工作目录中创建一些 secret 文件，尤其是与不同证书关联的一些私钥。
您应该存储并保护好这些 secrets。需要保护的这些文件是：

{{< text plain >}}
certs/root-key.pem - 根私钥
certs/intermediate-*/ca-key.pem - 中间私钥
{{< /text >}}

{{< /warning >}}

## 清理{#clean-up}

您可以使用以下命令从所有的已知集群中删除 Istio：

{{< text bash >}}
$ ./setup-mesh.sh teardown
{{< /text >}}
