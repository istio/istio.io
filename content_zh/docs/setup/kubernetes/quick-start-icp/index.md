---
title: IBM Cloud Private 快速入门
description: 如何使用 IBM Cloud Private 快速设置 Istio。
weight: 21
keywords: [kubernetes,icp]
---

按说明使用 `Catalog` 模块在 [IBM Cloud Private](https://www.ibm.com/cloud/private) 中安装和运行 Istio。

本指南将安装当前版本的 Istio。

## 前置条件

- 您需要拥有可用的 IBM Cloud Private 集群。否则，您可以按照[安装 IBM Cloud Private-CE](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/installing/install_containers_CE.html)
 创建 IBM Cloud Private 集群。

## 通过应用程序目录部署 Istio

- 登录 **IBM Cloud Private** 控制台。
- 单击导航栏右侧的 `Catalog`。
- 单击搜索框右侧的 `Filter`，然后选择 `ibm-charts` 复选框。
- 单击左侧导航窗口中的 `Operations`。

{{< image width="100%" ratio="50%"
    link="/docs/setup/kubernetes/quick-start-ibm/istio-catalog-1.png"
    caption="IBM Cloud Private - Istio 目录"
    >}}

- 单击右侧面板中的 `ibm-istio`。

{{< image width="100%" ratio="50%"
    link="/docs/setup/kubernetes/quick-start-ibm/istio-catalog-2.png"
    caption="IBM Cloud Private - Istio 目录"
    >}}

- （可选）使用 `CHART VERSION` 下拉菜单更改 Istio 版本。
- 单击 `Configure` 按钮。

{{< image width="100%" ratio="50%"
    link="/docs/setup/kubernetes/quick-start-ibm/istio-installation-1.png"
    caption="IBM Cloud Private - Istio 安装"
    >}}

- 输入 Helm 版本名称（例如 `istio-1.0.3`）并选择 `istio-system` 作为目标名称空间。
- 同意许可条款。
- （可选）单击 `All parameters` 自定义安装参数。
- 单击 `Install` 按钮。

{{< image width="100%" ratio="50%"
    link="/docs/setup/kubernetes/quick-start-ibm/istio-installation-2.png"
    caption="IBM Cloud Private - Istio 安装"
    >}}

安装后，您可以通过在 **Helm Releases** 页面上搜索其版本名称来找到它。

{{< image width="100%" ratio="40%"
    link="/docs/setup/kubernetes/quick-start-ibm/istio-release.png"
    caption="IBM Cloud Private - Istio 安装"
    >}}

## 升级或回滚

- 登录 **IBM Cloud Private** 控制台。
- 单击导航栏左侧的菜单按钮。
- 单击 `Workloads` 并选择 `Helm Releases`。
- 使用其版本名称查找已安装的 Istio。
- 单击 `Action` 链接并选择 `upgrade` 或 `rollback` 。

{{< image width="100%" ratio="50%"
    link="/docs/setup/kubernetes/quick-start-ibm/istio-upgrade-1.png"
    caption="IBM Cloud Private - Istio 升级或回滚"
    >}}

{{< image width="100%" ratio="50%"
    link="/docs/setup/kubernetes/quick-start-ibm/istio-upgrade-2.png"
    caption="IBM Cloud Private - Istio 升级或回滚"
    >}}

## 卸载

- 登录 **IBM Cloud Private** 控制台。
- 单击导航栏左侧的菜单按钮。
- 单击 `Workloads` 并选择 `Helm Releases`。
- 使用其版本名称查找已安装的 Istio。
- 单击 `Action` 链接并选择 `delete`。

{{< image width="100%" ratio="50%"
    link="/docs/setup/kubernetes/quick-start-ibm/istio-deletion.png"
    caption="IBM Cloud Private - Istio 卸载"
    >}}