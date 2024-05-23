---
title: 发布 Istio 1.21.0
linktitle: 1.21.0
subtitle: 大版本更新
description: Istio 1.21 发布公告。
publishdate: 2024-03-13
release: 1.21.0
aliases:
- /zh/news/announcing-1.21
- /zh/news/announcing-1.21.0
---

我们很高兴地宣布 Istio 1.21 发布。这是 2024 年的第一个 Istio 版本。
我们要感谢整个 Istio 社区对 1.21.0 版本发布所作出的帮助。
我们要感谢此版本的几位发布经理，来自 Google 的 `Aryan Gupta`、
来自 Tetrate 的 `Jianpeng He` 及 `Sumit Vij`。
这些发布经理们再次感谢测试和发布工作组负责人 Eric Van Norman（IBM）在整个发布周期中所提供的帮助和指导。
我们还要感谢 Istio 工作组的维护者以及广大 Istio 社区，感谢他们在发布过程中提供及时反馈、
审核和社区测试，以及在确保及时发布方面给予的全力支持。

{{< relnote >}}

{{< tip >}}
Istio 1.21.0 已得到 Kubernetes `1.26` 到 `1.29` 的官方正式支持。
{{< /tip >}}

## 新特性 {#whats-new}

### 通过兼容性版本轻松升级 {#easing-upgrades-with-compatibility-versions}

Istio 1.21 引入了一个被称为[兼容性版本](/zh/docs/setup/additional-setup/compatibility-versions/)的新概念。

兼容性版本解决了 Istio 长期以来的一个问题：
随着时间的推移，对于错误修复、改进与生态系统其他部分的集成、
提高安全性或修复非预期行为，可能都需要对 Istio 的行为做出变更。
然而，即使是最小的行为变更也可能会导致像 Istio 这样在数千家公司生产环境中部署的项目出现升级问题。
最好的情况是，这仅仅使得升级更具挑战性；而最坏的情况是，它会使用户根本无法升级！

若采用兼容性版本，行为变更将与 Istio 版本分离。
例如，如果您想升级到 Istio 1.21，但不想采用尚未引入的变更，
只需使用 `--set CompatibilityVersion=1.20` 进行安装即可保留 1.20 中的行为。

并不确定您是否需要旧的行为？也没问题，`istioctl` 可以告诉您！

{{< text shell >}}
$ istioctl experimental precheck --from-version {{< istio_previous_version >}}
Warning [IST0168] (DestinationRule default/tls) The configuration "ENABLE_AUTO_SNI"
changed in release 1.20: previously, no SNI would be set; now it will be automatically
set. Or, install with `--set compatibilityVersion=1.20` to retain the old default.

Error: Issues found when checking the cluster. Istio may not be safe to install or upgrade.
See https://istio.io/v1.21/docs/reference/config/analysis for more information about
causes and resolutions.
{{< /text >}}

在该版本中，下列变更被限制在兼容性版本之后：
* 对 `ExternalName` 服务的改进支持
* `DestinationRule` 中 `SIMPLE` TLS 源的自动 SNI
* `DestinationRule` 中 TLS 源的默认 TLS 验证

`istioctl experimental precheck` 可以检测所有这些变更可能影响的资源。
有关这些更改的更多信息，请参阅[升级说明](/zh/news/releases/1.21.x/announcing-1.21/upgrade-notes)。

Istio 加入了 [Kubernetes](https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/4330-compatibility-versions/README.md)
和 [Go](https://go.dev/blog/compat) 等引入了类似功能的相关项目。

### 缩减二进制大小 {#binary-size-reductions}

随着每个版本的发布，Istio 都会变得更快、更可靠、更稳定，在此版本中也不例外。
在该版本中，二进制文件大小全面下降，二进制文件大约缩小了 10MB。

这对于 Sidecar 来说尤其重要，因为它与每个工作负载一同部署。
Sidecar 镜像体积缩小了 25%，可以更快地拉取，从而缩短 Pod 启动时间。
此外，二进制文件的减小通常会使得 RAM 减少 5MB - 在多个 Pod 中，这些叠加可以快速节省成本。

### 支持 Ambient 模式下的所有 CNI {#support-for-all-cnis-in-ambient-mode}

我们新的 [Ambient 模式](/zh/blog/2022/introducing-ambient-mesh/)现在适用于所有 Kubernetes 平台和 CNI 实现。
Ambient 模式已经使用 GKE、AKS 和 EKS 及其提供的所有 CNI 实现、
Calico 和 Cilium 等第 3 方 CNI 以及 OpenShift 等平台进行了测试，
所有这些都取得了可靠的结果。
[最近的一篇博客文章](/zh/blog/2024/inpod-traffic-redirection-ambient/)描述了此修复背后的工程挑战。

Ambient 模式的目标是在即将发布的 Istio 1.22 中迁移到 Beta。

## 升级到 1.21 {#upgrading-to-1-21}

我们希望了解您升级到 Istio 1.21 的体验。
您可以在我们的 [Slack 工作区](https://slack.istio.io/)的 #release-1.21 频道中提供反馈。

您想直接为 Istio 做出贡献吗？
查找并加入我们的其中一个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)并帮助我们改进。
