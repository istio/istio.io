---
title: Azure
description: 为 Istio 设置一个 Azure 集群的指令。
weight: 9
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/azure/
    - /zh/docs/setup/kubernetes/platform-setup/azure/
keywords: [platform-setup,azure]
---

跟随这些指令来为 Istio 准备一个 Azure 集群。

你可以通过完全支持 Istio 的 [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) 或者 [AKS-Engine](https://github.com/azure/aks-engine)，部署一个 Kubernetes 集群到 Azure 上。

## AKS

你可以通过 [the az cli](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough) 或者 [the Azure portal](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal) 创建一个 AKS 集群。

对于 `az` cli 的选项，完成 `az login` 认证或者使用 cloud shell，然后运行下面的命令。

1. 确定支持 AKS 的期望 region 名

    {{< text bash >}}
    $ az provider list --query "[?namespace=='Microsoft.ContainerService'].resourceTypes[] | [?resourceType=='managedClusters'].locations[]" -o tsv
    {{< /text >}}

1. 证实对于期望的 region 有支持的 Kubernetes 版本

    使用从上面步骤中期望的 region 值替换 `my location`，然后执行：

    {{< text bash >}}
    $ az aks get-versions --location "my location" --query "orchestrators[].orchestratorVersion"
    {{< /text >}}

    确保最小值 `1.10.5` 被列出。

1. 创建 resource group 和部署 AKS 集群

    使用期望的名字替换 `myResourceGroup` 和 `myAKSCluster`，使用第一步中的名字替换 `mylocation`，替换 `1.10.5` 如果其在 region 中不被支持，然后执行：

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.10.5 --generate-ssh-keys
    {{< /text >}}

1. 取得 AKS `kubeconfig` 证书

    使用从之前步骤中获得的名字替换 `myResourceGroup` 和 `myAKSCluster` 并且执行：

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}

## AKS-Engine

1. [跟随这些命令](https://github.com/Azure/aks-engine/blob/master/docs/tutorials/quickstart.md#install-aks-engine)来获取和安装 `aks-engine` 的二进制版本。

1. 下载支持部署 Istio 的 `aks-engine` API 模型定义：

    {{< text bash >}}
    $ wget https://raw.githubusercontent.com/Azure/aks-engine/master/examples/service-mesh/istio.json
    {{< /text >}}

    注意：可能使用其他可以和 Istio 一起工作的 api 模型定义。MutatingAdmissionWebhook 和 ValidatingAdmissionWebhook 准入控制标识和 RBAC 被默认打开。从 [aks-engine api 模型默认值](https://github.com/Azure/aks-engine/blob/master/docs/topics/clusterdefinitions.md)获取更多信息。

1. 使用 `istio.json` 模板来部署你的集群。你能发现对于参数的参考在
   [官方文档](https://github.com/Azure/aks-engine/blob/master/docs/tutorials/deploy.md#step-3-edit-your-cluster-definition)中。

    | 参数                             | 期望值             |
    |---------------------------------------|----------------------------|
    | `subscription_id`                     | Azure Subscription Id      |
    | `dns_prefix`                          | 集群 DNS 前缀         |
    | `location`                            | 集群位置           |

    {{< text bash >}}
    $ aks-engine deploy --subscription-id <subscription_id> \
      --dns-prefix <dns_prefix> --location <location> --auto-suffix \
      --api-model istio.json
    {{< /text >}}

    {{< tip >}}
    几分钟之后，你能发现你的集群在你的 Azure subscription 上的
    resource group 里被叫做 `<dns_prefix>-<id>`。假设 `dns_prefix` 有这样的值 `myclustername`，一个带着唯一集群 ID `mycluster-5adfba82` 的有效的 resource group。`aks-engine` 在 `_output` 文件夹中生成你的 `kubeconfig`
    文件。
    {{< /tip >}}

1. 使用 `<dns_prefix>-<id>` 集群 ID，为了从 `_output` 文件夹复制你的 `kubeconfig` 到你的机器：

    {{< text bash >}}
    $ cp _output/<dns_prefix>-<id>/kubeconfig/kubeconfig.<location>.json \
        ~/.kube/config
    {{< /text >}}

    比如：

    {{< text bash >}}
    $ cp _output/mycluster-5adfba82/kubeconfig/kubeconfig.westus2.json \
      ~/.kube/config
    {{< /text >}}
