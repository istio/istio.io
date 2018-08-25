---
title: 使用 Helm 进行安装
description: 使用内含的 Helm chart 安装 Istio。
weight: 30
keywords: [kubernetes,helm]
aliases:
    - /zh/docs/setup/kubernetes/helm.html
    - /zh/docs/tasks/integrating-services-into-istio.html
icon: /img/helm.svg
---

使用 Helm 安装和配置 Istio 的快速入门说明。
这是将 Istio 安装到您的生产环境的推荐安装方式，因为它为 Istio 控制平面和数据平面 sidecar 提供了丰富的配置。

## 先决条件

1. [下载 Istio 的发布版本](/zh/docs/setup/kubernetes/download-release/)。
1. [Kubernetes 平台设置](/zh/docs/setup/kubernetes/platform-setup/)

* [Minikube](/zh/docs/setup/kubernetes/platform-setup/minikube/)
* [Google 容器引擎 (GKE)](/zh/docs/setup/kubernetes/platform-setup/gke/)
* [IBM 云 Kubernetes 服务 (IKS)](/zh/docs/setup/kubernetes/platform-setup/ibm/)
* [OpenShift Origin](/zh/docs/setup/kubernetes/platform-setup/openshift/)
* [Amazon Web Services (AWS) with Kops](/zh/docs/setup/kubernetes/platform-setup/aws/)
* [Azure](/zh/docs/setup/kubernetes/platform-setup/azure/)

1. 在 Pods 和服务上检查对 [Pods 和服务的要求](/zh/docs/setup/kubernetes/spec-requirements/)。

1. [安装 Helm 客户端](https://docs.helm.sh/using_helm)。

1. 默认情况下，Istio 使用 `负载均衡器` 服务对象类型。有些平台不支持 `负载均衡器` 服务对象类型。对于缺少 `负载均衡器` 支持的平台，安装需要带有 “`NodePort`” 支持的 Istio，而不是在 Helm 操作完后追加 `--set gateways.istio-ingressgateway.type=NodePort --set gateways.istio-egressgateway.type=NodePort` 的标记。

## 安装步骤

1. 如果使用 Helm 2.10.0 之前的版本，通过 `kubectl apply` [自定义资源定义](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，然后等待几秒钟，直到 kube-apiserver 中的 CRDs 提交完成:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

    > 如果您正在启用 `certmanager`，那么您还需要安装它的 CRDs，并等待几秒钟，以便在 kube-apiserver 中提交 CRDs :

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/charts/certmanager/templates/crds.yaml
    {{< /text >}}

1. 从下面的两个选项中选择一个，**相互排斥** 选项描述如下

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
    $ kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
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

[安装选项](/docs/reference/config/installation-options/) 中有选项的完整列表，可以让您根据自己的需要对 Istio 安装进行裁剪。在 `helm install` 中使用 `--set` 覆盖默认参数之前，请先检查 `install/kubernetes/helm/istio/values.yaml` 中的配置项，并根据需要添加或删除备注。

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

* 如果需要，可以删除 CRDs：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
    {{< /text >}}