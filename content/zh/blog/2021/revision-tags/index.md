---
title: "使用修订版本和标签安全地升级 Istio 控制平面"
description: 了解如何对网格控制平面执行金丝雀升级。
publishdate: 2021-05-26
attribution: "Christian Posta (Solo.io), Lin Sun (Solo.io), Sam Naser (Google)"
keywords: [upgrades,revisions,operations,canary]
---

像所有安全软件一样，您的服务网格应该保持最新。Istio 社区[每个季度都会发布新版本](/zh/docs/releases/supported-releases/)，通过定期发布补丁以修复错误和[安全漏洞](/zh/blog/2021/patch-tuesdays/)。服务网格的 Operator 将需要多次升级控制平面和数据平面组件。升级时必须小心，因为一个错误可能会影响您的业务流量。Istio 有许多机制可以确保以可控的方式安全地执行升级，并且在 Istio 1.10 中我们进一步改进了这种操作体验。

## 背景{#background}

在 [Istio 1.6](/zh/news/releases/1.6.x/announcing-1.6/change-notes/)中，我们添加了对[使用修订版本按照金丝雀模式升级服务网格的基本支持](/zh/blog/2020/multiple-control-planes/)。使用这种方法，您可以在不影响现有部署的情况下并行运行多个控制平面，并将工作负载从旧控制平面缓慢迁移到新控制平面。

为了支持这种基于修订的升级，Istio 为命名空间引入了一个 `istio.io/rev` 标签。这表明哪个控制平面修订版应该为相应命名空间中的工作负载注入 sidecar 代理。例如，`istio.io/rev=1-9-5` 的标签表示 `1-9-5` 版本的控制平面应该使用 `1-9-5` 的代理为该命名空间中的工作负载注入数据平面。

如果您想升级特定命名空间的数据平面代理，您需要更新 `istio.io/rev` 标签以指向新版本，例如 `istio.io/rev=1-10-0`。手动改变（甚至尝试编排）大量命名空间的标签变化，可能会出现错误，并导致意外的停机。

## 引入修订标签{#introducing-revision-tags}

[在 Istio 1.10 中](/zh/news/releases/1.10.x/announcing-1.10/)，我们改进了基于修订版本的升级，新增了一个名为 _[修订标签](/zh/docs/setup/upgrade/canary/#stable-revision-labels-experimental)_ 的功能。修订标签减少了 Operator 为使用修订而必须进行的更改次数，并安全地升级 Istio 控制平面。您将标签用作命名空间的标签，并为该标签分配修订。这意味着您不必在升级时更改命名空间上的标签，并最大限度地减少手动步骤和配置更改的数量。

例如，您可以定义一个名为 `prod-stable` 的标签，并将其指向控制平面的 `1-9-5` 修订版。您还可以定义另一个名为 `prod-canary` 的标签，指向 `1-10-0` 版本。您的集群中可能有很多重要的命名空间，您可以使用 `istio.io/rev=prod-stable` 来标记这些命名空间。在其他命名空间中，您可能想要测试新版本的 Istio，这时可以给这些命名空间添加 `istio.io/rev=prod-canary` 标签。该标签将间接地把这些命名空间与 `prod-stable` 的 `1-9-5` 修订版和 `prod-canary` 的 `1-10-0` 修订版分别关联起来。

{{< image link="./tags.png" caption="Stable revision tags" >}}

一旦您确定新的控制平面适用于其余的 `prod-stable` 命名空间，您就可以更改标签以指向新的修订版。这使您能够更新所有标记为 `prod-stable` 的命名空间为新的 `1-10-0` 版本，而无需对命名空间上的标签进行任何更改。将标记更改为指向不同的修订版后，您将需要重新启动命名空间中的工作负载。

{{< image link="./tags-updated.png" caption="Updated revision tags" >}}

一旦您对升级到新的控制平面版本感到满意，您就可以删除旧的控制平面。

## 稳定的修订标签正在运行{#stable-revision-tags-in-action}

要为修订版 `1-9-5` 创建一个新的 `prod-stable` 标签，请运行以下命令。

{{< text bash >}}
$ istioctl x revision tag set prod-stable --revision 1-9-5
{{< /text >}}

然后，您可以使用 `istio.io/rev=prod-stable` 标签标记您的命名空间。请注意，如果您安装了Istio的 `default` 修订版（即没有修订版），您首先必须删除标准注入标签：

{{< text bash >}}
$ kubectl label ns istioinaction istio-injection-
$ kubectl label ns istioinaction istio.io/rev=prod-stable
{{< /text >}}

You can list the tags in your mesh with the following:

{{< text bash >}}
$ istioctl x revision tag list

TAG         REVISION NAMESPACES
prod-stable 1-9-5    istioinaction
{{< /text >}}

一个标签是通过一个 `MutatingWebhookConfiguration` 来实现。 您可以验证是否已创建相应的 `MutatingWebhookConfiguration`：

{{< text bash >}}
$ kubectl get MutatingWebhookConfiguration

NAME                             WEBHOOKS   AGE
istio-revision-tag-prod-stable   2          75s
istio-sidecar-injector           1          5m32s
{{< /text >}}

假设您正在尝试采用金丝雀的方式基于 1.10.0 的控制平面升级到新版本。首先，您将使用修订版安装新版本：

{{< text bash >}}
$ istioctl install -y --set profile=minimal --revision 1-10-0
{{< /text >}}

您可以创建一个名为 `prod-canary` 的新标签，并将其指向 `1-10-0` 版本：

{{< text bash >}}
$ istioctl x revision tag set prod-canary --revision 1-10-0
{{< /text >}}

然后相应地标记您的命名空间：

{{< text bash >}}
$ kubectl label ns istioinaction-canary istio.io/rev=prod-canary
{{< /text >}}

如果您列出网格中的标签，您将看到两个稳定的标签指向两个不同的版本：

{{< text bash >}}
$ istioctl x revision tag list

TAG         REVISION NAMESPACES
prod-stable 1-9-5    istioinaction
prod-canary 1-10-0   istioinaction-canary
{{< /text >}}

任何您使用 `istio.io/rev=prod-canary` 标记的命名空间都将被 `prod-canary` 稳定标签名称（在此示例中指向 `1-10-0` 修订版）对应的控制平面所注入。准备好后，您可以使用以下命令将 `prod-stable` 标签切换到新的控制平面：

{{< text bash >}}
$ istioctl x revision tag set prod-stable --revision 1-10-0 --overwrite
{{< /text >}}

每当您切换标签以指向新修订版时，您都需要重新启动任何相应命名空间中的工作负载以获取新修订版的代理。

当 `prod-stable` 和 `prod-canary` 都不再指向旧版本时，可以安全地删除旧版本，如下所示：

{{< text bash >}}
$ istioctl x uninstall --revision 1-9-5
{{< /text >}}

## 结束语{#wrapping-up}

使用修订版可以更安全地对 Istio 控制平面进行金丝雀更改。在具有大量命名空间的大型环境中，您可能更喜欢使用稳定标签，正如我们在本博客中介绍的那样，以删除移动部件的数量并简化您可能围绕更新 Istio 控制平面构建的任何自动化。请查看 [1.10 版本](/zh/news/releases/1.10.x/announcing-1.10/)和[新标签功能](/zh/docs/setup/upgrade/canary/#stable-revision-labels-experimental) 并向我们提供反馈！
