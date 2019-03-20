---
title: IBM Cloud 快速入门
linktitle: IBM Cloud
description: 如何使用 IBM 公有云或 IBM 私有云快速安装 Istio。
weight: 70
keywords: [kubernetes,ibm,icp]
---

参照以下说明，在 IBM Cloud 上安装和运行 Istio。

您可以在 IBM 公有云中使用 [IBM Cloud Kubernetes 服务中托管的 Istio 附加组件](#managed-istio-add-on)
，使用 Helm 在 [IBM 公有云](#ibm-公有云)中安装 Istio，
或者在 [IBM 私有云](#ibm-私有云)中安装 Istio。

## Managed Istio 附加组件{#managed-istio-add-on}

IBM Cloud Kubernetes Service 上提供了 Istio 的无缝安装，Istio 控制平面组件的自动更新和生命周期管理，以及与平台日志记录和监控工具的集成。只需单击一下，您就可以获得所有 Istio 核心组件，其他跟踪，监控和可视化，以及 Bookinfo 示例应用程序的启动和运行。IBM Cloud Kubernetes 服务上的 Istio 作为托管附加组件提供，因此 IBM Cloud 会自动保持所有 Istio 组件的最新状态。

要在 IBM Cloud Public 中安装托管的 Istio 附加组件，请参阅 [IBM Cloud Kubernetes 服务文档](https://cloud.ibm.com/docs/containers?topic=containers-istio)。

## IBM 公有云

在 [IBM 公有云](https://www.ibm.com/cloud/)中，按照[这些说明](/zh/docs/setup/kubernetes/install/helm/)使用 Helm 和 IBM Cloud Kubernetes Service 安装和运行 Istio。

要升级现有 IKS 群集中的 Istio，请按照[升级说明](/zh/docs/setup/kubernetes/upgrade)进行操作。

## IBM 私有云

使用 `Catalog` 模块在 [IBM 私有云](https://www.ibm.com/cloud/private)安装和运行 Istio。

本指南针对 Istio 的当前版本。

### 前置条件 - IBM 私有云

- 你需要有一个可用的 IBM 私有云集群。否则，你可以参照[安装 IBM 私有云](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/installing/install_containers_CE.html)的指引创建一个 IBM 私有云集群。

### 使用 `Catalog` 模块部署 Istio

- 登录到 **IBM 私有云** 控制台。
- 点击导航栏右侧的 `Catalog`。
- 点击搜索框右侧的 `Filter` 并选中 `ibm-charts` 复选框。
- 点击左侧导航窗格的 `Operations`。

{{< image link="./istio-catalog-1.png" caption="IBM 私有云 - Istio 目录" >}}

- 点击右侧面板中的 `ibm-istio`。

{{< image link="./istio-installation-1.png" caption="IBM 私有云 - Istio 目录" >}}

- （可选的）使用 `CHART VERSION` 的下拉功能修改 Istio 版本。
- 点击 `Configure` 按钮。

{{< image link="./istio-installation-1.png" caption="IBM 私有云 - 安装 Istio" >}}

- 输入 Helm 部署实例的名称（例如：`istio-1.0.3`），并选择 `istio-system` 作为目标 namespace。
- 同意许可条款。
- （可选的）点击 `All parameters` 自定义安装参数。
- 点击 `Install` 按钮。

{{< image link="./istio-installation-2.png" caption="IBM 私有云 - 安装 Istio" >}}

安装完成后，你可以在 **Helm Releases** 页通过搜索实例名找到它。

{{< image link="./istio-release.png" caption="IBM 私有云 - 安装 Istio" >}}

### 升级或回滚

- 登录到 **IBM 私有云**控制台。
- 点击导航栏左侧的菜单按钮。
- 点击 `Workloads` 并选中 `Helm Releases`。
- 通过实例名找到已安装的 Istio。
- 点击 `Action` 然后选择 `upgrade` 或 `rollback`。

{{< image link="/docs/setup/kubernetes/install/platform/ibm/istio-upgrade-1.png" caption="IBM 私有云 - Istio 升级或回滚" >}}

{{< image link="/docs/setup/kubernetes/install/platform/ibm/istio-upgrade-2.png" caption="IBM 私有云 - Istio 升级或回滚" >}}

### 卸载

- 登录到 **IBM 私有云**控制台。
- 点击导航栏左侧的菜单按钮。
- 点击 `Workloads` 并选中 `Helm Releases`。
- 通过实例名找到已安装的 Istio。
- 点击 `Action` 并选择 `delete`。

{{< image link="./istio-deletion.png" caption="IBM 私有云 - 卸载 Istio" >}}
