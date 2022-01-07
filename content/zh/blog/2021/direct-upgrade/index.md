---
title: "宣布支持 1.8 到 1.10 的直接升级"
description: "迈向更顺畅的升级过程。"
publishdate: 2021-05-24
attribution: "Mitch Connors (Google), Sam Naser (Google)"
keywords: [更新，Istio，补丁]
---

随着 Service Mesh 技术从尖端转向稳定的基础架构，许多用户表示有兴趣减少升级他们的 Service Mesh 的频率，因为验证新的小版本可能需要很多时间。对于跟不上新版本的用户来说，升级尤其困难，因为 Istio 不支持跨多个小版本的升级。要升级 `1.6.x` 到 `1.8.x`，用户首先必须升级到 `1.7.x` 然后再到 `1.8.x`。

随着 Istio 1.10 的发布，我们宣布支持 Istio Alpha 级别的升级将直接从 `1.8.x` 升级到 `1.10.x`，而不升级到 `1.9.x`。我们希望这将减轻运行 Istio 的运营负担，与我们 2021 年改善 Day 2 Operations 的主题保持一致。

## 从 1.8 升级到 1.10

对于直接升级，我们建议使用金丝雀升级方法，以便在将工作负载切换到新版本之前验证控制平面功能。我们还将在本指南中使用[修订标签](/zh/blog/2021/revision-tags/)，这是对 1.10 中引入的金丝雀升级的改进，因此用户在升级时不必更改命名空间上的标签。

首先，使用版本 `1.10` 或更高版本的 `istioctl`，创建一个版本标签 `stable` ，指向现有的 `1.8` 版本。从现在开始，让我们假设这个修订版本叫做 `1-8-5`：

{{< text bash >}}
$ istioctl x revision tag set stable --revision 1-8-5
{{< /text >}}

如果您的 1.8 安装没有相关的修订，我们可以使用以下命令创建此修订标记：

{{< text bash >}}
$ istioctl x revision tag set stable --revision default
{{< /text >}}

现在，重新用 `istio.io/rev=stable` 标签标记以前标记为 `istio-injection=enabled` 或者 `istio.io/rev=<REVISION>` 的名称空间。下载 Istio 1.10.0 版本并安装带有修订版的新控制平面：

{{< text bash >}}
$ istioctl install --revision 1-10-0 -y
{{< /text >}}

现在评估 `1.10` 版本是否正确出现并且是健康的。一旦对新版本的稳定性感到满意，您可以将版本标签设置为新版本：

{{< text bash >}}
$ istioctl x revision tag set stable --revision 1-10-0 --overwrite
{{< /text >}}

验证修订标签 `stable` 是否指向新的修订：

{{< text bash >}}
$ istioctl x revision tag list
TAG    REVISION NAMESPACES
stable 1-10-0        ...
{{< /text >}}

一旦准备好将现有工作负载转移到新的 1.10 版本，就必须重新启动工作负载，以便 sidecar 代理使用新的控制平面。我们可逐个遍历名空间，并将工作负载滚动到新版本：

{{< text bash >}}
$ kubectl rollout restart deployments -n …
{{< /text >}}

在将工作负载转移到新的 Istio 版本后，注意到了一个问题吗？没问题！因为您用的是金丝雀升级，旧的控制平面仍在运行，我们可以切换回去。

{{< text bash >}}
$ istioctl x revision tag set prod --revision 1-8-5
{{< /text >}}

然后在触发另一次部署后，您的工作负载将返回到旧版本。

我们期待听到您关于直接升级的体验，并期待在未来改进和扩展此功能。
