---
title: Istio 最小化安装
description: 使用 Helm 最小化安装 Istio 。
weight: 30
keywords: [kubernetes,helm,minimal]
icon: helm
---

使用 Helm 最小化安装和配置 Istio 的快速入门指南。

此最小安装提供了 Istio 的流量管理功能。

## 前置条件

请参考快速入门指南中描述的[前置条件](/zh/docs/setup/kubernetes/install/kubernetes/#前置条件)。

## 安装步骤

您可以使用两种互斥的选项来安装Istio：
- 如要使用 Kubernetes 清单文件来安装 Istio，请按照[选项 #1](#option-1) 的说明进行操作。
- 如要使用 [Helm 的 Tiller pod](https://helm.sh/) 来管理 Istio 发布，请按照 [选项 #2](#option-2) 的说明进行操作。

### 选项 1：通过 Helm 命令 `helm template` 安装 {#option-1}

如您的集群中没有部署 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 并且您也不打算安装它时，请使用此选项。

1. 通过 `kubectl apply` 安装所有的 Istio [自定义资源定义（CRD）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，等待几秒钟以便 CRD 被提交到 Kube api-server：

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. 将 Istio 核心组件渲染到一个名为 `istio-minimal.yaml` 的 Kubernetes 清单文件中：

    {{< text bash >}}
    $ cat @install/kubernetes/namespace.yaml@ > $HOME/istio-minimal.yaml
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --values install/kubernetes/helm/istio/values-istio-minimal.yaml >> $HOME/istio-minimal.yaml
    {{< /text >}}

1. 使用该清单文件安装 Pilot 组件：

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-minimal.yaml
    {{< /text >}}

### 选项 2：通过 `helm install` 命令安装 Helm 和 Tiller {#option-2}

本选项允许您使用 Helm 和 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 管理 Istio 的生命周期。

1. 如果还没有为 Tiller 设置 service account，请先创建一个：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1. 使用已安装的 service account 将 Tiller 安装到您的集群：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 安装 `istio-init` chart 以引导所有的 Istio CRD：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
    {{< /text >}}

1. 使用下列命令，验证全部 `58` 个 Istio CRD 均已被提交到 Kubernetes api-server：

    {{< text bash >}}
    $ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
    58
    {{< /text >}}

1. 安装 `istio` chart：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio --name istio-minimal --namespace istio-system \
      --values install/kubernetes/helm/istio/values-istio-minimal.yaml
    {{< /text >}}

1. 确保 `istio-pilot-*` 的 pod 已经被部署并且其容器已经拉起并运行：

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-pilot-58c65f74bc-2f5xn             1/1       Running   0          1m
{{< /text >}}

## 卸载

- 对于选项 1，使用 `kubectl` 卸载：

    {{< text bash >}}
    $ kubectl delete -f $HOME/istio-minimal.yaml
    {{< /text >}}

- 对于选项 2，使用 Helm 卸载：

    {{< warning >}}
    Uninstalling this chart does not delete Istio's registered CRDs. Istio, by design, expects
    CRDs to leak into the Kubernetes environment. As CRDs contain all the runtime configuration
    data needed to configure Istio. Because of this, we consider it better for operators to
    explicitly delete the runtime configuration data rather than unexpectedly lose it.
    {{< /warning >}}

    {{< text bash >}}
    $ helm delete --purge istio-minimal
    $ helm delete --purge istio-init
    {{< /text >}}

- 如果需要，请运行下列命令删除所有 CRD：

    {{< warning >}}
    Deleting CRDs deletes any configuration changes that you have made to Istio.
    {{< /warning >}}

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete -f $i; done
    {{< /text >}}