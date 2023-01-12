---
title: Kubernetes Gardener 快速开始
description: 使用 Gardener 快速搭建 Istio 服务。
weight: 35
aliases:
    - /zh/docs/setup/kubernetes/platform-setup/gardener/
skip_seealso: true
keywords: [platform-setup,kubernetes,gardener,sap]
owner: istio/wg-environments-maintainers
test: no
---

## Gardener 引导 {#bootstrapping-gardener}

若要搭建自己的 [Gardener](https://gardener.cloud) 满足您所在组织的 Kubernetes 服务需求，可以查看
[文档](https://github.com/gardener/gardener/blob/master/docs/README.md)。
有关测试用途，也可以通过调用源代码仓库并执行 `make kind-up gardener-up`（这是开发时调用 Gardener 最简单的方式）
[在您的笔记本上搭建 Gardener](https://github.com/gardener/gardener/blob/master/docs/development/getting_started_locally.md)。

另外，[`23 Technologies GmbH`](https://23technologies.cloud/) 提供了完全托管的 Gardener 服务，
能够很方便地处理所有支持的云提供商，附带免费试用机会：[`Okeanos`](https://okeanos.dev/)。
类似的，[`STACKIT`](https://stackit.de/)、[`B'Nerd`](https://bnerd.com/)、[`MetalStack`](https://metalstack.cloud/)
和许多其他云提供商可以将 Gardener 用作他们的 Kubernetes 引擎。

要了解有关开源项目的更多信息，请阅读 [`kubernetes.io`](https://kubernetes.io/zh-cn/blog) 上的
[Gardener 项目更新](https://kubernetes.io/blog/2019/12/02/gardener-project-update/)和
[Gardener - Kubernetes 植物学家](https://kubernetes.io/blog/2018/05/17/gardener/)。

[快速使用 Istio、自定义域和证书培育自己的 Gardener](https://gardener.cloud/docs/extensions/others/gardener-extension-shoot-cert-service/docs/tutorial-custom-domain-with-istio/)
是针对 Gardener 最终用户的详细教程。

### 安装并且配置 `kubectl`{#install-and-configure-Kubernetes}

1. 如果您已经有 `kubectl` CLI，请运行 `kubectl version --short` 来检查版本。
    您需要一个至少与要订购的 Kubernetes 集群版本匹配的当前版本。
    如果您的 `kubectl` 版本较旧，请按照下一步安装新版本。

1. [安装 `kubectl` CLI](https://kubernetes.io/zh-cn/docs/tasks/tools/)。

### 访问 Gardener{#access-gardener}

1. 在 Gardener 仪表板中创建一个项目。这实际上将创建一个名为 `garden-<my-project>` 的 Kubernetes 命名空间。

1. [配置 Gardener 项目的访问权限](https://gardener.cloud/docs/dashboard/usage/gardener-api/)使用 kubeconfig。

    {{< tip >}}
    如果您打算使用 Gardener 仪表板和嵌入式网络终端创建集群并与之交互，则可以跳过这一步；只有编程访问才需要这一步。
    {{< /tip >}}

    如果您还不是 Gardener 管理员，则可以在 Gardener 仪表板中创建一个技术用户：
    转到 "Members" 部分并添加服务帐户。然后，您可以为您的项目下载 kubeconfig。
    确保在您的 Shell 中设置 `export KUBECONFIG=garden-my-project.yaml`。

    ![Download kubeconfig for Gardener](https://raw.githubusercontent.com/gardener/dashboard/master/docs/images/01-add-service-account.png "downloading the kubeconfig using a service account")

### 创建 Kubernetes 集群{#creating-a-Kubernetes-cluster}

您可以通过提供集群规范 yaml 文件，使用 `kubectl` CLI 创建集群。
您可以在[这里](https://github.com/gardener/gardener/blob/master/example/90-shoot.yaml)找到关于 GCP 的示例。
确保命名空间与您的项目命名空间匹配。然后只需将准备好的 "shoot" 集群清单与 `kubectl` 配合使用：

{{< text bash >}}
$ kubectl apply --filename my-cluster.yaml
{{< /text >}}

更简单的替代方法是按照 Gardener 仪表板中的集群创建向导来创建集群：

![shoot creation](https://raw.githubusercontent.com/gardener/dashboard/master/docs/images/dashboard-demo.gif "shoot creation via the dashboard")

### 为集群配置 `kubectl`{#configure-Kubernetes-for-your-cluster}

现在，您可以在 Gardener 仪表板中或通过 CLI 为新创建的集群下载 kubeconfig，如下所示：

{{< text bash >}}
$ kubectl --namespace shoot--my-project--my-cluster get secret kubecfg --output jsonpath={.data.kubeconfig} | base64 --decode > my-cluster.yaml
{{< /text >}}

此 kubeconfig 文件能让管理员对集群具有完全访问权限。
对于负载集群的任何活动，请确保已设置 `export KUBECONFIG=my-cluster.yaml`。

## 删除{#cleaning-up}

使用 Gardener 仪表板删除集群，或者使用指向您的 `garden-my-project.yaml` kubeconfig 的 `kubectl` 执行以下操作：

{{< text bash >}}
$ kubectl --kubeconfig garden-my-project.yaml --namespace garden--my-project annotate shoot my-cluster confirmation.garden.sapcloud.io/deletion=true
$ kubectl --kubeconfig garden-my-project.yaml --namespace garden--my-project delete shoot my-cluster
{{< /text >}}
