---
title: Istio 最小化安装
description: 使用 Helm 最小化安装 Istio 。
weight: 30
keywords: [kubernetes,helm, minimal]
icon: helm
---

按照此路径使用 Helm 执行最小安装和配置 Istio 网格。

此最小安装提供了 Istio 的流量管理功能。

## 前置条件

请参考快速入门指南中描述的[前置条件](/zh/docs/setup/kubernetes/install/kubernetes/#前置条件)。

## 安装步骤

您有两个互斥的选项来安装 Istio：
- 要使用Kubernetes清单来部署Istio，请按照[选项＃1](#option-1)的说明进行操作。
- 要使用 [Helm's Tiller pod](https://helm.sh/) 管理您的 Istio 版本，请按照[选项＃2](#option-2) 的说明进行操作。

### 选项 1：通过 Helm 命令 `helm template` 安装{#option-1}

1. 通过 `kubectl apply` 安装所有 Istio 的[自定义资源定义或简称 CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，然后在 Kube api-server 中提交 CRD 后等待几秒钟：

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. 将 Istio 的核心组件渲染为名为 `istio-minimal.yaml` 的 Kubernetes 清单：

    {{< text bash >}}
    $ cat @install/kubernetes/namespace.yaml@ > $HOME/istio-minimal.yaml
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --values install/kubernetes/helm/istio/values-istio-minimal.yaml >> $HOME/istio-minimal.yaml
    {{< /text >}}

1. 通过清单安装 Pilot 组件：

    {{< text bash >}}
    $ kubectl apply -f $HOME/istio-minimal.yaml
    {{< /text >}}

### 选项 2：通过 `helm install` 命令安装 Helm 和 Tiller{#option-2}

本选项允许 Helm 和 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 管理 Istio 的生命周期。

1. 如果还没有为 Tiller 安装 service account，请安装一个：

    {{< text bash >}}
    $ kubectl apply -f @install/kubernetes/helm/helm-service-account.yaml@
    {{< /text >}}

1. 使用已安装的 service account 将 Tiller 安装到你的集群：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 安装 `istio-init` 图表来引导所有 Istio 的 CRD：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio-init --name istio-init --namespace istio-system
    {{< /text >}}

1. 使用以下命令验证所有 `56` 个 Istio CRD 是否已提交到 Kubernetes api-server：

    {{< text bash >}}
    $ kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
    56
    {{< /text >}}

1. 安装 `istio` 图表：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio --name istio-minimal --namespace istio-system \
      --values install/kubernetes/helm/istio/values-istio-minimal.yaml
    {{< /text >}}

1. 确保已经部署 `istio-pilot-*` Kubernetes pod，并且容器已经正常运行：

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-pilot-58c65f74bc-2f5xn             1/1       Running   0          1m
{{< /text >}}

## 卸载

* 对于选项 1，使用 `kubectl` 卸载：

    {{< text bash >}}
    $ kubectl delete -f $HOME/istio-minimal.yaml
    {{< /text >}}

* 对于选项 2，使用 Helm 卸载：

    {{< warning >}}
    卸载此 chart 不会删除 Istio 已注册的 CRD。根据设计，Istio 预计 CRD 会泄漏到 Kubernetes 环境中。
    由于 CRD 包含配置 Istio 所需的所有运行时配置数据。因此，
    我们认为运维人员会更好地明确删除运行时配置数据而不是是它意外丢失。
    {{< /warning >}}

    {{< text bash >}}
    $ helm delete --purge istio-minimal
    $ helm delete --purge istio-init
    {{< /text >}}

* 如果需要，请运行以下命令以删除所有 CRD：

    {{< warning >}}
    删除 CRD 会删除您对 Istio 所做的任何配置更改。
    {{< /warning >}}

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete -f $i; done
    {{< /text >}}
