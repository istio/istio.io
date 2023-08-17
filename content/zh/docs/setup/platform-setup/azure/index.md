---
title: Azure
description: 为 Istio 设置一个 Azure 集群的操作说明。
weight: 10
skip_seealso: true
aliases:
  - /zh/docs/setup/kubernetes/prepare/platform-setup/azure/
  - /zh/docs/setup/kubernetes/platform-setup/azure/
keywords: [platform-setup,azure]
owner: istio/wg-environments-maintainers
test: no
---

跟随以下操作说明来为 Istio 准备一个 Azure 集群。

{{< tip >}}
Azure 为 Azure Kubernetes Service (AKS) 提供了
{{< gloss >}}managed control plane{{< /gloss >}}（托管控制面）加载项，
您可以用其代替 Istio 的手动安装。有关细节和教程请参阅
[为 Azure Kubernetes Service 部署基于 Istio 的服务网格加载项](https://learn.microsoft.com/zh-cn/azure/aks/istio-deploy-addon)。
{{< /tip >}}

您可以通过完全支持 Istio 的 [AKS](https://azure.microsoft.com/zh-cn/services/kubernetes-service/)
或者 [AKS-Engine](https://github.com/azure/aks-engine)，部署一个 Kubernetes 集群到 Azure 上。

## AKS

您可以通过 [Azure CLI](https://learn.microsoft.com/zh-cn/azure/aks/learn/quick-kubernetes-deploy-cli)
或者 [Azure 门户](https://docs.microsoft.com/zh-cn/azure/aks/learn/quick-kubernetes-deploy-portal)创建一个 AKS 集群。

对于 `az` cli 的选项，完成 `az login` 认证，或者使用 cloud shell 运行下面的命令。

1. 确定支持 AKS 的目标 region 名称。

    {{< text bash >}}
    $ az provider list --query "[?namespace=='Microsoft.ContainerService'].resourceTypes[] | [?resourceType=='managedClusters'].locations[]" -o tsv
    {{< /text >}}

1. 验证目标 region 所支持的 Kubernetes 版本。

    使用上一步中的目标 region 值替换 `my location`，然后执行：

    {{< text bash >}}
    $ az aks get-versions --location "my location" --query "orchestrators[].orchestratorVersion"
    {{< /text >}}

    {{< warning >}}
    在更新本文档之时，支持的 AKS Kubernetes 最低版本为 1.24.9
    {{< /warning >}}

1. 创建资源组并部署 AKS 集群。

    使用第 1 步中得到的 `mylocation` 名称替换 `myResourceGroup` 和 `myAKSCluster`；
    如果该 region 不支持 `Kubernetes 1.10.5`，则执行：

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.10.5 --generate-ssh-keys
    {{< /text >}}

1. 取得 AKS `kubeconfig` 证书。

    使用从之前步骤中获得的名称替换 `myResourceGroup` 和 `myAKSCluster` 后执行：

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}

## AKS-Engine

{{< warning >}}
针对 Azure 公有云客户的 AKS Engine 项目已被弃用。
对于托管的 Kubernetes，请考虑使用[附带 Istio 加载项的 Azure Kubernetes Service (AKS)](https://learn.microsoft.com/zh-cn/azure/aks/istio-about)；
对于自我管理的 Kubernetes，请考虑使用 [Cluster API Provider Azure](https://github.com/kubernetes-sigs/cluster-api-provider-azure)。
{{< /warning >}}

1. [跟随这些操作说明](https://github.com/Azure/aks-engine/blob/master/docs/tutorials/quickstart.md#install-aks-engine)来获取并安装 `aks-engine` 的二进制版本。

1. 下载支持部署 Istio 的 `aks-engine` API 模型定义：

    {{< text bash >}}
    $ wget https://raw.githubusercontent.com/Azure/aks-engine/master/examples/service-mesh/istio.json
    {{< /text >}}

    注意：可以使用其他将与 Istio 一起工作的 API 模型定义。默认情况下，
    `MutatingAdmissionWebhook` 和 `ValidatingAdmissionWebhook` 准入控制标识和 RBAC 会被启用。
    参阅 [aks-engine api 模型默认值](https://github.com/Azure/aks-engine/blob/master/docs/topics/clusterdefinitions.md)获取更多信息。

1. 使用 `istio.json` 模板来部署您的集群。
   您能在[官方文档](https://github.com/Azure/aks-engine/blob/master/docs/topics/creating_new_clusters.md#deploy)中找到有关参数的参考。

    | 参数                             | 期望值             |
    |---------------------------------------|----------------------------|
    | `subscription_id`                     | Azure 订阅 ID      |
    | `dns_prefix`                          | 集群 DNS 前缀         |
    | `location`                            | 集群位置           |

    {{< text bash >}}
    $ aks-engine deploy --subscription-id <subscription_id> \
      --dns-prefix <dns_prefix> --location <location> --auto-suffix \
      --api-model istio.json
    {{< /text >}}

    {{< tip >}}
    几分钟之后，您能在名为 `<dns_prefix>-<id>` 的 Azure subscription 的资源组中找到您的集群。
    假设 `dns_prefix` 有这样的值 `myclustername`，一个有效的资源组具有唯一集群 ID 为 `mycluster-5adfba82`。
    `aks-engine` 在 `_output` 文件夹中生成您的 `kubeconfig` 文件。
    {{< /tip >}}

1. 使用 `<dns_prefix>-<id>` 集群 ID，将 `kubeconfig` 从 `_output` 文件夹复制到您的机器：

    {{< text bash >}}
    $ cp \_output/<dns_prefix>-<id>/kubeconfig/kubeconfig.<location>.json \
     ~/.kube/config
    {{< /text >}}

    比如：

    {{< text bash >}}
    $ cp \_output/mycluster-5adfba82/kubeconfig/kubeconfig.westus2.json \
     ~/.kube/config
    {{< /text >}}
