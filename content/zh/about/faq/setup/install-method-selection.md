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

1. [使用 Helm 进行安装](/zh/docs/setup/install/helm/)

    允许轻松与基于 Helm 的工作流程集成并在升级期间自动进行资源修剪。

    优点：

    - 使用行业标准工具的熟悉方法。
    - Helm 原生发布和升级管理。

    缺点：

    - 与 `istioctl install` 相比，检查和验证更少。
    - 某些管理任务需要更多步骤并且复杂性更高。

1. 应用生成的 Kubernetes 清单

    - [使用 `istioctl` 生成 Kubernetes 清单](/zh/docs/setup/install/istioctl/#generate-a-manifest-before-installation)
    - [使用 `helm` 生成 Kubernetes 清单](/zh/docs/setup/install/helm/#generate-a-manifest-before-installation)

    此方法适用于需要严格审核或扩充输出清单，或存在第三方工具限制的情况。

    优点：

    - 更容易与未使用 `helm` 或 `istioctl` 的工具集成。
    - 除了 `kubectl` 之外，不需要其他安装工具。

    缺点：

    - 不执行上述任一方法支持的安装时检查、环境检测或验证。
    - 不支持安装管理或升级功能。
    - 用户体验不够精简。
    - 安装过程中的错误报告不够完善。

这些安装方式的安装向导在 [Istio 安装页面](/zh/docs/setup/install)中。
