---
title: 使用 Helm 进行安装
description: 使用内含的 Helm chart 安装 Istio。
weight: 30
keywords: [kubernetes,helm]
icon: /img/helm.svg
---

使用 Helm 安装和配置 Istio 的快速入门说明。
这是将 Istio 安装到您的生产环境的推荐安装方式，因为它为 Istio 控制平面和数据平面 sidecar 提供了丰富的配置。

## 先决条件

1. [下载 Istio 的发布版本](/zh/docs/setup/kubernetes/download-release/)。
1. [在 Kubernetes 中安装 Istio](/zh/docs/setup/kubernetes/platform-setup/)

## 安装步骤

要安装 Istio 的核心组件，您可以选择以下四个互斥选项之一。

但是，我们建议您在生产环境使用 [Helm Chart](/zh/docs/setup/kubernetes/helm-install/) 安装 Istio。通过此安装，您可以利用所有选项来根据需要配置和自定义 Istio。

## 选项1：通过 Helm 的 `helm template` 安装 Istio

1. 将 Istio 的核心组件呈现为名为 `istio.yaml` 的 Kubernetes 清单文件：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
    {{< /text >}}

1. 通过清单文件安装组件

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create -f $HOME/istio.yaml
    {{< /text >}}

## 选项2：通过 Helm 和 Tiller 的 `helm install` 安装 Istio

此选项允许 Helm 和 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 管理 Istio 的生命周期。

{{< warning_icon >}} 使用 Helm 升级 Istio 还没有进行全面的测试。

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

## 自定义示例：流量管理最小集

Istio 配备了一组丰富而强大的功能，但你可能只需要这些功能的一部分。例如，用户可能只对安装 Istio 的流量管理所需的最小集合感兴趣。

这个示例展示了如何安装使用[流量管理](/zh/docs/tasks/traffic-management/)功能所需的最小组件集和。

执行以下命令来安装 Pilot 和 Citadel：

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=false \
  --set gateways.istio-ingressgateway.enabled=false \
  --set gateways.istio-egressgateway.enabled=false \
  --set galley.enabled=false \
  --set sidecarInjectorWebhook.enabled=false \
  --set mixer.enabled=false \
  --set prometheus.enabled=false \
  --set global.proxy.envoyStatsd.enabled=false
{{< /text >}}

请确保 `istio-pilot-*` 和 `istio-citadel-*` 的 Kubernetes pod 已经部署，并且他们的容器已经启动并运行：

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-citadel-b48446f79-wd4tk            1/1       Running   0          1m
istio-pilot-58c65f74bc-2f5xn             2/2       Running   0          1m
{{< /text >}}

在这个最小集合之下，您安装您自己的应用并为实例[配置请求路由](/zh/docs/tasks/traffic-management/request-routing/)。
您需要[手动注入 sidecar](/zh/docs/setup/kubernetes/sidecar-injection/#手工注入-sidecar)。

[安装选项](/docs/reference/config/installation-options/) 中有选项的完整列表，可以让您根据自己的需要对 Istio 安装进行裁剪。

## 卸载

* 对于选项1，使用 `kubectl` 进行卸载：

    {{< text bash >}}
    $ kubectl delete -f $HOME/istio.yaml
    {{< /text >}}

* 对于选项2，使用 Helm 进行卸载：

    {{< text bash >}}
    $ helm delete --purge istio
    {{< /text >}}

    如果您的 Helm 版本低于 2.9.0，那么在重新部署新版 Istio chart 之前，您需要手动清理额外的 job 资源：

    {{< text bash >}}
    $ kubectl -n istio-system delete job --all
    {{< /text >}}
