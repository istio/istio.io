---
title: Azure
description: 对 Azure 集群进行配置以便安装运行 Istio。
weight: 9
skip_seealso: true
keywords: [platform-setup,azure]
---

依照本指南对 Azure 集群进行配置以便安装运行 Istio。

可以使用 [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) 或者 [ACS-Engine](https://github.com/azure/acs-engine) 部署 Kubernetes 集群，两种方式都完全能够支持 Istio 的安装和运行。

## AKS

[az 客户端工具](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough) 或者 [Azure 门户](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal) 都能被用来创建 AKS 集群。

如果使用 `az` 客户端工具，首先要完成 `az login` 认证过程，或者直接使用 Cloud shell；然后运行下面的命令：

1. 选择支持 AKS 的区域进行后续安装过程

    {{< text bash >}}
    $ az provider list --query "[?namespace=='Microsoft.ContainerService'].resourceTypes[] | [?resourceType=='managedClusters'].locations[]" -o tsv
    {{< /text >}}

1. 查询该区域所支持的 Kubernetes 版本

    用上面选择的区域替换 `my location`，执行命令：

    {{< text bash >}}
    $ az aks get-versions --location "my location" --query "orchestrators[].orchestratorVersion"
    {{< /text >}}

    这里需要看到 `1.10.5` 出现在列表之中，或者选择一个大于或等于 `1.9.6` 的其它版本。

1. 创建资源组，然后部署 AKS 集群

    用真实名称替换  `myResourceGroup` 和 `myAKSCluster`，`my location` 则使用步骤 1 中确定的区域，如果区域支持的话，选择 `1.10.5` 版本，运行命令：

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.10.5 --generate-ssh-keys
    {{< /text >}}

1. 获取 AKS 的 `kubeconfig` 和凭据

    用前面选择的名称替换  `myResourceGroup` 和 `myAKSCluster` 然后执行：

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}

## ACS-Engine

1. 按照下面的[介绍](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md#install)，下载和安装 `acs-engine` 的二进制包。

1. 下载支持 Istio 的 `acs-engine` API 模型定义文件：

    {{< text bash >}}
    $ wget https://raw.githubusercontent.com/Azure/acs-engine/master/examples/service-mesh/istio.json
    {{< /text >}}

    注意：使用其他的 API 模型定义也是可以支持 Istio 的。MutatingAdmissionWebhook 以及 ValidatingAdmissionWebhook 两个准入控制标志以及 RBAC 在 1.9 或更新版本的集群中都是缺省开启的。请参看 [acs-engine API 模型的缺省值](https://github.com/Azure/acs-engine/blob/master/docs/clusterdefinition.md)获取更多相关信息。

1. 使用 `istio.json` 模板定义集群。其中的参数可以在[官方文档](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/deploy.md#step-3-edit-your-cluster-definition)中找到。

    | 参数                                   | 说明               |
    |---------------------------------------|---------------------------|
    | `subscription_id`                     | Azure 订阅 ID|
    | `dns_prefix`                          | 集群 DNS 前缀         |
    | `location`                            | 集群位置           |

    {{< text bash >}}
    $ acs-engine deploy --subscription-id <subscription_id> \
      --dns-prefix <dns_prefix> --location <location> --auto-suffix \
      --api-model istio.json
    {{< /text >}}

    {{< tip >}}
    几分钟之后，就可以在 Azure 订阅中发现一个资源组，命名方式是 `<dns_prefix>-<id>`。假设 `dns-prefix` 取值为 `myclustername`，会在后面加入一个随机 ID 后缀，生成资源组名，例如 `mycluster-5adfba82`。`acs-engine` 会生成 `kubeconfig` 文件，放置到 `_output` 文件夹中。
    {{< /tip >}}

1. 使用 `<dns_prefix>-<id>` 集群 ID，把 `kubeconfig` 从 `_output` 文件夹中复制出来：

    {{< text bash >}}
    $ cp _output/<dns_prefix>-<id>/kubeconfig/kubeconfig.<location>.json \
        ~/.kube/config
    {{< /text >}}

    例如：

    {{< text bash >}}
    $ cp _output/mycluster-5adfba82/kubeconfig/kubeconfig.westus2.json \
      ~/.kube/config
    {{< /text >}}
