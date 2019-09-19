---
title: 使用 Helm 进行安装
description: 使用内含的 Helm chart 安装 Istio。
weight: 20
keywords: [kubernetes,helm]
icon: helm
---

按照此流程安装和配置 Istio 网格，用于深入评估或生产环境使用。
这种安装方式使用 [Helm](https://github.com/helm/helm) chart 自定义 Istio 控制平面和 Istio 数据平面的 sidecar 。
你只需使用 `helm template` 生成配置并使用 `kubectl apply` 安装它，或者你可以选择使用 `helm install` 让 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 来完全管理安装。

通过这些说明，你可以选择 Istio 内置的任何一个[配置文件](/zh/docs/setup/kubernetes/additional-setup/config-profiles/)并根据你特定的需求进行进一步的自定义配置。

## 先决条件

1. [下载 Istio 发行版](/zh/docs/setup/kubernetes/download/).
1. 完成必要的 [Kubernetes 平台设置](/zh/docs/setup/kubernetes/prepare/platform-setup/)
1. 检查对 [Pod 和服务的要求](/zh/docs/setup/kubernetes/additional-setup/requirements/)。
1. [安装高于 2.10 版本的 Helm 客户端](https://docs.helm.sh/using_helm)。

{{< tip >}}
这些说明假定你将 `istio-init` 容器用于设置 `iptables` ，并将网络流量重定向到 Envoy sidecars。
如果你在自定义配置中使用了 `--set istio_cni.enabled=true` 参数, 你还需要确保你部署了 CNI 插件。更多详情，请参阅 [CNI 设置](/zh/docs/setup/kubernetes/additional-setup/cni/)。
{{< /tip >}}

## 安装步骤

以下命令使用了包含 Istio 发行版镜像的 Helm charts。
将目录更改为 Istio 发行版的根目录然后在以下两个**互斥**选项选择一种进行安装：

1. 如果你不使用 Tiller 部署 Istio, 请查看 [方案 1](/zh/docs/setup/kubernetes/install/helm/#方案-1-使用-helm-template-进行安装)。
1. 如果你使用 [Helm 的 Tiller pod](https://helm.sh/) 来管理你的 Istio 发行版,请查看[方案 2](/zh/docs/setup/kubernetes/install/helm/#方案-2-在-helm-和-tiller-的环境中使用-helm-install-命令进行安装)。

{{< tip >}}
默认情况下，Istio 使用 `LoadBalancer` 服务类型，而有些平台是不支持 `LoadBalancer` 服务的。对于缺少 `LoadBalancer` 支持的平台，执行下面的安装步骤时，可以在 Helm 命令中加入 `--set gateways.istio-ingressgateway.type=NodePort` 选项，使用 `NodePort` 来替代 `LoadBalancer` 服务类型。
{{< /tip >}}

### 方案 1：使用 `helm template` 进行安装

如果你的集群中没有运行 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components)，你也不想安装它。

1. 为 Istio 组件创建命名空间 `istio-system`：

    {{< text bash >}}
    $ kubectl create namespace istio-system
    {{< /text >}}

1. 使用 `kubectl apply` 安装所有的 Istio [CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，命令执行之后，会隔一段时间才能被 Kubernetes API Server 收到：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. 选择一个 [配置文件](/docs/setup/additional-setup/config-profiles/)，接着部署与你选择的配置文件相对应的 Istio 的核心组件，我们建议在生成环境部署中使用 **default** 配置文件:

    {{< tip >}}
    你可以添加一个或多个 `--set <key>=<value>` 来进一步自定义 helm 命令的
    [安装选项](/zh/docs/reference/config/installation-options/) 。
    {{< /tip >}}

{{< tabset cookie-name="helm_profile" >}}

{{< tab name="default" cookie-value="default" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< tab name="demo" cookie-value="demo" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-demo.yaml | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< tab name="minimal" cookie-value="minimal" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-minimal.yaml | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< tab name="sds" cookie-value="sds" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml | kubectl apply -f -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

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
    $ helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. 选择一个 [配置文件](/docs/setup/additional-setup/config-profiles/)，接着部署与你选择的配置文件相对应的 Istio 的核心组件，我们建议在生成环境部署中使用 **default** 配置文件:

    {{< tip >}}
    你可以添加一个或多个 `--set <key>=<value>` 来进一步自定义 helm 命令的
    [安装选项](/zh/docs/reference/config/installation-options/) 。
    {{< /tip >}}

{{< tabset cookie-name="helm_profile" >}}

{{< tab name="default" cookie-value="default" >}}

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="demo" cookie-value="demo" >}}

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-demo.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="minimal" cookie-value="minimal" >}}

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-minimal.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="sds" cookie-value="sds" >}}

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 确认安装情况

1. 查询[配置文件](/zh/docs/setup/kubernetes/additional-setup/config-profiles/)中的组件表,
    验证 Helm 是否已经部署了与所选配置文件相对应的 Kubernetes services 服务：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    {{< /text >}}

1. 确保部署了相应的 Kubernetes pod 并且 `STATUS` 是 `Running`的:

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    {{< /text >}}

## 卸载

* 如果你使用 `helm template` 命令安装的 Istio，使用如下命令卸载 :

{{< tabset cookie-name="helm_profile" >}}

{{< tab name="default" cookie-value="default" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl delete -f -
$ kubectl delete namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="demo" cookie-value="demo" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-demo.yaml | kubectl delete -f -
$ kubectl delete namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="minimal" cookie-value="minimal" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-minimal.yaml | kubectl delete -f -
$ kubectl delete namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< tab name="sds" cookie-value="sds" >}}

{{< text bash >}}
$ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-sds-auth.yaml | kubectl delete -f -
$ kubectl delete namespace istio-system
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* 如果你使用的Helm 和 Tiller 安装的 Istio,使用如下命令卸载:

    {{< text bash >}}
    $ helm delete --purge istio
    $ helm delete --purge istio-init
    {{< /text >}}

## 删除 CRD 和 Istio 配置

Istio 的设计中，其自定义资源以 CRD 的形式存在于 Kubernetes 环境之中。CRD 中包含了运维过程中产生的运行时配置。正因如此，我们建议运维人员应该显式的对其进行删除，从而避免意外操作。

{{< warning >}}
CRD 的删除，意味着删掉所有的用户配置。
{{< /warning >}}

`istio-init` Chart 包含了 `istio-init/ifiles` 目录中的所有原始 CRD。下载该 Chart 之后，可以简单的使用 `kubectl` 删除 CRD。要永久删除 Istio 的 CRD 以及所有 Istio 配置,请运行如下命令：

{{< text bash >}}
$ kubectl delete -f install/kubernetes/helm/istio-init/files
{{< /text >}}
