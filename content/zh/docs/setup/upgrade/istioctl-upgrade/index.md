---
title: 使用 istioctl 命令升级 Istio [实验中]
description: 使用 istioctl 命令来升级或降级 Istio。
weight: 25
keywords: [kubernetes,upgrading]
---

{{< boilerplate experimental-feature-warning >}}

`istioctl experimental upgrade` 命令可为 Istio 进行升级。在进行升级之前，升级命令首先检查已安装的 Istio 是否符合升级要求。此外，如果升级命令检测到 Istio 版本间，配置中有任何默认值发生变化，都将及时提醒用户。

升级命令也可为 Istio 降级。

查看 [`istioctl` 升级参考](/zh/docs/reference/commands/istioctl/#istioctl-experimental-upgrade) 来获取 `istioctl experimental upgrade` 命令的更多功能。

## 升级前置条件{#upgrade-prerequisites}

确保您在开始升级之前满足以下要求：

* 已安装 Istio 1.3.3 或更高版本。

* Istio 是 [使用 {{< istioctl >}}](/zh/docs/setup/install/istioctl/) 命令安装的。

## 升级步骤{#upgrade-steps}

{{< warning >}}
升级过程中可能发生流量中断。为了缩短流量中断时间，请确保每个组件（Citadel 除外）至少运行有两个副本。同时，确保 [`PodDistruptionBudgets`](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) 配置最小可用性为 1。
{{< /warning >}}

本节中的命令应该使用新版本的 `istioctl` 命令运行，可以在下载包的 `bin/` 目录中找到该命令。

1. [下载新版本 Istio](/zh/docs/setup/getting-started/#download) 并切换目录为新版本目录。

1. 查看支持的版本列表，验证 `istoctl` 命令是否支持从当前版本升级

    {{< text bash >}}
    $ istioctl manifest versions
    {{< /text >}}

1. 确保 Kubernetes 配置指向要升级的集群：

    {{< text bash >}}
    $ kubectl config view
    {{< /text >}}

1. 运行以下命令开始升级：

    {{< text bash >}}
    $ istioctl experimental upgrade -f `<your-custom-configuration-file>`
    {{< /text >}}

    `<your-custom-configuration-file>` 是
    [IstioControlPlane API Custom Resource Definition](/zh/docs/setup/install/istioctl/#configure-the-feature-or-component-settings)
    文件，该文件用于自定义安装当前运行版本的 Istio。

    {{< warning >}}
    如果您安装 Istio 时，使用了 `-f` 选项，例如：`istioctl manifest apply -f <IstioControlPlane-custom-resource-definition-file>`，那么 `istioctl upgrade` 命令也必须使用相同的 `-f` 选项参数值。
    {{< /warning >}}

    `istioctl upgrade` 命令不支持 `--set` 选项。因此，如果您的 Istio 是使用 `--set` 选项安装的，请创建一个与配置项等效的配置文件，并将其传递给 `istioctl upgrade` 命令。使用 `-f` 选项来加载配置文件。

    如果省略了 `-f` 选项，Istio 将使用默认配置升级。

    在执行多个步骤的检查后，`istioctl` 将要求您确认是否继续。

1. `istioctl` 将安装新版本的 Istio 控制平面，并显示完成状态。

1. 在使用 `istioctl` 命令升级完成后，必须手动重启包含 Istio sidecar 的 pod 来更新数据平面:

    {{< text bash >}}
    $ kubectl rollout restart deployment
    {{< /text >}}

## 降级前置条件{#downgrade-prerequisites}

确保您在开始升级之前满足以下要求：

* 已安装 Istio 1.4 或更高版本。

* Istio 是 [使用 {{< istioctl >}}](/zh/docs/setup/install/istioctl/) 命令安装的。

* 降级命令 `istioctl` 的版本需要与要降级到的 Istio 版本相对应。例如：要将 Istio 从版本 1.4 降级到 1.3.3，需要使用 1.3.3 版本的 `istioctl` 命令。

## 降级到 Istio 1.4 或更高版本的步骤{#downgrade-to-Istio-1-4-and-higher-versions-steps}

您也可以使用 `istioctl upgrade` 命令降级 Istio 版本。步骤与前一部分提到的升级步骤相同，即使用低版本 Istio 配套的 `istioctl` 命令来降级。降级完成后，Istio 将会恢复到运行 `istioctl experimental upgrade` 命令以前的安装版本。

### 降级到 Istio 1.3.3 或更低版本的步骤{#downgrade-to-Istio-1-3-3-and-lower-versions-steps}

`istioctl experimental upgrade` 命令在 Istio 1.3.3 及更低版本中是不可用的。因此，降级必须使用 `istioctl experimental manifest apply` 命令。

该命令与 `istioctl experimental upgrade` 命令安装的 Istio 控制平面相同，但不会进行任何检查。例如：配置文件中使用的默认值如果发生变化，将不会提醒用户。
