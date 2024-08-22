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
Follow this guide to install and configure an Istio mesh with support for ambient mode.
If you are new to Istio, and just want to try it out, follow the
[quick start instructions](/docs/ambient/getting-started) instead.
{{< /tip >}}

We encourage the use of Helm to install Istio for production use in ambient mode. To allow controlled upgrades, the control plane and data plane components are packaged and installed separately. (Because the ambient data plane is split across [two components](/docs/ambient/architecture/data-plane), the ztunnel and waypoints, upgrades involve separate steps for these components.)

## 前提条件 {#prerequisites}

1. 检查[平台特定先决条件](/zh/docs/ambient/install/platform-preventions)。

1. [安装 Helm 客户端](https://helm.sh/docs/intro/install/)，版本要求 3.6 或更高。

1. 配置 Helm 仓库：

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

## Install the control plane

Default configuration values can be changed using one or more `--set <parameter>=<value>` arguments. Alternatively, you can specify several parameters in a custom values file using the `--values <file>` argument.

{{< tip >}}
You can display the default values of configuration parameters using the `helm show values <chart>` command or refer to Artifact Hub chart documentation for the [base](https://artifacthub.io/packages/helm/istio-official/base?modal=values), [istiod](https://artifacthub.io/packages/helm/istio-official/istiod?modal=values), [CNI](https://artifacthub.io/packages/helm/istio-official/cni?modal=values), [ztunnel](https://artifacthub.io/packages/helm/istio-official/ztunnel?modal=values) and [Gateway](https://artifacthub.io/packages/helm/istio-official/gateway?modal=values) chart configuration parameters.
{{< /tip >}}

Full details on how to use and customize Helm installations are available in [the sidecar installation documentation](/docs/setup/install/helm/).

Unlike [istioctl](/docs/ambient/install/istioctl/) profiles, which group together components to be installed or removed, Helm profiles simply set groups of configuration values.

### Base components

`base` Chart 包含设置 Istio 所需的基本 CRD 和集群角色。
需要先安装此 Chart，才能安装任何其他 Istio 组件。

{{< text syntax=bash snip_id=install_base >}}
$ helm install istio-base istio/base -n istio-system --create-namespace --wait
{{< /text >}}

### istiod control plane

The `istiod` chart installs a revision of Istiod. Istiod is the control plane component that manages and
configures the proxies to route traffic within the mesh.

{{< text syntax=bash snip_id=install_istiod >}}
$ helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait
{{< /text >}}

### CNI node agent

The `cni` chart installs the Istio CNI node agent. It is responsible for detecting the pods that belong to the ambient mesh, and configuring the traffic redirection between pods and the ztunnel node proxy (which will be installed later).

{{< text syntax=bash snip_id=install_cni >}}
$ helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait
{{< /text >}}

## Install the data plane

### ztunnel DaemonSet

`ztunnel` Chart 会安装 ztunnel DaemonSet，它是 Istio Ambient 模式的节点代理组件。

{{< text syntax=bash snip_id=install_ztunnel >}}
$ helm install ztunnel istio/ztunnel -n istio-system --wait
{{< /text >}}

### Ingress gateway (optional)

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
您可以按照[部署示例应用程序](/zh/docs/ambient/getting-started/deploy-sample-app/)指南部署示例应用程序和入口网关，
然后您可以[添加您的应用程序到 Ambient 网格中](/zh/docs/ambient/getting-started/secure-and-visualize/#add-bookinfo-to-the-mesh)。

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

1. Delete the ztunnel chart:

    {{< text syntax=bash snip_id=delete_ztunnel >}}
    $ helm delete ztunnel -n istio-system
    {{< /text >}}

1. Delete the Istio CNI chart:

    {{< text syntax=bash snip_id=delete_cni >}}
    $ helm delete istio-cni -n istio-system
    {{< /text >}}

1. Delete the istiod control plane chart:

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
