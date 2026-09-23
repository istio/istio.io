---
title: 使用 Helm 升级（简易）
description: 使用单个 Chart 通过 Helm 升级 Ambient 模式安装
weight: 5
owner: istio/wg-environments-maintainers
test: yes
draft: true
---

按照本指南使用 [Helm](https://helm.sh/docs/) 升级和配置
Ambient 模式安装。本指南假定您已使用旧版本的 Istio
执行了[使用 Helm 和 Ambient 包装器 Chart 的 Ambient 模式安装](/zh/docs/ambient/install/helm/all-in-one)。

{{< warning >}}
请注意，这些升级说明仅适用于升级使用 Ambient 包装器 Chart 创建的
Helm 安装的情况，如果您通过单独的 Helm 组件 Chart 安装，
请参阅[相关升级文档](/zh/docs/ambient/upgrade/helm)
{{< /warning >}}

## 了解 Ambient 模式升级 {#understanding-ambient-mode-upgrades}

{{< warning >}}
请注意，如果您将所有内容作为此包装器 Chart 的一部分安装，
则只能通过此包装器 Chart 升级或卸载 Ambient - 您不能单独升级或卸载子组件。
{{< /warning >}}

## 先决条件 {#prerequisites}

### 准备升级 {#prepare-for-the-upgrade}

在升级 Istio 之前，我们建议下载新版本的 istioctl，
并运行 `istioctl x precheck` 以确保升级与您的环境兼容。输出应如下所示：

{{< text syntax=bash snip_id=istioctl_precheck >}}
$ istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
{{< /text >}}

现在，更新 Helm 仓库：

{{< text syntax=bash snip_id=update_helm >}}
$ helm repo update istio
{{< /text >}}

### 升级 Istio Ambient 控制平面和数据平面 {#upgrade-the-istio-ambient-control-plane-and-data-plane}

{{< warning >}}
使用包装器 Chart 进行就地升级将短暂中断节点上的所有 Ambient 网格流量，
**即使使用修订版本也是如此**。实际上，中断期是一个非常短的窗口，
主要影响长时间运行的连接。

建议使用节点封锁和蓝/绿节点池来减轻生产升级期间的影响范围风险。
有关详细信息，请参阅 Kubernetes 提供商文档。
{{< /warning >}}

`ambient` Chart 使用由各个组件 Chart 组成的 Helm 包装器
Chart 来升级 Ambient 所需的所有 Istio 数据平面和控制平面组件。

如果您已经定制了 istiod 安装，则可以重用以前升级或安装中的
`values.yaml` 文件以保持设置一致。

{{< text syntax=bash snip_id=upgrade_ambient_aio >}}
$ helm upgrade istio-ambient istio/ambient -n istio-system --wait
{{< /text >}}

### 升级手动部署的网关 Chart（可选） {#upgrade-manually-deployed-gateway-chart-optional}

必须使用 Helm 单独升级[手动部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#manual-deployment)的 `Gateway`：

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-ingress istio/gateway -n istio-ingress
{{< /text >}}
