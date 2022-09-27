---
title: 原地升级
description: 原地升级和回退。
weight: 20
keywords: [kubernetes,upgrading,in-place]
owner: istio/wg-environments-maintainers
test: no
---

通过 `istioctl upgrade` 命令对 Istio 进行升级。在开始升级之前，该命令会自动检查 Istio 的安装是否满足升级需求。同时，如果该命令检测到 Istio 与当前版本的配置文件默认值存在变动时，会警告用户。

{{< tip >}}
[金丝雀升级](/zh/docs/setup/upgrade/canary/)比原地升级更安全，是推荐的升级方法。
{{< /tip >}}

Istio 的升级指令同样可以执行回退操作。

阅读 [`istioctl` 升级参考](/zh/docs/reference/commands/istioctl/#istioctl-upgrade)来了解 `istoictl upgrade` 指令提供的全部参数。

{{< warning >}}
`istioctl upgrade` 用于原地升级，并且与使用 `--revision` 参数进行的安装不兼容。此类安装的升级将失败，并显示错误。
{{< /warning >}}

## 升级的前置条件{#upgrade-prerequisites}

在您执行升级之前，请检查以下条件：

* 安装的 Istio 版本与升级的目标版本之间至最多差一个 minor 版本。例如，如果要升级到1.7.x版本，需要至少1.6.0或更高版本。

* 您是[使用 {{< istioctl >}} 安装](/zh/docs/setup/install/istioctl/)的 Istio.

## 升级步骤{#upgrade-steps}

{{< warning >}}
在升级过程中，服务可能会发生流量中断。为了最大程度的减少中断，请确保 `istiod` 至少有两个副本正在运行。另外，请确保 [`PodDisruptionBudgets`](https://kubernetes.io/zh-cn/docs/tasks/run-application/configure-pdb/) 配置的最低可用性为 1。
{{< /warning >}}

本节所使用的所有命令应该使用新版本的 `istioctl` 运行，可执行文件可以在下载包的 `bin/` 目录下找到。

1. [下载新版 Istio](/zh/docs/setup/getting-started/#download)，并且切换到该目录。

1. 确保您的 Kubernetes 配置指向的是要升级的集群：

    {{< text bash >}}
    $ kubectl config view
    {{< /text >}}

1. 确保此升级与您的环境兼容。

    {{< text bash >}}
    $ istioctl x precheck
    ✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
    To get started, check out https://istio.io/latest/docs/setup/getting-started/
    {{< /text >}}

1. 通过执行以下指令开始升级：

    {{< text bash >}}
    $ istioctl upgrade
    {{< /text >}}

    {{< warning >}}
    如果您使用 `-f` 参数安装 Istio，那么您必须提供同样的 `-f` 参数值来执行 `istioctl upgrade` 指令。例如：`istioctl install -f <IstioOperator-custom-resource-definition-file>`。
    {{< /warning >}}

    如果您使用了 `--set` 参数安装 Istio，请确保使用同样的 `--set` 参数值来升级，否则升级过程将会还原 `--set` 的参数。如果在生产环境，建议您使用配置文件而不是 `--set` 参数进行安装。

    如果您没有设置 `-f` 参数，Istio 将会使用默认 profile 升级。

    执行几次检查后，`istioctl` 将会询问您是否需要继续升级。

1. `istioctl` 会将 Istio 的控制平面和网关升级到新版本，并显示完成状态。

1. 在 `istioctl` 完成升级后，您必须通过重启 Pod 的 Sidecar 来手动更新 Istio 的数据平面。

    {{< text bash >}}
    $ kubectl rollout restart deployment
    {{< /text >}}

## 版本回退的前置条件{#downgrade-prerequisites}

在您开始进行版本回退的时候，请检查以下前置条件：

* 您是[使用 {{< istioctl >}} 安装](/zh/docs/setup/install/istioctl/)的 Istio.

* 安装的 Istio 版本与回退的目标版本之间至最多差一个 minor 版本。例如，您可以从 1.7.x 版本降级到最小 1.6.0 版本。

* 回退需要使用回退目标版本的二进制 `istioctl` 指令完成。例如，如果您要从Istio 1.7 降级到 1.6.5，请使用 1.6.5 的 `istioctl`。

## 回退版本操作步骤{#steps-to-downgrade-to-a-lower-Istio-version}

您可以使用 `istioctl upgrade` 来回退 Istio 到低版本。回退步骤与上一步中所述的升级过程相同，不过需要使用较低版本（例如 1.6.5) 的 `istioctl` 二进制文件。完成后，Istio 将会更新到低版本。

另外，`istioctl install` 可用于安装旧版 `istio` 的控制平面，但是不建议这样使用，因为这个过程不会执行任何检查。例如，用于配置集群的配置文件的某些默认值可能会发生变动，但是不会发出任何警告。
