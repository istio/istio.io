---
title: 使用 Helm 自定义安装
description: 安装和配置 Istio 以进行深入评估或用于生产。
weight: 20
keywords: [kubernetes,helm]
aliases:
    - /zh/docs/setup/kubernetes/helm.html
    - /zh/docs/tasks/integrating-services-into-istio.html
    - /zh/docs/setup/kubernetes/helm-install/
    - /zh/docs/setup/kubernetes/install/helm/
icon: helm
---

{{< warning >}}
Helm 的安装方法已被弃用。
请改用 [使用 {{< istioctl >}} 安装](/zh/docs/setup/install/istioctl/)。
{{< /warning >}}

请按照本指南安装和配置 Istio 网格，以进行深入评估或用于生产。

这种安装方式使用 [Helm](https://github.com/helm/helm) charts 自定义 Istio 控制平面和 Istio 数据平面的 sidecar。
你只需使用 `helm template` 生成配置并使用 `kubectl apply` 命令安装它, 或者你可以选择使用 `helm install` 让
[Tiller](https://helm.sh/docs/topics/architecture/#components)
 来完全管理安装。

通过这些说明, 您可以选择 Istio 内置的任何一个
[配置文件](/zh/docs/setup/additional-setup/config-profiles/)
并根据的特定的需求进行进一步的自定义配置。

## 先决条件

1. [下载 Istio 发行版](/zh/docs/setup/getting-started/#download)。
1. 完成必要的 [Kubernetes 平台设置](/zh/docs/setup/platform-setup/)。
1. 检查 [Pod 和服务的要求](/zh/docs/ops/deployment/requirements/)。
1. [安装高于 2.10 版本的 Helm 客户端](https://github.com/helm/helm#install)。

## 添加 Helm chart 仓库

本指南的以下命令使用了包含 Istio 发行版镜像的 Helm charts。
如果要使用 Istio 发行版 Helm chart ，建议使用下面的命令添加 Istio 发行版仓库：

{{< text bash >}}
$ helm repo add istio.io https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/charts/
{{< /text >}}

## 安装步骤

将目录切换到 Istio 发行版的根目录，然后在以下两个**互斥**选项选择一种安装：

1. 如果您不使用 Tiller 部署 Istio，请查看 [方案 1](/zh/docs/setup/install/helm/#option-1-install-with-helm-via-helm-template)。
1. 如果您使用 [Helm 的 Tiller pod](https://helm.sh/) 来管理 Istio 发行版, 请查看 [方案 2](/zh/docs/setup/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install)。

{{< tip >}}
默认情况下，Istio 使用 `LoadBalancer` 服务类型。 而有些平台是不支持 `LoadBalancer`
服务的。 对于不支持 `LoadBalancer` 服务类型的平台, 执行下面的步骤时，可以在 Helm 命令中加入 `--set gateways.istio-ingressgateway.type=NodePort` 选项，使用 `NodePort` 来替代 `LoadBalancer` 服务类型。
{{< /tip >}}

### 方案 1: 使用 `helm template` 命令安装{#option-1-install-with-helm-via-helm-template}

在您的集群没有按照 [Tiller](https://helm.sh/docs/topics/architecture/#components)
 而且您也不想安装它的情况下，选择此方案安装。

1. 为 Istio 组件创建命名空间 `istio-system`：

    {{< text bash >}}
    $ kubectl create namespace istio-system
    {{< /text >}}

1. 使用 `kubectl apply` 安装所有 Istio 的
    [自定义资源](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
    (CRDs) ：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. 选择一个 [配置文件](/zh/docs/setup/additional-setup/config-profiles/)
    接着部署与您选择的配置文件相对应的 Istio 核心组件。
    我们建议在生产环境使用**默认**的配置文件：

    {{< tip >}}
    您可以添加一个或多个 `--set <key>=<value>` 来进一步自定义 helm 命令的 [安装选项](/zh/docs/reference/config/installation-options/) 。
    {{< /tip >}}

{{< tabset category-name="helm_profile" >}}

{{< tab name="default" category-value="default" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< tab name="demo" category-value="demo" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-demo.yaml | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< tab name="minimal" category-value="minimal" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-minimal.yaml | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< tab name="sds" category-value="sds" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< tab name="Istio CNI enabled" category-value="cni" >}}

安装 [Istio CNI](/zh/docs/setup/additional-setup/cni/) 组件：

{{< text bash >}}
$ helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=kube-system | kubectl apply -f -
{{< /text >}}

将 `--set istio_cni.enabled=true` 设置追加到 helm 命令上，来启用 Istio CNI 插件。
以 Istio **默认**配置文件为例：

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --set istio_cni.enabled=true | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 方案 2: 在 Helm 和 Tiller 的环境中使用 `helm install` 命令安装{#option-2-install-with-helm-and-tiller-via-helm-install}

这个方案使用 Helm 和 [Tiller](https://helm.sh/docs/topics/architecture/#components) 来对 Istio 的生命周期进行管理。

{{< boilerplate helm-security-warning >}}

1. 请确保您的集群的 Tiller 设置了 `cluster-admin` 角色的 Service Account。
   如果还没有定义，请执行下面命令创建：

    {{< text bash >}}
    $ kubectl apply -f @install/kubernetes/helm/helm-service-account.yaml@
    {{< /text >}}

1. 使用 Service Account 在集群上安装 Tiller：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 安装 `istio-init` chart，来启动 Istio CRD 的安装过程：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. 选择一个 [配置文件](/zh/docs/setup/additional-setup/config-profiles/)
    接着部署与您选择的配置文件相对应的 `istio` 的核心组件。
    我们建议在生成环境部署中使用**默认**配置文件:

    {{< tip >}}
    您可以添加一个或多个 `--set <key>=<value>` 来进一步定义 Helm 命令的
    [安装选项](/zh/docs/reference/config/installation-options/)。
    {{< /tip >}}

{{< tabset category-name="helm_profile" >}}

{{< tab name="default" category-value="default" >}}

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="demo" category-value="demo" >}}

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-demo.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="minimal" category-value="minimal" >}}

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-minimal.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="sds" category-value="sds" >}}

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="Istio CNI enabled" category-value="cni" >}}

安装 [Istio CNI](/zh/docs/setup/additional-setup/cni/) chart：

{{< text bash >}}
$ helm install install/kubernetes/helm/istio-cni --name istio-cni --namespace kube-system
{{< /text >}}

将 `--set istio_cni.enabled=true` 设置追加到 helm 命令上，来启用 Istio CNI 插件。
以 Istio **默认**配置文件为例：

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set istio_cni.enabled=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 验证安装

1. 查询 [配置文件](/zh/docs/setup/additional-setup/config-profiles/) 的组件表，验证是否已部署了与您选择的配置文件相对应的 Kubernetes 服务

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    {{< /text >}}

1. 确保相应的 Kubernetes Pod 已部署并且 `STATUS` 是 `Running`：

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    {{< /text >}}

## 卸载

- 如果你使用 `helm template` 命令安装的 Istio，使用如下命令卸载：

{{< tabset category-name="helm_profile" >}}

{{< tab name="default" category-value="default" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl delete -f -
$ kubectl delete namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="demo" category-value="demo" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-demo.yaml | kubectl delete -f -
$ kubectl delete namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="minimal" category-value="minimal" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-minimal.yaml | kubectl delete -f -
$ kubectl delete namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="sds" category-value="sds" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml | kubectl delete -f -
$ kubectl delete namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="Istio CNI enabled" category-value="cni" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --set istio_cni.enabled=true | kubectl delete -f -
{{< /text >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=kube-system | kubectl delete -f -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

- 如果您使用的Helm 和 Tiller 安装的 Istio,使用如下命令卸载：

    {{< text bash >}}
    $ helm delete --purge istio
    $ helm delete --purge istio-init
    $ helm delete --purge istio-cni
    $ kubectl delete namespace istio-system
    {{< /text >}}

## 删除 CRD 和 Istio 配置

Istio 的设计中，其自定义资源以 CRD 的形式存在于 Kubernetes 环境之中。CRD 中包含了运维过程中产生的运行时配置。正因如此，我们建议运维人员应该显式的对其进行删除，从而避免意外操作。

{{< warning >}}
CRD 的删除，意味着删掉所有的用户配置。
{{< /warning >}}

`istio-init` Chart 包含了 `istio-init/files` 目录中的所有原始 CRD。下载该 Chart 之后，可以简单的使用 `kubectl` 删除 CRD。要永久删除 Istio 的 CRD 以及所有 Istio 配置,请运行如下命令

{{< text bash >}}
$ kubectl delete -f install/kubernetes/helm/istio-init/files
{{< /text >}}