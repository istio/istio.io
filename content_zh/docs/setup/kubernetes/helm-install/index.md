---
title: 使用 Helm 进行安装
description: 使用内含的 Helm chart 安装 Istio。
weight: 30
keywords: [kubernetes,helm]
icon: /img/helm.svg
---

使用 Helm 安装和配置 Istio 的快速入门说明。
这种方式为 Istio 控制平面和 Sidecar 提供了丰富的配置，因此推荐用这种方式进行生产环境中的 Istio 部署。

## 先决条件

1. [下载 Istio 的发布版本](/zh/docs/setup/kubernetes/download-release/)。

1. [Kubernetes 平台设置](/zh/docs/setup/kubernetes/platform-setup/):
  * [Minikube](/zh/docs/setup/kubernetes/platform-setup/minikube/)
  * [Google Container Engine (GKE)](/zh/docs/setup/kubernetes/platform-setup/gke/)
  * [IBM Cloud Kubernetes Service (IKS)](/zh/docs/setup/kubernetes/platform-setup/ibm/)
  * [OpenShift Origin](/docs/setup/kubernetes/platform-setup/openshift/)
  * [Amazon Web Services (AWS) with Kops](/zh/docs/setup/kubernetes/platform-setup/aws/)
  * [Azure](/zh/docs/setup/kubernetes/platform-setup/azure/)

1. 检查对 [Pod 和服务的要求](/zh/docs/setup/kubernetes/spec-requirements/)。

1. [安装 Helm 客户端](https://docs.helm.sh/using_helm/).

1. 默认情况下，Istio 使用 `LoadBalancer` 服务类型，但是有些平台不支持 `LoadBalancer` 服务类型。
   对于这些不支持 `LoadBalancer` 的平台，在安装 Istio 需要在 Helm 命令结尾处中加入 `--set gateways.istio-ingressgateway.type=NodePort --set gateways.istio-egressgateway.type=NodePort`选项，使用 `NodePort` 以代替 `LoadBalancer`。

## 安装步骤

1. 如果您使用的 Helm 版本低于 2.10.0,那么您需要通过 `kubectl apply` 命令安装 Istio 的 [自定义资源定义（CRD）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，并且等待几秒钟让 CRD 被提交到 kube-apiserver:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

    > 如果你开启了 `certmanager`，你也需要安装它的 CRD 并等待其被提交到 kube-apiserver:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/charts/certmanager/templates/crds.yaml
    {{< /text >}}

1. 在下面的两个 **互斥方案** 中选择一个完成部署。

## 选项1：通过 Helm 的 `helm template` 安装 Istio

1. 将 Istio 的核心组件呈现为名为 `istio.yaml` 的 Kubernetes 清单文件：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
    {{< /text >}}

1. 通过清单文件安装组件

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl apply -f $HOME/istio.yaml
    {{< /text >}}

## 选项2：通过 Helm 和 Tiller 的 `helm install` 安装 Istio

此选项允许 Helm 和 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 管理 Istio 的生命周期。


1. 如果还没有为 Tiller 配置 service account，请配置一个：

    {{< text bash >}}
    $ kubectl create -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1. 使用 service account 在您的集群中安装 Tiller：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 安装 Istio：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio --name istio --namespace istio-system
    {{< /text >}}

## 卸载

* 对于选项 1，使用 `kubectl` 进行卸载：

    {{< text bash >}}
    $ kubectl delete -f $HOME/istio.yaml
    {{< /text >}}

* 对于选项 2，使用 Helm 进行卸载：

    {{< text bash >}}
    $ helm delete --purge istio
    {{< /text >}}

    如果您的 Helm 版本低于 2.9.0，那么在重新部署新版 Istio chart 之前，您需要手动清理额外的 job 资源：

    {{< text bash >}}
    $ kubectl -n istio-system delete job --all
    {{< /text >}}

* 如有需要，删除 CRD:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
    {{< /text >}}
