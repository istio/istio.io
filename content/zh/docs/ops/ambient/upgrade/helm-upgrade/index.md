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
由于 Ambient 尚未稳定，以下声明不是兼容性保证，后续可能会变更或移除。
在达到稳定状态之前，此组件和/或控制平面可能会有破坏性变更，使得次要版本之间互不兼容。
{{< /warning >}}

只要 ztunnel 的版本差距不超过一个次要版本，1.x 版本总体上与 1.x+1 和 1.x 版本的控制平面兼容，
这意味着必须先升级控制平面，再升级 ztunnel。

{{< warning >}}
就地升级 ztunnel 将短暂中断节点上的所有 Ambient Mesh 流量。
建议使用节点封锁和蓝/绿节点池来减轻生产环境升级期间的影响范围。
有关详细信息，请参阅您的 Kubernetes 提供商文档。
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_ztunnel >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system
{{< /text >}}

### 升级 CNI 组件 {#upgrade-the-cni-component}

Istio CNI 代理负责检测添加到 Ambient 网格的 Pod，
通知 ztunnel 应在添加的 Pod 内建立代理端口，并在 Pod 网络命名空间内配置流量重定向。
它不是数据平面或控制平面的一部分。

{{< warning >}}
由于 Ambient 尚未稳定，以下声明不具备兼容性保证，可能会变更或移除。
在达到稳定状态之前，该组件和/或控制平面可能会受到破坏性变更，从而阻碍次要版本之间的兼容性。
{{< /warning >}}

CNI 1.x 版本通常与 1.x+1 和 1.x 版本的控制平面兼容，
这意味着控制平面必须在 Istio CNI 之前升级，需要它们之前的版本差异在一个次要版本之内。

{{< warning >}}
将 Istio CNI 代理就地升级到兼容版本不会中断已成功添加到 Ambient 网格中正在运行 Pod 的网络，
但在节点上 Istio CNI 代理成功升级并完成就绪检查之前，
不会有任何 Ambient 捕获的 Pod 可以在节点上被成功调度（或重新调度）。
如果这是一个重大的中断问题，或者需要对 CNI 升级进行更严格的影响范围控制，则建议使用节点污染和/或节点警戒线。
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
