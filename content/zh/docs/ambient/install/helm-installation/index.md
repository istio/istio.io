---
title: 通过 Helm 安装
description: 使用 Helm 在 Ambient 模式下安装 Istio。
weight: 4
owner: istio/wg-environments-maintainers
aliases:
  - /zh/docs/ops/ambient/install/helm-installation
  - /zh/latest/docs/ops/ambient/install/helm-installation
test: yes
---

本指南向您展示如何使用 Helm 在环境模式下安装 Istio。
除了遵循[Ambient 模式入门](/zh/docs/ambient/getting-started/)中的演示之外，
我们鼓励使用 Helm 安装 Istio 使其在 Ambient 模式下运行。
Helm 帮助您单独管理组件，您可以轻松地将组件升级到最新版本。

## 前提条件 {#prerequisites}

1. 检查[平台特定先决条件](/zh/docs/ambient/install/platform-preventions)。

1. [安装 Helm 客户端](https://helm.sh/docs/intro/install/)，版本要求 3.6 或更高。

1. 配置 Helm 仓库：

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

有关 Helm 命令文档，请参阅 [Helm 仓库](https://helm.sh/docs/helm/helm_repo/)。

## 安装组件 {#installing-the-components}

### 安装 base 组件 {#installing-the-base-component}

`base` Chart 包含设置 Istio 所需的基本 CRD 和集群角色。
需要先安装此 Chart，才能安装任何其他 Istio 组件。

{{< text syntax=bash snip_id=install_base >}}
$ helm install istio-base istio/base -n istio-system --create-namespace --wait
{{< /text >}}

### 安装 CNI 组件 {#installing-the-cni-component}

`cni` Chart 将安装 Istio CNI 插件。它负责检测属于 Ambient 网格的 Pod，
并配置 Pod 和 ztunnel 节点代理（稍后将安装）之间的流量重定向。

{{< text syntax=bash snip_id=install_cni >}}
$ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait
{{< /text >}}

### 安装 Istiod 组件 {#installing-the-discovery-component}

`istiod` Chart 会安装 Istiod 的修订版。Istiod 是控制平面组件，用于管理和配置代理，以在网格内进行流量路由。

{{< text syntax=bash snip_id=install_discovery >}}
$ helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait
{{< /text >}}

### 安装 ztunnel 组件 {#installing-the-ztunnel-component}

`ztunnel` Chart 会安装 ztunnel DaemonSet，它是 Istio Ambient 模式的节点代理组件。

{{< text syntax=bash snip_id=install_ztunnel >}}
$ helm install ztunnel istio/ztunnel -n istio-system --wait
{{< /text >}}

### 安装入口网关（可选） {#install-an-ingress-gateway-optional}

要安装入口网关，请运行以下命令：

{{< text syntax=bash snip_id=install_ingress >}}
$ helm install istio-ingress istio/gateway -n istio-ingress --create-namespace --wait
{{< /text >}}

如果您的 Kubernetes 集群不支持分配了正确外部 IP 的
`LoadBalancer` 服务类型（`type: LoadBalancer`），
请在不带 `--wait` 参数的情况下运行上述命令，以避免无限等待。
有关网关安装的详细文档，
请参阅[安装 Gateway](/zh/docs/setup/additional-setup/gateway/)。

## 配置 {#configuration}

要查看已被支持的配置选项和文档，请运行：

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

### 使用示例应用程序进行验证 {#verifying-with-the-sample-application}

使用 Helm 安装 Ambient 模式后，
您可以按照[部署示例应用程序](/zh/docs/ambient/getting-started/#bookinfo)指南部署示例应用程序和入口网关，
然后您可以[添加您的应用程序到 Ambient 网格中](/zh/docs/ambient/getting-started/#addtoambient)。

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

1. 删除 Istio CNI Chart：

    {{< text syntax=bash snip_id=delete_cni >}}
    $ helm delete istio-cni -n istio-system
    {{< /text >}}

1. 删除 Istio ztunnel Chart：

    {{< text syntax=bash snip_id=delete_ztunnel >}}
    $ helm delete ztunnel -n istio-system
    {{< /text >}}

1. 删除 Istio discovery Chart：

    {{< text syntax=bash snip_id=delete_discovery >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. 删除 Istio base Chart：

    {{< tip >}}
    根据设计，通过 Helm 删除 Chart 不会删除通过 Chart 安装的自定义资源定义（CRD）。
    {{< /tip >}}

    {{< text syntax=bash snip_id=delete_base >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. 删除 Istio 安装的 CRD（可选）

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
