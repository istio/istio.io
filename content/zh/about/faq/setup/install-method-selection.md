---
title: 我应该使用哪种方式安装 Istio？
weight: 10
---

除了简单地[入门](/zh//docs/setup/getting-started)评估版安装之外，
还有其它几种不同的方式安装 Istio，您应该根据您的生产要求来选择安装方式。
下面列出了每种安装方式的优缺点：

1. [使用 istioctl 安装](/zh/docs/setup/install/istioctl/)

    具有高安全性的简单、合格的安装和管理方法，这也是社区推荐的安装方法。

    优点：

    - 完整的配置和运行状态的验证。
    - 使用提供了扩展的配置、自定义选项的 `IstioOperator` API。

    缺点：

    - 需要维护多个 Istio 次要版本的二进制文件。
    - `istioctl` 命令可能根据您的运行环境自动设置相关值，从而能够在不同的
      Kubernetes 环境中进行不同的安装。

1. [使用 istioctl 生成清单](/zh/docs/setup/install/istioctl/#generate-a-manifest-before-installation)

    生成 Kubernetes 的配置清单，并通过 `kubectl apply --prune` 应用到集群中，
    该方法适用于需要严格审查或者增加配置清单的情况。

    优点：

    - 资源是由与 `istioctl install` 中使用相同的 `IstioOperator` API 生成的。
    - 使用提供了扩展的配置、自定义选项的 `IstioOperator` API。

    缺点：

    - 一些在 `istioctl install` 中执行的未完成的检查将不会执行。
    - 与 `istioctl install` 相比，UX 的精简程度较低。
    - 错误报告不如 `istioctl install` 的错误报告详细、全面。

1. [使用 Helm 安装](/zh/docs/setup/install/helm/)

    使用 Helm Chart 可以通过 Helm 的工作流程轻松的完成，并在升级的过程中自动清理资源。

    优点：

    - 使用熟悉、常用的行业标准工具。
    - Helm 原生的版本、升级管理。

    缺点：

    - 相比于 `istioctl install`，检查较少。
    - 一些高权限任务需要更多步骤，并且具有更高的复杂性。

这些安装方式的安装向导在 [Istio 安装页面](/zh/docs/setup/install)中。
