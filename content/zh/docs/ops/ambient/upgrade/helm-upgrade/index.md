---
title: 使用 Helm 升级
description: 如何使用 Helm 升级 Ambient Mesh。
weight: 5
owner: istio/wg-environments-maintainers
test: yes
status: Experimental
---

根据本指南使用 [Helm](https://helm.sh/docs/) 升级和配置 Ambient Mesh。
本指南假设您已经[通过 Helm 安装](/zh/docs/ops/ambient/install/helm-installation/)了
Istio 的一个较早的次要版本或补丁版本的 Ambient Mesh。

{{< boilerplate ambient-alpha-warning >}}

{{< warning >}}
与 Sidecar 模式相比，`Ambient` 支持将应用程序 Pod 移动到已升级的数据平面，
而无需强制重新启动或重新编排正在运行的应用程序 Pod。
但是，升级数据平面**将**短暂中断被升级节点上的所有工作负载流量，
并且 Ambient 当前不支持数据平面的金丝雀升级。

建议使用节点封锁和蓝/绿节点池来控制生产环境升级期间应用程序 Pod 流量中断的影响范围。
有关详细信息，请参阅您的 Kubernetes 提供商文档。
{{< /warning >}}

## 先决条件 {#prerequisites}

1. 按照[使用 Helm 安装](/zh/docs/ops/ambient/install/helm-installation/)并满足该指南中的所有先决条件，
   通过 Helm 安装 Ambient Mesh。

1. 更新 Helm 仓库：

    {{< text syntax=bash snip_id=update_helm >}}
    $ helm repo update istio
    {{< /text >}}

## 就地升级 {#in-place-upgrade}

您可以使用 Helm 升级工作流程在集群中就地升级 Istio。

在升级 Istio 之前，建议先运行 `istioctl x precheck` 命令以确保升级与您的环境兼容。

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

{{< warning >}}
[Helm 在执行升级时不会升级或删除 CRD](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/#some-caveats-and-explanations)。
由于此限制，在使用 Helm 升级 Istio 时需要执行额外的步骤。
{{< /warning >}}

### 手动升级 CRD 和 Istio Base Chart {#manually-upgrade-the-crds-and-istio-base-chart}

1. 升级 Kubernetes 自定义资源定义 ({{< gloss "crd" >}}CRD{{</ gloss >}})：

    {{< text syntax=bash snip_id=manual_crd_upgrade >}}
    $ kubectl apply -f manifests/charts/base/crds
    {{< /text >}}

1. 升级 Istio Base Chart：

    {{< text syntax=bash snip_id=upgrade_base >}}
    $ helm upgrade istio-base manifests/charts/base -n istio-system --skip-crds
    {{< /text >}}

### 升级 Istio Discovery 组件 {#upgrade-the-istio-discovery-component}

Istiod 是管理和配置代理以在 ambient mesh 中路由流量的控制平面组件。

{{< text syntax=bash snip_id=upgrade_istiod >}}
$ helm upgrade istiod istio/istiod -n istio-system
{{< /text >}}

### 升级 ztunnel 组件 {#upgrade-the-ztunnel-component}

ztunnel DaemonSet 是 Ambient 中的 L4 节点代理组件。

{{< warning >}}
就地升级 ztunnel 将短暂中断节点上的所有 Ambient Mesh 流量。
建议使用节点封锁和蓝/绿节点池来减轻生产环境升级期间的影响范围。
有关详细信息，请参阅您的 Kubernetes 提供商文档。
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_ztunnel >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system
{{< /text >}}

### 升级 CNI 组件 {#upgrade-the-cni-component}

Istio CNI Agent 负责检测属于 Ambient Mesh 的 Pod，
并配置 Pod 和 ztunnel DaemonSet 之间的流量重定向。
Istio CNI Agent 不是数据平面或控制平面的一部分。

Istio CNI Agent 1.x 版本兼容控制平面 1.x-1、1.x 以及 1.x+1 版本，
这意味着 Istio CNI Agent 和 Istio 控制平面能够以任何先后顺序独立升级。
只要它们的版本差异在一个小版本之内。

{{< warning >}}
升级 Istio CNI Agent 将重新配置节点上的网络，因此会暂时中断节点流量。
为了控制 Istio CNI Agent 升级期间影响应用程序 Pod 的范围，建议使用节点警戒线。
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_cni >}}
$ helm upgrade istio-cni istio/cni -n istio-system
{{< /text >}}

### （可选）升级 Gateway 组件 {#optional-upgrade-the-gateway-component}

Gateway 组件管理 Ambient Mesh 边界之间的东西向和南北向数据平面流量，
以及 L7 数据平面的某些方面。

{{< text syntax=bash snip_id=upgrade_gateway >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

## 配置 {#configuration}

要查看已被支持的配置选项和文档，请运行：

{{< text syntax=bash snip_id=show_istiod_values >}}
$ helm show values istio/istiod
{{< /text >}}

## 验证安装 {#verify-the-installation}

### 验证工作负载状态 {#verify-the-workload-status}

安装所有组件后，您可以使用以下命令检查 Helm 部署状态：

{{< text syntax=bash snip_id=show_components >}}
$ helm list -n istio-system
{{< /text >}}

您可以使用以下命令检查已部署的 Istio Pod 的状态：

{{< text syntax=bash snip_id=check_pods >}}
$ kubectl get pods -n istio-system
{{< /text >}}

## 卸载 {#uninstall}

请参阅我们的 [Helm Ambient 安装指南](/zh/docs/ops/ambient/install/helm-installation/#uninstall)中的卸载部分。
