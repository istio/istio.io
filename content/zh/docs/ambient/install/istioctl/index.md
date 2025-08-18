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

## 前提条件 {#prerequisites}

开始之前，请检查以下前提条件：

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

## 安装前生成清单 {#generate-a-manifest-before-installation}

您可以在安装 Istio 之前使用 `manifest generate` 子命令生成清单。
例如，使用以下命令为可以使用 `kubectl` 安装的 `default` 配置文件生成清单：

{{< text syntax=bash snip_id=none >}}
$ istioctl manifest generate > $HOME/generated-manifest.yaml
{{< /text >}}

生成的清单可用于检查具体安装了什么以及跟踪清单随时间的变化。
虽然 `IstioOperator` CR 代表完整的用户配置并且足以跟踪它，
但 `manifest generate` 的输出还捕获了底层 Chart 中可能的变化，因此可用于跟踪实际安装的资源。

{{< tip >}}
您通常用于安装的任何其他标志或自定义值覆盖也应提供给 `istioctl manifest generate` 命令。
{{< /tip >}}

{{< warning >}}
如果尝试使用 `istioctl manifest generate` 安装和管理 Istio，请注意以下事项：

1. 手动创建 Istio 命名空间（默认为 `istio-system`）。

1. Istio 验证默认不会启用。与 `istioctl install` 不同，
   `manifest generate` 命令不会创建 `istiod-default-validator`
   验证 webhook 配置，除非设置了 `values.defaultRevision`：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl manifest generate --set values.defaultRevision=default
    {{< /text >}}

1. 资源可能没有按照与 `istioctl install` 相同的依赖项顺序进行安装。

1. 此方法尚未作为 Istio 版本的一部分进行测试。

1. 虽然 `istioctl install` 会自动从 Kubernetes 上下文中检测特定于环境的设置，
   但 `manifest generate` 无法做到这一点，因为它是离线运行的，
   这可能会导致意外结果。特别是，如果您的 Kubernetes 环境不支持第三方服务帐户令牌，
   则必须确保遵循[这些步骤](/zh/docs/ops/best-practices/security/#configure-third-party-service-account-tokens)。
   建议将 `--cluster-specific` 附加到您的 `istio manifest generate`
   命令以检测目标集群的环境，这会将这些特定于集群的环境设置嵌入到生成的清单中。
   这需要对正在运行的集群进行网络访问。

1. 由于集群中的资源没有按正确的顺序可用，生成的清单的 `kubectl apply` 可能会显示瞬态错误。

1. `istioctl install` 会自动修剪配置更改时应删除的任何资源（例如，如果您删除网关）。
   当您将 `istio manifest generate` 与 `kubectl` 一起使用时，
   不会发生这种情况，必须手动删除这些资源。

{{< /warning >}}
