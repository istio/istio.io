---
title: 使用 Helm 升级
description: 使用 Helm 对 Ambient 模式的安装进行升级。
weight: 5
aliases:
  - /zh/docs/ops/ambient/upgrade/helm-upgrade
  - /zh/latest/docs/ops/ambient/upgrade/helm-upgrade
  - /zh/docs/ambient/upgrade/helm
  - /zh/latest/docs/ambient/upgrade/helm
owner: istio/wg-environments-maintainers
test: yes
status: Experimental
---

按照本指南使用 [Helm](https://helm.sh/docs/) 对 Ambient 模式的安装进行升级和配置。
本指南假设您已经使用之前的 Istio 版本执行了
[Helm Ambient 模式安装](/zh/docs/ambient/install/helm/)。

{{< warning >}}
与 Sidecar 模式相比，Ambient 模式支持将应用程序 Pod 移动到升级后的 ztunnel 代理，
而无需强制重启或重新安排正在运行的应用程序 Pod。但是，升级 ztunnel
**将**导致升级节点上所有长寿命 TCP 连接重置，并且 Istio 目前不支持 ztunnel 的金丝雀升级。

建议使用节点封锁和蓝/绿节点池来限制生产升级期间应用程序流量重置的影响范围。
有关详细信息，请参阅 Kubernetes 提供商文档。
{{< /warning >}}

## 了解 Ambient 模式升级 {#understanding-ambient-mode-upgrades}

所有 Istio 升级都涉及升级控制平面、数据平面和 Istio CRD。
由于 Ambient 数据平面分为[两个组件](/zh/docs/ambient/architecture/data-plane)，
即 ztunnel 和 waypoint，因此升级涉及这些组件的单独步骤。
这里简要介绍了升级控制平面和 CRD，但本质上与[在 Sidecar 模式下升级这些组件的过程](/zh/docs/setup/upgrade/canary/)相同。

与 Sidecar 模式类似，网关可以使用[修订标签](/zh/docs/setup/upgrade/canary/#stable-revision-labels)来对
{{< gloss >}}Gateway{{</ gloss >}}）升级，
包括 waypoint 进行细粒度控制，并可通过简单的控件随时回滚。
但是，与 Sidecar 模式不同，ztunnel 作为 DaemonSet（每个节点的代理）运行，
这意味着 ztunnel 升级至少一次会影响整个节点。虽然这在许多情况下是可以接受的，
但具有长 TCP 连接的应用程序可能会中断。在这种情况下，
我们建议在升级给定节点的 ztunnel 之前使用节点封锁和排空。
为简单起见，本文档将演示 ztunnel 的就地升级，这可能涉及短暂的停机时间。

## 前提条件 {#prerequisites}

### 整理您的标签和修订 {#organize-your-tags-and-revisions}

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
例如 `1-22-1`。除了选择新的修订版本名称外，您还应该记下当前的修订版本名称。
您可以通过运行以下命令找到它：

{{< text syntax=bash snip_id=list_revisions >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/rev,!istio.io/tag' -L istio\.io/rev
$ # 将您的修订版本和新的修订版本存到变量中：
$ export REVISION=istio-1-22-1
$ export OLD_REVISION=istio-1-21-2
{{< /text >}}

## 升级控制平面 {#upgrade-the-control-plane}

### 基本组件 {#base-components}

{{< boilerplate crd-upgrade-123 >}}

在部署新版本的控制平面之前，必须升级集群范围的 Custom Resource Definitions（CRD）：

{{< text syntax=bash snip_id=upgrade_crds >}}
$ helm upgrade istio-base istio/base -n istio-system
{{< /text >}}

### istiod 控制平面 {#istiod-control-plane}

[Istiod](/zh/docs/ops/deployment/architecture/#istiod) 控制平面管理和配置在网格内路由流量的代理。
以下命令将在当前实例旁边安装控制平面的新实例，但不会引入任何新代理，也不会接管现有代理的控制权。

如果您已经定制了 istiod 安装，则可以重用以前升级或安装中的 `values.yaml` 文件，以保持控制平面的一致性。

{{< text syntax=bash snip_id=upgrade_istiod >}}
$ helm install istiod-"$REVISION" istio/istiod -n istio-system --set revision="$REVISION" --set profile=ambient --wait
{{< /text >}}

### CNI 节点代理 {#cni-node-agent}

Istio CNI 节点代理负责检测添加到 Ambient 网格的 Pod，
通知 ztunnel 应在添加的 Pod 内建立代理端口，并在 Pod 网络命名空间内配置流量重定向。
它不是数据平面或控制平面的一部分。

1.x 版本的 CNI 与 1.x+1 和 1.x 版本的控制平面兼容。这意味着，
只要控制平面和 Istio CNI 的版本差异在一个小版本以内，就必须在升级控制平面之前对其升级。

{{< warning >}}
将 Istio CNI 节点代理就地升级到兼容版本不会中断已成功添加到 Ambient 网格的正在运行的 Pod 的网络，
但在升级完成且节点上升级的 Istio CNI 代理通过就绪性检查之前，
不会在节点上成功调度（或重新调度）任何环境捕获的 Pod。如果这是一个严重的中断问题，
或者需要对 CNI 升级进行更严格的影响范围控制，建议使用节点污点和/或节点警戒线。
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_cni >}}
$ helm upgrade istio-cni istio/cni -n istio-system
{{< /text >}}

## 升级数据平面 {#upgrade-the-data-plane}

### ztunnel DaemonSet {#ztunnel-daemonset}

{{< gloss >}}ztunnel{{< /gloss >}} DaemonSet 是节点代理组件。
1.x 版本的 ztunnel 与 1.x+1 和 1.x 版本的控制平面兼容。这意味着，
只要控制平面的版本差异在一个小版本以内，就必须在升级 ztunnel 之前升级控制平面。
如果您之前已自定义 ztunnel 安装，则可以重用以前升级或安装中的 `values.yaml` 文件，
以保持{{< gloss "data plane" >}}数据平面{{< /gloss >}}的一致性。

{{< warning >}}
无论使用何种修订版本，就地升级 ztunnel 都会短暂中断节点上的所有 Ambient 网格流量。
实际上，中断时间非常短，主要影响长时间运行的连接。

建议使用节点封锁和蓝/绿节点池来减轻生产升级期间的影响范围风险。
有关详细信息，请参阅 Kubernetes 提供商文档。
{{< /warning >}}

{{< text syntax=bash snip_id=upgrade_ztunnel >}}
$ helm upgrade ztunnel istio/ztunnel -n istio-system --set revision="$REVISION" --wait
{{< /text >}}

### 使用标签升级 waypoint 和网关 {#upgrade-waypoints-and-gateways-using-tags}

如果您遵循了最佳实践，则所有网关、工作负载和命名空间都使用默认修订版本（实际上是名为 `default` 的标签）
或 `istio.io/rev` 标签，其值设置为标签名称。
现在，您可以通过移动它们的标签以指向新版本（一次一个）来将它们全部升级到新版本的 Istio 数据平面。
要列出集群中的所有标签，请运行：

{{< text syntax=bash snip_id=list_tags >}}
$ kubectl get mutatingwebhookconfigurations -l 'istio.io/tag' -L istio\.io/tag,istio\.io/rev
{{< /text >}}

对于每个标签，您可以通过运行以下命令来升级标签，
将 `$MYTAG` 替换为您的标签名称，将 `$REVISION` 替换为您的修订名称：

{{< text syntax=bash snip_id=upgrade_tag >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$REVISION" -n istio-system | kubectl apply -f -
{{< /text >}}

这将升级引用该标签的所有对象，
但使用[手动网关部署模式](/zh/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment)的对象除外
（下文将处理），以及未在 Ambient 模式下使用的 Sidecar。

建议您在升级下一个标签之前密切监控使用升级后的数据平面的应用程序的运行状况。
如果检测到问题，您可以回滚标签，将其重置为指向旧修订版本的名称：

{{< text syntax=bash snip_id=rollback_tag >}}
$ helm template istiod istio/istiod -s templates/revision-tags.yaml --set revisionTags="{$MYTAG}" --set revision="$OLD_REVISION" -n istio-system | kubectl apply -f -
{{< /text >}}

### 升级手动部署的网关（可选） {#upgrade-manually-deployed-gateways-optional}

必须使用 Helm
单独升级[手动部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment)
的 `Gateway`：

{{< text syntax=bash snip_id=upgrade_gateway >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}

## 卸载之前的控制平面 {#uninstall-the-previous-control-plane}

如果您已升级所有数据平面组件以使用新版本的 Istio，
并且认为不需要回滚，则可以通过运行以下命令删除以前版本的控制平面：

{{< text syntax=bash snip_id=none >}}
$ helm delete istiod-"$REVISION" -n istio-system
{{< /text >}}
