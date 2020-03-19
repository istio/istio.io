---
title: 使用 Helm 升级
description: 升级 Istio 控制平面，可以选择使用 Helm 升级 CNI 插件。
weight: 30
aliases:
    - /zh/docs/setup/kubernetes/upgrade/steps/
    - /zh/docs/setup/upgrade/steps
keywords: [kubernetes,upgrading]
---

请参阅本指南，以升级使用 Helm 安装的 Istio 控制平面和 sidecar 代理。升级过程可能会安装新的二级制文件，并可能修改配置和 API schema。升级过程可能导致服务停机。为了减少停机时间，请确保 Istio 控制平面组件和应用程序是多副本高可用的。

{{< warning >}}
在将 Istio 版本升级到 {{< istio_version >}} 之前，请务必查看[升级说明]。
{{< /warning >}}

{{< tip >}}
Istio **不支持** 跨版本升级。仅支持从 {{< istio_previous_version >}} 版本升级到 {{< istio_version >}} 版本。如果您使用的是旧版本，请先升级到 {{< istio_previous_version >}} 版本。
{{< /tip >}}

## 升级步骤{#upgrade-steps}

[下载新版本 Istio](/zh/docs/setup/getting-started/#download)，并切换目录到新版本的目录下。

### Istio CNI 升级{#Istio-CNI-upgrade}

如果您已经安装或计划安装 [Istio CNI](/zh/docs/setup/additional-setup/cni/)，请选择以下 **互斥** 选项之一，检查 Istio CNI 是否已经安装并进行升级：

{{< tabset category-name="controlplaneupdate" >}}
{{< tab name="Kubernetes rolling update" category-value="k8supdate" >}}

您可以使用 Kubernetes 的滚动更新机制来升级 Istio CNI 组件。这适用于使用 `kubectl apply` 部署 Istio CNI 的情况。

1. 检查是否已安装 `istio-cni`。找到 `istio-cni-node` pod 以及它们运行的命名空间（通常是 `kube-system` 或 `istio-system`）：

    {{< text bash >}}
    $ kubectl get pods -l k8s-app=istio-cni-node --all-namespaces
    $ NAMESPACE=$(kubectl get pods -l k8s-app=istio-cni-node --all-namespaces --output='jsonpath={.items[0].metadata.namespace}')
    {{< /text >}}

1. 如果 `istio-cni` 安装在 `kube-system` 以外的命名空间（例如：`istio-system`），请删除 `istio-cni`：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=$NAMESPACE | kubectl delete -f -
    {{< /text >}}

1. 在 `kube-system` 命名空间中安装或升级 `istio-cni`：

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio-cni --name=istio-cni --namespace=kube-system | kubectl apply -f -
    {{< /text >}}

{{< /tab >}}

{{< tab name="Helm upgrade" category-value="helmupgrade" >}}

如果您已使用 [Helm and Tiller](/zh/docs/setup/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install) 安装 Istio CNI，请优先使用 Helm 升级 Istio CNI。

1. 检查 `istio-cni` 是否已安装，并检查安装在哪个命名空间：

    {{< text bash >}}
    $ helm status istio-cni
    {{< /text >}}

1. 根据下面几种情况来安装或升级 `istio-cni`：

    * 如您尚未安装 `istio-cni`，并决定安装它，则运行以下命令：

        {{< text bash >}}
        $ helm install install/kubernetes/helm/istio-cni --name istio-cni --namespace kube-system
        {{< /text >}}

    * 如果 `istio-cni` 已被安装到 `kube-system` 以外的命名空间（例如：`istio-system`）中，请先运行以下命令删除：

        {{< text bash >}}
        $ helm delete --purge istio-cni
        {{< /text >}}

        然后，将其安装到 `kube-system` 命名空间中：

        {{< text bash >}}
        $ helm install install/kubernetes/helm/istio-cni --name istio-cni --namespace kube-system
        {{< /text >}}

    * 如果 `istio-cni` 已被安装到命名空间 `kube-system` 中，则运行以下命令升级：

        {{< text bash >}}
        $ helm upgrade istio-cni install/kubernetes/helm/istio-cni --namespace kube-system
        {{< /text >}}

{{< /tab >}}
{{< /tabset >}}

### 控制平面升级{#control-plane-upgrade}

Pilot, Galley, 策略, 遥测和 Sidecar 注入器。
选择下列 **互斥** 选项中的一种升级控制平面：

{{< tabset category-name="controlplaneupdate" >}}
{{< tab name="Kubernetes rolling update" category-value="k8supdate" >}}

您可以使用 Kubernetes 的滚动升级机制来升级控制平面组件。这适用于使用 `kubectl apply` 部署 Istio 组件的情况，包括使用 [Helm template](/zh/docs/setup/install/helm/#option-1-install-with-helm-via-helm-template) 生成的配置。

1. 使用 `kubectl apply` 命令升级所有 Istio 的 CRD。等待 Kubernetes API 服务器提交升级的 CRD：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio-init/files/
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. 应用更新模板:

    {{< text bash >}}
    $ helm template install/kubernetes/helm/istio --name istio \
      --namespace istio-system | kubectl apply -f -
    {{< /text >}}

    您必须使用与首次[安装 Istio](/zh/docs/setup/install/helm) 相同的配置。

滚动更新进程会将所有的部署组件和 configmap 升级到新版本。当此进程执行完毕后，您的 Istio 控制平面将会升级到新版本。

您现有的应用程序无需任何更改，可以继续运行。如果新的控制平面有任何严重的问题，您可以通过应用旧版本的 yaml 文件来回滚此次变更。

{{< /tab >}}

{{< tab name="Helm upgrade" category-value="helmupgrade" >}}

如果您使用 [Helm and Tiller](/zh/docs/setup/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install) 安装 Istio，推荐的方式是使用 Helm 来进行升级。

1. 升级 `istio-init` chart 来更新所有 Istio [用户资源定义](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)（CRD）。

    {{< text bash >}}
    $ helm upgrade --install istio-init install/kubernetes/helm/istio-init --namespace istio-system
    {{< /text >}}

1. {{< boilerplate verify-crds >}}

1. 升级 `istio` chart：

    {{< text bash >}}
    $ helm upgrade istio install/kubernetes/helm/istio --namespace istio-system
    {{< /text >}}

    如果安装了 Istio CNI，则通过添加 `--set istio_cni.enabled=true` 配置项来启用它。

{{< /tab >}}
{{< /tabset >}}

### Sidecar 升级{#sidecar-upgrade}

在升级控制平面后，已运行 Istio 的应用仍将使用旧的 sidecar。要升级 sidecar，您需要重新注入它。

如果您使用自动的 sidecar 注入方式，可以滚动更新所有 pod 来升级 sidecar。这样，新版本的 sidecar 将被自动重新注入。

{{< warning >}}
要运行以下命令，`kubectl` 的版本需要 >= 1.15，必要时请进行升级。
{{< /warning >}}

{{< text bash >}}
$ kubectl rollout restart deployment --namespace default
{{< /text >}}

如果使用手动注入，可以通过以下命令升级 sidecar：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}

如果 sidecar 之前使用了一些定制的配置文件注入，则需要将配置文件中的版本更改为新版本，并通过以下命令重新注入：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject \
     --injectConfigFile inject-config.yaml \
     --filename $ORIGINAL_DEPLOYMENT_YAML)
{{< /text >}}
