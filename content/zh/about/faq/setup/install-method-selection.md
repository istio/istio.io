---
title: 我应该使用哪种方式安装 Istio ?
weight: 10
---

除了简单地[入门](/zh//docs/setup/getting-started)评估版安装之外，您还可以使用几种不同的方式安装 Istio 。您应该根据您的生产要求来选择安装方式。

下面列出了每种安装方式的优缺点：

1. [使用 istioctl 安装](/zh/docs/setup/install/istioctl/)

    具有高安全性的简单、合格的安装和管理方法。这是社区推荐的安装方法。

    优点:

    - 完整的配置和运行状态的验证。
    - 使用提供了扩展的配置、自定义选项的 `IstioOperator` API。
    - 不需要集群内的高权限 Pod 。通过执行 `istioctl` 命令修改。

    缺点:

    - 需要维护多个 Istio minor 版本的二进制文件。
    - `istioctl` 命令可能根据您的运行环境设置诸如 `JWT_POLICY` 之类的值，从而能够在不同的 Kubernetes 环境中进行不同的安装。

1. [使用 Istio Operator 安装](/zh/docs/setup/install/operator/)

    没有 `istioctl` 二进制文件的简单安安装方式。这是推荐的方法。用于简单升级工作，无需考虑运行集群内的高权限 Controller。

    优点:

    - 具有与 `istioctl install` 相同的 API ，但是通过据群众具有高权限的 Controller Pod 通过完全声明的方式进行操作。
    - 使用提供了扩展的配置、自定义选项的 `IstioOperator` API。
    - 不需要管理多个 `istioctl` 的二进制文件。

    缺点:

    - 在集群内运行高权限的 Controller 会带来安全问题。

1. [使用 istioctl manifest generate 安装](/zh/docs/setup/install/istioctl/#generate-a-manifest-before-installation)

    生成 Kubernetes 的配置清单，并通过 `kubectl apply --prune` 应用到集群中。该方法适用于需要严格审查或者增加配置清单的情况。

    优点:

    - Chart 是由与 `istioctl install` 和 Operator 里使用的相同的 `IstioOperator` API 生成的。
    - 使用提供了扩展的配置、自定义选项的 `IstioOperator` API。

    缺点:

    - 一些在 `istioctl install` 和 Operator 中会进行的检查将不会执行。
    - 与 `istioctl install` 相比，UX 的精简程度较低。
    - 错误报告没有 `istioctl install` 的错误报告详细、全面。

1. [使用 Helm 安装](/zh/docs/setup/install/helm/)

    使用 Helm 的 Chart 可以通过 Helm 的工作流程轻松的完成，并在升级的过程中自动清理资源。

    优点:

    - 使用熟悉、常用的行业标准工具。
    - Helm 原生的版本、升级管理。

    缺点:

    - 相比于 `istioctl install` 和 Operator 相比，检查较少。
    - 一些高权限任务需要更多步骤，并且具有更高的复杂性。

1. [Istio Operator](/zh/docs/setup/install/operator/)

    {{< warning >}}
    不建议在新安装时使用 Operator。虽然 Operator 将继续得到支持，新特性请求将不会被优先化。
    {{< /warning >}}

    Istio 操作符提供了一个安装路径，而不需要 `istioctl` 二进制文件。这可以用于简化升级工作流，其中不需要考虑集群内特权控制器的运行。此方法适用于不需要严格审计或增加输出清单的情况。

    优点:

    - 与 `istioctl install` 相同的 API，但驱动是通过集群中的一个带有完全声明式操作的控制器。
    - `IstioOperator` API 提供了广泛的配置/定制选项。
    - 不需要管理多个 `istioctl` 二进制文件。

    缺点:

    - 集群中运行的高权限控制器存在安全风险。

这些安装方式的安装向导在 [Istio 安装页](/zh/docs/setup/install)中。
