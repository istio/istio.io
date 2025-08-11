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
或者[自托管 Kubernetes 或 AKS 所用的 Azure 集群 API 提供程序（CAPZ）](https://capz.sigs.k8s.io/)部署一个 Kubernetes 集群到 Azure 上。

## AKS

您可以通过多种方式创建 AKS 群集，例如
[az cli](https://docs.microsoft.com/zh-cn/azure/aks/kubernetes-walkthrough)、
[Azure 门户](https://docs.microsoft.com/zh-cn/azure/aks/kubernetes-walkthrough-portal)、
[az cli with Bicep](https://learn.microsoft.com/zh-cn/azure/aks/learn/quick-kubernetes-deploy-bicep?tabs=azure-cli)
或 [Terraform](https://learn.microsoft.com/zh-cn/azure/aks/learn/quick-kubernetes-deploy-terraform?tabs=bash)。

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

1. 创建资源组并部署 AKS 集群。

    使用第 1 步中得到的 `mylocation` 名称替换 `myResourceGroup` 和 `myAKSCluster`；
    如果该 region 不支持 `Kubernetes 1.28.3`，则执行：

    {{< text bash >}}
    $ az group create --name myResourceGroup --location "my location"
    $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --kubernetes-version 1.28.3 --generate-ssh-keys
    {{< /text >}}

1. 取得 AKS `kubeconfig` 证书。

    使用从之前步骤中获得的名称替换 `myResourceGroup` 和 `myAKSCluster` 后执行：

    {{< text bash >}}
    $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
    {{< /text >}}

### 在 Azure 中使用 Gateway API {#using-gateway-api-with-azure}

如果您将 Gateway API 与 AKS 一起使用，则可能还需要将以下配置添加到 `Gateway` 资源：

{{< text yaml >}}
infrastructure:
  annotations:
    service.beta.kubernetes.io/port_<http[s] port>_health-probe_protocol: tcp
{{< /text >}}

其中，`<http[s] port>` 是 HTTP(S) 侦听器的端口号。如果您有多个 HTTP(S) 侦听器，
则需要为每个侦听器添加注解。当 `/` 路径未响应 200 时，此注解是 Azure 负载均衡器运行状况检查正常运行所必需的。

例如，如果您按照 [Ingress Gateway](/zh/docs/setup/getting-started)
示例使用 Gateway API，则需要部署以下 `Gateway`：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  infrastructure:
    annotations:
      service.beta.kubernetes.io/port_80_health-probe_protocol: tcp
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: "httpbin.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}
