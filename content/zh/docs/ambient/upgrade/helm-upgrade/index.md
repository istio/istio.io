---
title: 使用 Helm 升级
description: 使用 Helm 对 Ambient 模式的安装进行升级。
weight: 5
aliases:
  - /zh/docs/ops/ambient/upgrade/helm-upgrade
  - /zh/latest/docs/ops/ambient/upgrade/helm-upgrade
owner: istio/wg-environments-maintainers
test: yes
status: Experimental
---

按照本指南使用 [Helm](https://helm.sh/docs/) 对 Ambient 模式的安装进行升级和配置。
本指南假设您已经使用之前的 Istio 版本执行了
[Helm Ambient 模式安装](/zh/docs/ambient/install/helm-installation/)。

{{< warning >}}
与 Sidecar 模式相比，Ambient 模式支持将应用程序 Pod 移动到升级后的 ztunnel 代理，
而无需强制重启或重新安排正在运行的应用程序 Pod。但是，升级 ztunnel
**将**导致升级节点上所有长寿命 TCP 连接重置，并且 Istio 目前不支持 ztunnel 的金丝雀升级。

建议使用节点封锁和蓝/绿节点池来限制生产升级期间应用程序流量重置的影响范围。
有关详细信息，请参阅 Kubernetes 提供商文档。
{{< /warning >}}

## 了解 Ambient 升级 {#understanding-ambient-upgrades}

所有 Istio 升级都涉及升级控制平面、数据平面和 Istio CRD。
由于 Ambient 数据平面分为[两个组件](/zh/docs/ambient/architecture/data-plane)，
即 ztunnel 和 waypoint，因此升级涉及这些组件的单独步骤。
这里简要介绍了升级控制平面和 CRD，但本质上与[在 Sidecar 模式下升级这些组件的过程](/zh/docs/setup/upgrade/canary/)相同。

与 Sidecar 模式类似，网关可以使用[修订标签](/zh/docs/setup/upgrade/canary/#stable-revision-labels)来对（{{< gloss >}}Gateway{{</ gloss >}}）升级，
包括 waypoint 进行细粒度控制，并可通过简单的控件随时回滚。
但是，与 Sidecar 模式不同，ztunnel 作为 DaemonSet（每个节点的代理）运行，
这意味着 ztunnel 升级至少一次会影响整个节点。虽然这在许多情况下是可以接受的，
但具有长 TCP 连接的应用程序可能会中断。在这种情况下，
我们建议在升级给定节点的 ztunnel 之前使用节点封锁和排空。
为简单起见，本文档将演示 ztunnel 的就地升级，这可能涉及短暂的停机时间。

## 先决条件 {#prerequisites}

### 整理你的标签和修订 {#organize-your-tags-and-revisions}

为了安全地在 Ambient 模式下升级网格，您的网关和命名空间应使用 `istio.io/rev` 标签来指定修订标签，
该标签控制正在运行的代理版本。我们建议将您的生产集群分成多个标签来组织您的升级。
给定标签的所有成员将同时升级，因此最好从风险最低的应用程序开始升级。
我们不建议直接通过标签引用修订进行升级，因为此过程很容易导致意外升级大量代理，
并且难以细分。要查看您在集群中使用的标签和修订，请参阅有关升级标签的部分。

### 准备升级 {#prepare-for-the-upgrade}

在升级 Istio 之前，我们建议下载新版本的 istioctl，
并运行 `istioctl x precheck` 以确保升级与您的 Ambient 兼容。输出应如下所示：

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

现在，更新 Helm 仓库：

{{< text syntax=bash snip_id=update_helm >}}
$ helm repo update istio
{{< /text >}}

### 选择修订名称 {#choose-a-revision-name}

修订标识了 Istio 控制平面的唯一实例，允许您在单个网格中同时运行控制平面的多个不同版本。

建议修订版本保持不变，也就是说，一旦使用特定修订版本名称安装了控制平面，
就不应修改安装，也不应重用修订版本名称。另一方面，标签是指向修订版本的可变指针。
这使集群操作员能够进行数据平面升级，而无需调整任何工作负载标签，
只需将标签从一个修订版本移动到下一个修订版本即可。所有数据平面将仅连接到一个控制平面，
该控制平面由 `istio.io/rev` 标签（指向修订版本或标签）指定，
如果不存在 `istio.io/rev` 标签，则由默认修订版本指定。
升级数据平面只需通过修改标签或编辑标签来更改它指向的控制平面即可。

由于修订版本是不可变的，我们建议选择与您正在安装的 Istio 版本相对应的修订版本名称，
例如 `1-22-1`。除了选择新的修订版本名称外，您还应该记下当前的修订版本名称。您可以通过运行以下命令找到它：

{{< text syntax=bash snip_id=list_revisions >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/rev,!istio.io/tag' -L istio\.io/rev
$ # Store your revision and new revision in variables:
$ export REVISION=istio-1-22-1
$ export OLD_REVISION=istio-1-21-2
{{< /text >}}

### 升级 Istio Discovery 组件 {#upgrade-the-istio-discovery-component}

Istiod 是管理和配置代理以在 Ambient 网格中路由流量的控制平面组件。

{{< text syntax=bash snip_id=upgrade_istiod >}}
$ helm upgrade istiod istio/istiod -n istio-system
{{< /text >}}

### 升级 ztunnel 组件 {#upgrade-the-ztunnel-component}

ztunnel DaemonSet 是节点代理组件。

{{< warning >}}
由于 Ambient 模式尚未稳定，以下声明不是兼容性保证，后续可能会变更或移除。
在达到稳定状态之前，此组件和/或控制平面可能会有破坏性变更，使得次要版本之间互不兼容。
{{< /warning >}}

只要 ztunnel 的版本差距不超过一个次要版本，1.x 版本总体上与 1.x+1 和 1.x 版本的控制平面兼容，
这意味着必须先升级控制平面，再升级 ztunnel。

{{< warning >}}
就地升级 ztunnel 将短暂中断节点上的所有 Ambient 模式流量。
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
由于 Ambient 模式尚未稳定，以下声明不具备兼容性保证，可能会变更或移除。
在达到稳定状态之前，该组件和/或控制平面可能会受到破坏性变更，从而阻碍次要版本之间的兼容性。
{{< /warning >}}

CNI 1.x 版本通常与 1.x+1 和 1.x 版本的控制平面兼容，
这意味着控制平面必须在 Istio CNI 之前升级，需要它们之前的版本差异在一个次要版本之内。

{{< warning >}}
将 Istio CNI 代理就地升级到兼容版本不会中断已成功添加到一个 Ambient 网格中正在运行 Pod 的网络，
但在节点上 Istio CNI 代理成功升级并完成就绪检查之前，
不会有任何 Ambient 捕获的 Pod 可以在节点上被成功调度（或重新调度）。
如果这是一个重大的中断问题，或者需要对 CNI 升级进行更严格的影响范围控制，则建议使用节点污染和/或节点警戒线。
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_cni >}}
$ helm upgrade istio-cni istio/cni -n istio-system
{{< /text >}}

### 升级 Gateway 组件（可选） {#upgrade-the-gateway-component-optional}

Gateway 组件管理 Ambient 模式边界之间的东西向和南北向数据平面流量，
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

请参阅 [Helm 安装指南](/zh/docs/ambient/install/helm-installation/#uninstall)中的卸载部分。
