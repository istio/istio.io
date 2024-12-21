---
title: 通过 Helm 安装
description: 使用 Helm 安装支持 Ambient 模式的 Istio。
weight: 4
owner: istio/wg-environments-maintainers
aliases:
  - /zh/docs/ops/ambient/install/helm-installation
  - /zh/latest/docs/ops/ambient/install/helm-installation
  - /zh/docs/ambient/install/helm-installation
  - /zh/latest/docs/ambient/install/helm-installation
test: yes
---

{{< tip >}}
按照本指南安装和配置支持 Ambient 模式的 Istio 网格。
如果您是 Istio 新手，只想尝试一下，
请按照[快速入门说明](/zh/docs/ambient/getting-started)进行操作。
{{< /tip >}}

我们鼓励使用 Helm 在 Ambient 模式下安装 Istio 以供生产使用。
为了允许受控的升级，控制平面和数据平面组件是分开打包和安装的。
（由于 Ambient 数据平面分为 ztunnel 和 waypoint
[两个组件](/zh/docs/ambient/architecture/data-plane)，
所以需要单独升级这些组件。）

## 前提条件 {#prerequisites}

1. 检查[平台特定的前提条件](/zh/docs/ambient/install/platform-preventions)。

1. [安装 Helm 客户端](https://helm.sh/docs/intro/install/)，版本要求 3.6 或更高。

1. 配置 Helm 仓库：

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

### 安装或升级 Kubernetes Gateway API CRD {#install-or-upgrade-the-kubernetes-gateway-api-crds}

{{< boilerplate gateway-api-install-crds >}}

## 安装控制平面 {#install-the-control-plane}

可以使用一个或多个 `--set <parameter>=<value>` 参数更改默认配置值。
或者，您可以使用 `--values <file>` 参数在自定义值文件中指定多个参数。

{{< tip >}}
您可以使用 `helm show values <chart>` 命令显示配置参数的默认值，
或者参阅 Artifact Hub Chart 文档中的 [base](https://artifacthub.io/packages/helm/istio-official/base?modal=values)、
[istiod](https://artifacthub.io/packages/helm/istio-official/istiod?modal=values)、
[CNI](https://artifacthub.io/packages/helm/istio-official/cni?modal=values)、
[ztunnel](https://artifacthub.io/packages/helm/istio-official/ztunnel?modal=values)
和 [Gateway](https://artifacthub.io/packages/helm/istio-official/gateway?modal=values)
Chart 配置参数。
{{< /tip >}}

有关如何使用和自定义 Helm 安装的完整详细信息，
请参阅 [Sidecar 安装文档](/zh/docs/setup/install/helm/)。

与 [istioctl](/zh/docs/ambient/install/istioctl/)
配置文件（它会将要安装或移除的组件放在一组）不同，
而 Helm 配置文件只是对配置值做了分组。

### 基本组件 {#base-components}

`base` Chart 包含设置 Istio 所需的基本 CRD 和集群角色。
需要先安装此 Chart，才能安装任何其他 Istio 组件。

{{< text syntax=bash snip_id=install_base >}}
$ helm install istio-base istio/base -n istio-system --create-namespace --wait
{{< /text >}}

### istiod 控制平面 {#istiod-control-plane}

`istiod` Chart 安装了修订版的 Istiod。
Istiod 是管理和配置代理以在网格内路由流量的控制平面组件。

{{< text syntax=bash snip_id=install_istiod >}}
$ helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait
{{< /text >}}

### CNI 节点代理 {#cni-node-agent}

`cni` Chart 安装 Istio CNI 节点代理。此代理负责检测属于 Ambient 网格的 Pod，
并配置 Pod 和 ztunnel 节点代理（稍后安装）之间的流量重定向。

{{< text syntax=bash snip_id=install_cni >}}
$ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait
{{< /text >}}

## 安装数据平面 {#install-the-data-plane}

### ztunnel DaemonSet {#ztunnel-daemonset}

`ztunnel` Chart 会安装 ztunnel DaemonSet，它是 Istio Ambient 模式的节点代理组件。

{{< text syntax=bash snip_id=install_ztunnel >}}
$ helm install ztunnel istio/ztunnel -n istio-system --wait
{{< /text >}}

### 入口网关（可选） {#ingress-gateway-optional}

{{< tip >}}
{{< boilerplate gateway-api-future >}}
如果您使用 Gateway API，则无需按照下文所述安装和管理入口网关 Helm Chart。
有关详细信息，请参阅 [Gateway API 任务](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)。
{{< /tip >}}

要安装入口网关，请运行以下命令：

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
{{< /text >}}

如果您的 Kubernetes 集群不支持分配了正确外部 IP 的 `LoadBalancer` 服务类型（`type: LoadBalancer`），
请在不带 `--wait` 参数的情况下运行上述命令，以避免无限等待。有关网关安装的详细文档，
请参阅[安装 Gateway](/zh/docs/setup/additional-setup/gateway/)。

## 配置 {#configuration}

要查看受支持的配置选项和文档，请运行：

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

## 验证安装 {#verifying-the-installation}

### 验证工作负载状态 {#verifying-the-workload-status}

安装所有组件后，您可以使用以下命令检查 Helm 部署状态：

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
{{< /text >}}

您可以使用以下命令检查已部署的 Pod 状态：

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
NAME                             READY   STATUS    RESTARTS   AGE
istio-cni-node-g97z5             1/1     Running   0          10m
istiod-5f4c75464f-gskxf          1/1     Running   0          10m
ztunnel-c2z4s                    1/1     Running   0          10m
{{< /text >}}

### 使用示例应用进行验证 {#verifying-with-the-sample-application}

使用 Helm 安装 Ambient 模式后，
您可以按照[部署示例应用](/zh/docs/ambient/getting-started/deploy-sample-app/)指南部署示例应用和入口网关，
然后您可以[添加您的应用到 Ambient 网格中](/zh/docs/ambient/getting-started/secure-and-visualize/#add-bookinfo-to-the-mesh)。

## 卸载 {#uninstall}

您可以通过卸载上面安装的 Chart 来卸载 Istio 及其组件。

1. 列出安装在 `istio-system` 命名空间中的所有 Istio Chart：

    {{< text syntax=bash >}}
    $ helm ls -n istio-system
    NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
    istio-base      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    base-{{< istio_full_version >}}     {{< istio_full_version >}}
    istio-cni       istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    cni-{{< istio_full_version >}}      {{< istio_full_version >}}
    istiod          istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    istiod-{{< istio_full_version >}}   {{< istio_full_version >}}
    ztunnel         istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ztunnel-{{< istio_full_version >}}  {{< istio_full_version >}}
    {{< /text >}}

1.（可选）删除所有 Istio 网关 Chart 安装文件：

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. 删​​除 ztunnel Chart：

    {{< text syntax=bash snip_id=delete_ztunnel >}}
    $ helm delete ztunnel -n istio-system
    {{< /text >}}

1. 删除 Istio CNI Chart：

    {{< text syntax=bash snip_id=delete_cni >}}
    $ helm delete istio-cni -n istio-system
    {{< /text >}}

1. 删除 istiod 控制平面 Chart：

    {{< text syntax=bash snip_id=delete_istiod >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. 删除 Istio base Chart：

    {{< tip >}}
    根据设计，通过 Helm 删除 Chart 不会删除通过 Chart 安装的自定义资源定义（CRD）。
    {{< /tip >}}

    {{< text syntax=bash snip_id=delete_base >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. 删除通过 Istio 安装的 CRD（可选）

    {{< warning >}}
    这将删除所有已创建的 Istio 资源。
    {{< /warning >}}

    {{< text syntax=bash snip_id=delete_crds >}}
    $ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
    {{< /text >}}

1. 删除 `istio-system` 命名空间：

    {{< text syntax=bash snip_id=delete_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

## 安装前生成清单 {#generate-a-manifest-before-installation}

您可以在安装 Istio 之前使用 `helm template` 子命令为每个组件生成清单。
例如，要为 `istiod` 组件生成可以使用 `kubectl` 安装的清单：

{{< text syntax=bash snip_id=none >}}
$ helm template istiod istio/istiod -n istio-system --kube-version {Kubernetes version of target cluster} > istiod.yaml
{{< /text >}}

生成的清单可用于检查具体安装了什么以及跟踪清单随时间的变化。

{{< tip >}}
您通常用于安装的任何其他标志或自定义值覆盖也应提供给 `helm template` 命令。
{{< /tip >}}

要安装上面生成的清单，它将在目标集群中创建 `istiod` 组件：

{{< text syntax=bash snip_id=none >}}
$ kubectl apply -f istiod.yaml
{{< /text >}}

{{< warning >}}
如果尝试使用 `helm template` 安装和管理 Istio，请注意以下注意事项：

1. 必须手动创建 Istio 命名空间（默认为 `istio-system`）。

1. 资源可能未按照与 `helm install` 相同的依赖顺序进行安装

1. 此方法尚未作为 Istio 版本的一部分进行测试。

1. 虽然 `helm install` 会自动从 Kubernetes 上下文中检测特定于环境的设置，
   但 `helm template` 无法做到这一点，因为它是离线运行的，
   这可能会导致意外结果。特别是，如果您的 Kubernetes 环境不支持第三方服务帐户令牌，
   您必须确保遵循[这些步骤](/zh/docs/ops/best-practices/security/#configure-third-party-service-account-tokens)。

1. 由于集群中的资源没有按正确的顺序可用，
   生成的清单的 `kubectl apply` 可能会显示瞬态错误。

1. `helm install` 会自动修剪配置更改时应删除的任何资源（例如，如果您删除网关）。
   当您将 `helm template` 与 `kubectl` 一起使用时，
   不会发生这种情况，必须手动删除这些资源。

{{< /warning >}}
