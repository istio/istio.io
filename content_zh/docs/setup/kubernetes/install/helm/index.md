---
title: 使用 Helm 进行安装
description: 使用内含的 Helm chart 安装 Istio。
weight: 20
keywords: [kubernetes,helm]
icon: helm
---

使用 Helm 安装和配置 Istio 的快速入门说明。这种方式为 Istio 控制平面和 Sidecar 提供了丰富的配置，因此推荐用这种方式进行生产环境中的 Istio 部署。

## 先决条件

1. 完成必要的 [Kubernetes 平台设置](/zh/docs/setup/kubernetes/platform-setup/)
1. 检查对 [Pod 和服务的要求](/zh/docs/setup/kubernetes/additional-setup/requirements/)。
1. [安装高于 2.10 版本的 Helm 客户端](https://docs.helm.sh/using_helm)。
1. 默认情况下，Istio 使用 `LoadBalancer` 服务类型，而有些平台是不支持 `LoadBalancer` 服务的。对于缺少 `LoadBalancer` 支持的平台，执行下面的安装步骤时，可以在 Helm 命令中加入 `--set gateways.istio-ingressgateway.type=NodePort --set gateways.istio-egressgateway.type=NodePort` 选项，使用 `NodePort` 来替代 `LoadBalancer` 服务类型。

## 安装步骤

下面的命令可以在任何目录下运行。这里 Helm 用 https 方式从 Istio 提供的服务中下载 Chart。

{{< tip >}}
本文中提到的方法，使用的是 Istio 1.1 Helm 包的每日构建版本。在 Istio 完成 1.1 版本发布之前，这样获得的 Helm Chart 会比快照版本更早。要指定一个特定的快照版本，需要将仓库地址更换为特定的快照地址。例如想要运行 snapshot 6，步骤 1 中需要指定使用 [`1.1.0-snapshot.6` 的地址](https://gcsweb.istio.io/gcs/istio-prerelease/prerelease/1.1.0-snapshot.6/charts)。
{{< /tip >}}

1. 用 Helm 每日构建版本的地址来更新 Helm 的本地包缓存。

    {{< text bash >}}

    $ helm repo add istio.io "https://gcsweb.istio.io/gcs/istio-prerelease/daily-build/release-1.1-latest-daily/charts/"

    {{< /text >}}

1. 在下面的两个**互斥方案**中选择一个完成部署。

    - 要使用 Kubernetes 清单来部署 Istio，可以使用[方案 1](#方案-1-使用-helm-template-进行安装) 中的步骤。
    - 也可以用 [Helm Tiller pod](https://helm.sh/) 来对 Istio 进行管理，[方案 2](#方案-2-在-helm-和-tiller-的环境中使用-helm-install-命令进行安装) 中描述了这种方式。

    {{< tip >}}
    要对 Istio 及其组件进行定制，可以在 `helm template` 或者 `helm install` 命令中使用 `--set <key>=<value>` 参数来完成。[安装选项](/zh/docs/reference/config/installation-options/)中陈述了目前支持的键值对。

    {{< /tip >}}

### 方案 1：使用 `helm template` 进行安装

如果你的集群中没有运行 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components)，你也不想安装它。

1. 创建一个 Istio 的工作目录，用于下载 Chart：

    {{< text bash >}}

    $ mkdir -p $HOME/istio-fetch

    {{< /text >}}

1. 下载安装过程所需的 Helm 模板：

    {{< text bash >}}

    $ helm fetch istio.io/istio-init --untar --untardir $HOME/istio-fetch
    $ helm fetch istio.io/istio --untar --untardir $HOME/istio-fetch

    {{< /text >}}

1. 为 Istio 组件创建命名空间 `istio-system`：

    {{< text bash >}}

    $ kubectl create namespace istio-system

    {{< /text >}}

1. 使用 `kubectl apply` 安装所有的 Istio [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，命令执行之后，会隔一段时间才能被 Kubernetes API Server 收到：

    {{< text bash >}}

    $ helm template $HOME/istio-fetch/istio-init --name istio-init --namespace istio-system | kubectl apply -f -

    {{< /text >}}

1. 用下面的命令，来确认 Istio 的 `56` 个 CRD 都已经成功的提交给 Kubernetes API Server：

    {{< text bash >}}
    $ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
    56
    {{< /text >}}

1. 渲染和提交 Istio 的核心组件：

    {{< text bash >}}

    $ helm template $HOME/istio-fetch/istio --name istio --namespace istio-system | kubectl apply -f -

    {{< /text >}}

1. 删除步骤：

    {{< text bash >}}

    $ kubectl delete namespace istio-system

    {{< /text >}}

1. 如果需要，可以用下列命令删除所有的 CRD：

    {{< warning >}}
    CRD 的删除，意味着删掉所有的用户配置。
    {{< /warning >}}

    {{< text bash >}}

    $ kubectl delete -f $HOME/istio-fetch/istio-init/files

    {{< /text >}}

### 方案 2：在 Helm 和 Tiller 的环境中使用 `helm install` 命令进行安装

这个方案使用 Helm 和 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 来对 Istio 的生命周期进行管理。

1. 如果没有为 Tiller 创建 Service account，就创建一个：

    {{< text bash >}}

    $ kubectl apply -f @install/kubernetes/helm/helm-service-account.yaml@

    {{< /text >}}

1. 使用 Service account 在集群上安装 Tiller：

    {{< text bash >}}

    $ helm init --service-account tiller

    {{< /text >}}

1. 安装 `istio-init` chart，来启动 Istio CRD 的安装过程：

    {{< text bash >}}

    $ helm install istio.io/istio-init --name istio-init --namespace istio-system

    {{< /text >}}

1. 用下面的命令，来确认 Istio 的 `56` 个 CRD 都已经成功的提交给 Kubernetes API Server：

    {{< text bash >}}
    $ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
    56
    {{< /text >}}

1. 安装 `istio` Chart：

    {{< text bash >}}

    $ helm install istio --name istio --namespace istio-system

    {{< /text >}}

1. 删除步骤：

    {{< text bash >}}

    $ helm delete --purge istio
    $ helm delete --purge istio-init

    {{< /text >}}

## 删除 CRD 和 Istio 配置

{{< tip >}}
Istio 的设计中，其自定义资源以 CRD 的形式存在于 Kubernetes 环境之中。CRD 中包含了运维过程中产生的运行时配置。正因如此，我们建议运维人员应该显式的对其进行删除，从而避免意外操作。
{{< /tip >}}

{{< warning >}}
CRD 的删除，意味着删掉所有的用户配置。
{{< /warning >}}

{{< tip >}}
`istio-init` Chart 包含了 `istio-init/ifiles` 目录中的所有原始 CRD。下载该 Chart 之后，可以简单的使用 `kubectl` 删除 CRD。
{{< /tip >}}

1. 要永久删除 Istio 的 CRD 以及所有 Istio 配置：

    {{< text bash >}}

    $ mkdir -p $HOME/istio-fetch
    $ helm fetch istio.io/istio-init --untar --untardir $HOME/istio-fetch
    $ kubectl delete -f $HOME/istio-fetch/istio-init/files

    {{< /text >}}
