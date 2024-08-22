---
title: 使用 istioctl 进行安装
description: 使用 istioctl 命令行工具安装支持 Ambient 模式的 Istio。
weight: 10
keywords: [istioctl,ambient]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
按照本指南安装和配置支持 Ambient 模式的 Istio 网格。
如果您是 Istio 新手，只想尝试一下，
请按照[快速入门说明](/zh/docs/ambient/getting-started)进行操作。
{{< /tip >}}

本安装指南使用 [istioctl](/zh/docs/reference/commands/istioctl/)
命令行工具。与其他安装方法一样，`istioctl`
也提供许多自定义选项。此外，它还提供用户输入验证以帮助防止安装错误，
并包含许多安装后分析和配置工具。

使用这些说明，您可以选择 Istio
的内置[配置文件](/zh/docs/setup/additional-setup/config-profiles/)中的任意一个，
然后根据您的特定需求进一步自定义配置。

`istioctl` 命令通过命令行选项进行单独设置，
或传递包含 `IstioOperator` {{<gloss CRD>}}自定义资源{{</gloss>}} 的 YAML 文件，
支持完整的 [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/)。

## 先决条件 {#prerequisites}

开始之前，请检查以下先决条件：

1. [下载 Istio 发行版](/zh/docs/setup/additional-setup/download-istio-release/)。
1. 执行任何必要的[平台特定设置](/zh/docs/ambient/install/platform-prerequisites/)。

## 安装或升级 Kubernetes Gateway API CRD {#install-or-upgrade-the-kubernetes-gateway-api-crds}

{{< boilerplate gateway-api-install-crds >}}

## 使用 Ambient 配置文件安装 Istio {#install-istio-using-the-ambient-profile}

`istioctl` 支持多种[配置文件](/zh/docs/setup/additional-setup/config-profiles/)，
其中包含不同的默认选项，并可根据您的生产需求进行自定义。
`ambient` 配置文件中包含对 Ambient 模式的支持。使用以下命令安装 Istio：

{{< text syntax=bash snip_id=install_ambient >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

此命令在 Kubernetes 配置定义的集群上安装 `ambient` 配置文件。

## 配置和修改配置文件 {#configure-and-modify-profiles}

Istio 的安装 API 记录在
[`IstioOperator` API 参考](/zh/docs/reference/config/istio.operator.v1alpha1/)中。
您可以使用 `istioctl install` 的 `--set`
选项来修改各个安装参数，或者使用 `-f` 指定您自己的配置文件。

有关如何使用和自定义 `istioctl` 安装的完整详细信息，
请参阅 [Sidecar 安装文档](/zh/docs/setup/install/istioctl/)。

## 卸载 Istio {#uninstall-istio}

要从集群中完全卸载 Istio，请运行以下命令：

{{< text syntax=bash snip_id=uninstall >}}
$ istioctl uninstall --purge -y
{{< /text >}}

{{< warning >}}
可选的 `--purge` 标志将删除所有 Istio 资源，
包括可能与其他 Istio 控制平面共享的集群范围资源。
{{< /warning >}}

或者，要仅删除特定的 Istio 控制平面，请运行以下命令：

{{< text syntax=bash snip_id=none >}}
$ istioctl uninstall <your original installation options>
{{< /text >}}

控制平面命名空间（例如 `istio-system`）默认不会被删除。
如果不再需要，请使用以下命令将其删除：

{{< text syntax=bash snip_id=remove_namespace >}}
$ kubectl delete namespace istio-system
{{< /text >}}
