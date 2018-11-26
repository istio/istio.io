---
title: Istio 最小化安装
description: 使用 Helm 最小化安装 Istio 。
weight: 31
keywords: [kubernetes,helm, minimal]
icon: helm
---
<!--
---
title: Minimal Istio Installation
description: Install minimal Istio using Helm.
weight: 31
keywords: [kubernetes,helm, minimal]
icon: helm
---
-->

使用 Helm 最小化安装和配置 Istio 的快速入门指南。
此最小安装提供了 Istio 的流量管理功能。
<!--
Quick start instructions for the minimal setup and configuration of Istio using Helm.
This minimal install provides traffic management features of Istio.
-->

## 前置条件

请参考快速入门指南中描述的[前置条件](/zh/docs/setup/kubernetes/quick-start/#前置条件)。

<!--
## Prerequisites

Refer to the [prerequisites](/docs/setup/kubernetes/quick-start/#prerequisites) described in the Quick Start guide.
-->

## 安装步骤

1. 如果你的 Helm 版本低于 2.10.0，通过 `kubectl apply` 安装 Istio 的 [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，稍等片刻 CRD 会被提交到 kube-apiserver：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

1. 从以下**互斥**的两个选项中选择一个并执行。

<!--
## Installation steps

1. If using a Helm version prior to 2.10.0, install Istio's [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)
via `kubectl apply`, and wait a few seconds for the CRDs to be committed in the kube-apiserver:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

1. Choose one of the following two
**mutually exclusive** options described below.
-->

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


<!--
### Option 1: Install with Helm via `helm template`

1. Render Istio's core components to a Kubernetes manifest called `istio-minimal.yaml`:

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

1. Install the Pilot component via the manifest:

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl apply -f $HOME/istio-minimal.yaml
    {{< /text >}}
-->

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


<!--
### Option 2: Install with Helm and Tiller via `helm install`

This option allows Helm and
[Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components)
to manage the lifecycle of Istio.

1. If a service account has not already been installed for Tiller, install one:

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/helm-service-account.yaml
    {{< /text >}}

1. Install Tiller on your cluster with the service account:

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. Install Istio:

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

1. Ensure the `istio-pilot-*` Kubernetes pod is deployed and its container is up and running:

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-pilot-58c65f74bc-2f5xn             1/1       Running   0          1m
{{< /text >}}
-->

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

<!--
## Uninstall

* For option 1, uninstall using `kubectl`:

    {{< text bash >}}
    $ kubectl delete -f $HOME/istio-minimal.yaml
    {{< /text >}}

* For option 2, uninstall using Helm:

    {{< text bash >}}
    $ helm delete --purge istio-minimal
    {{< /text >}}

    If your Helm version is less than 2.10.0, then you need to manually cleanup extra job resource before redeploy new version of Istio chart:

    {{< text bash >}}
    $ kubectl -n istio-system delete job --all
    {{< /text >}}

* If desired, delete the CRDs:

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system
    {{< /text >}}
-->
