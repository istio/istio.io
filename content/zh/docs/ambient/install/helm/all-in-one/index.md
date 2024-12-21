---
title: 使用 Helm 安装（简易）
description: 使用单个 Chart 安装支持 Helm Ambient 模式的 Istio。
weight: 4
owner: istio/wg-environments-maintainers
test: yes
draft: true
---

{{< tip >}}
按照本指南安装和配置支持 Ambient 模式的 Istio 网格。如果您是 Istio 新手，只想尝试一下，
请按照[快速入门说明](/zh/docs/ambient/getting-started)进行操作。
{{< /tip >}}

我们鼓励使用 Helm 在 Ambient 模式下安装 Istio 以供生产使用。
为了允许受控升级，控制平面和数据平面组件是分开打包和安装的。
（由于 Ambient 数据平面分为[两个组件](/zh/docs/ambient/architecture/data-plane)，
ztunnel 和 waypoint，因此升级涉及这些组件的单独步骤。）

## 先决条件 {#prerequisites}

1. 检查[平台特定的先决条件](/zh/docs/ambient/install/platform-prerequisites)。

1. [安装 Helm 客户端](https://helm.sh/docs/intro/install/)，版本 3.6 及以上。

1. 配置 Helm 仓库：

    {{< text syntax=bash snip_id=configure_helm >}}
    $ helm repo add istio https://istio-release.storage.googleapis.com/charts
    $ helm repo update
    {{< /text >}}

<!-- ### Base components -->

<!-- The `base` chart contains the basic CRDs and cluster roles required to set up Istio. -->
<!-- This should be installed prior to any other Istio component. -->

<!-- {{< text syntax=bash snip_id=install_base >}} -->
<!-- $ helm install istio-base istio/base -n istio-system --create-namespace --wait -->
<!-- {{< /text >}} -->

### 安装或升级 Kubernetes Gateway API CRD {#install-or-upgrade-the-kubernetes-gateway-api-crds}

{{< boilerplate gateway-api-install-crds >}}

### 安装 Istio Ambient 控制平面和数据平面 {#install-the-istio-ambient-control-plane-and-data-plane}

`ambient` Chart 安装 Ambient 所需的所有 Istio 数据平面和控制平面组件，
使用组成各个组件 Chart 的 Helm 包装器 Chart。

{{< warning >}}
请注意，如果您将所有内容作为此包装器 Chart 的一部分安装，
则只能通过此包装器 Chart 升级或卸载 Ambient - 您不能单独升级或卸载子组件。
{{< /warning >}}

{{< text syntax=bash snip_id=install_ambient_aio >}}
$ helm install istio-ambient istio/ambient --namespace istio-system --create-namespace --wait
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

如果您的 Kubernetes 集群不支持 `LoadBalancer` 服务类型（`type: LoadBalancer`）
且未分配正确的外部 IP，请在不带 `--wait` 参数的情况下运行上述命令以避免无限等待。
有关网关安装的详细文档，请参阅[安装网关](/zh/docs/setup/additional-setup/gateway/)。

## 配置 {#configuration}

Ambient 包装器 Chart 由以下组件 Helm Chart 组成

- base
- istiod
- istio-cni
- ztunnel

可以使用一个或多个 `--set <parameter>=<value>` 参数更改默认配置值。
或者，您可以使用 `--values <file>` 参数在自定义值文件中指定多个参数。

您可以通过包装器 Chart 覆盖组件级设置，就像单独安装组件时一样，通过在值路径前加上组件名称。

例如：

{{< text syntax=bash snip_id=none >}}
$ helm install istiod istio/istiod --set hub=gcr.io/istio-testing
{{< /text >}}

变为：

{{< text syntax=bash snip_id=none >}}
$ helm install istio-ambient istio/ambient --set istiod.hub=gcr.io/istio-testing
{{< /text >}}

当通过包装 Chart 设置时。

要查看每个子组件支持的配置选项和文档，请运行：

{{< text syntax=bash >}}
$ helm show values istio/istiod
{{< /text >}}

对于您感兴趣的每个组件。

有关如何使用和自定义 Helm 安装的完整详细信息，
请参阅 [Sidecar 安装文档](/zh/docs/setup/install/helm/)。

## 验证安装 {#verify-the-installation}

### 验证工作负载状态 {#verify-the-workload-status}

安装所有组件后，您可以使用以下命令检查 Helm 部署状态：

{{< text syntax=bash snip_id=show_components >}}
$ helm ls -n istio-system
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART           APP VERSION
istio-ambient      istio-system    1           2024-04-17 22:14:45.964722028 +0000 UTC deployed    ambient-{{< istio_full_version >}}     {{< istio_full_version >}}
{{< /text >}}

您可以使用以下命令检查已部署 Pod 的状态：

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
NAME                             READY   STATUS    RESTARTS   AGE
istio-cni-node-g97z5             1/1     Running   0          10m
istiod-5f4c75464f-gskxf          1/1     Running   0          10m
ztunnel-c2z4s                    1/1     Running   0          10m
{{< /text >}}

### 使用示例应用程序进行验证 {#verify-with-the-sample-application}

使用 Helm 安装 Ambient 模式后，您可以按照[部署示例应用程序](/zh/docs/ambient/getting-started/deploy-sample-app/)指南来部署示例应用程序和入口网关，
然后您可以[将您的应用程序添加到环境网格](/zh/docs/ambient/getting-started/secure-and-visualize/#add-bookinfo-to-the-mesh)。

## 卸载 {#uninstall}

您可以通过卸载上面安装的 Chart 来卸载 Istio 及其组件。

1. 卸载所有 Istio 组件

    {{< text syntax=bash snip_id=delete_ambient_aio >}}
    $ helm delete istio-ambient -n istio-system
    {{< /text >}}

1. （可选）删除所有 Istio 网关 Chart 安装：

    {{< text syntax=bash snip_id=delete_ingress >}}
    $ helm delete istio-ingress -n istio-ingress
    $ kubectl delete namespace istio-ingress
    {{< /text >}}

1. 删​​除 Istio 安装的 CRD（可选）

    {{< warning >}}
    This will delete all created Istio resources.
    {{< /warning >}}

    {{< text syntax=bash snip_id=delete_crds >}}
    $ kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
    {{< /text >}}

1. 删​​除 `istio-system` 命名空间：

    {{< text syntax=bash snip_id=delete_system_namespace >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}
