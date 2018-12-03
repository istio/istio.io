---
title: Istio 最小化安装
description: 使用 Helm 最小化安装 Istio 。
weight: 31
keywords: [kubernetes,helm, minimal]
icon: helm
---

使用 Helm 最小化安装和配置 Istio 的快速入门指南。此最小安装提供了 Istio 的流量管理功能。

## 前置条件

请参考快速入门指南中描述的[前置条件](/zh/docs/setup/kubernetes/quick-start/#前置条件)。

## 安装步骤

1. 如果你的 Helm 版本低于 2.10.0，通过 `kubectl apply` 安装 Istio 的 [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，稍等片刻 CRD 会被提交到 kube-apiserver：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

1. 从以下**互斥**的两个选项中选择一个并执行。

### 选项 1：通过 Helm 命令 `helm template` 安装

1. 将 Istio 的核心组件添加到 Kubernetes 的描述文件，并命名为 `istio-minimal.yaml`：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
      --set security.enabled=false \
      --set ingress.enabled=false \
      --set gateways.istio-ingressgateway.enabled=false \
      --set gateways.istio-egressgateway.enabled=false \
      --set galley.enabled=false \
      --set sidecarInjectorWebhook.enabled=false \
      --set mixer.enabled=false \
      --set prometheus.enabled=false \
      --set global.proxy.envoyStatsd.enabled=false \
      --set pilot.sidecar=false > $HOME/istio-minimal.yaml
    {{< /text >}}

1. 通过描述文件安装 Pilot 组件：

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl apply -f $HOME/istio-minimal.yaml
    {{< /text >}}

### 选项 2：通过 `helm install` 命令安装 Helm 和 Tiller

本选项允许 Helm 和 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 管理 Istio 的生命周期。

1. 如果还没有为 Tiller 安装 service account，请安装一个：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1. 使用已安装的 service account 将 Tiller 安装到你的集群：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 安装 Istio：

    {{< text bash >}}
    $ helm install install/kubernetes/helm/istio --name istio-minimal --namespace istio-system \
      --set security.enabled=false \
      --set ingress.enabled=false \
      --set gateways.istio-ingressgateway.enabled=false \
      --set gateways.istio-egressgateway.enabled=false \
      --set galley.enabled=false \
      --set sidecarInjectorWebhook.enabled=false \
      --set mixer.enabled=false \
      --set prometheus.enabled=false \
      --set global.proxy.envoyStatsd.enabled=false \
      --set pilot.sidecar=false
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

    {{< text bash >}}
    $ helm delete --purge istio-minimal
    {{< /text >}}

    如果 Helm 版本低于 2.10.0，在部署新版本的 Istio chart 之前，你需要手动清理额外的 job 资源：

    {{< text bash >}}
    $ kubectl -n istio-system delete job --all
    {{< /text >}}

* 如果需要，删除 CRD：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
    {{< /text >}}
