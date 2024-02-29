---
title: 发布 Istio 1.21.0
linktitle: 1.21.0
subtitle: 大版本更新
description: Istio 1.21 发布公告。
publishdate: 2024-02-28
release: 1.21.0
aliases:
- /news/announcing-1.21
- /news/announcing-1.21.0
---

We are pleased to announce the release of Istio 1.21. This is the first Istio release of 2024. We would like to thank the entire Istio community for helping get the 1.21.0 release published. We would like to thank the Release Managers for this release, `Aryan Gupta` from Google, `Jianpeng He` from Tetrate, and `Sumit Vij`. The release managers would specially like to thank the Test & Release WG lead Eric Van Norman (IBM) for his help and guidance throughout the release cycle. We would also like to thank the maintainers of the Istio work groups and the broader Istio community for helping us throughout the release process with timely feedback, reviews, community testing and for all your support to help ensure a timely release.
我们很高兴地宣布 Istio 1.21 发布。 这是 2024 年的第一个 Istio 版本。我们要感谢整个 Istio 社区帮助发布 1.21.0 版本。 我们要感谢此版本的发布经理，来自 Google 的“Aryan Gupta”、来自 Tetrate 的“Jianpeng He”和“Sumit Vij”。 发布经理要特别感谢测试和发布工作组领导 Eric Van Norman (IBM) 在整个发布周期中提供的帮助和指导。 我们还要感谢 Istio 工作组和更广泛的 Istio 社区的维护者在整个发布过程中为我们提供的及时反馈、审查、社区测试以及为确保及时发布而提供的所有支持。

{{< relnote >}}

{{< tip >}}
Istio 1.21.0 is officially supported on Kubernetes versions `1.26` to `1.29`.
Kubernetes 版本“1.26”至“1.29”正式支持 Istio 1.21.0。
{{< /tip >}}

## What's new
## 新特性 {#whats-new}

### Easing upgrades with compatibility versions
### 通过兼容版本轻松升级

Istio 1.21 introduces a new concept known as [compatibility versions](/docs/setup/additional-setup/compatibility-versions/).
Istio 1.21 引入了一个称为[兼容性版本](/docs/setup/additional-setup/compatibility-versions/) 的新概念。

Compatibility versions solve a long running problem in Istio: as time passes, changes to the behavior of Istio may be desired to fix bugs, improve integration with the rest of the ecosystem, improve security, or fix surprising behaviors. However, even the smallest behavioral changes can cause issues on upgrade for a project like Istio deployed across thousands of companies in production. At best, this makes upgrades more challenging - at worst, it pushes users to not upgrade at all!
兼容性版本解决了 Istio 中长期存在的问题：随着时间的推移，可能需要更改 Istio 的行为来修复错误、改进与生态系统其他部分的集成、提高安全性或修复令人惊讶的行为。 然而，即使是最小的行为变化也可能会导致像 Istio 这样在数千家生产公司中部署的项目的升级问题。 最好的情况是，这使得升级更具挑战性 - 最坏的情况是，它会迫使用户根本不升级！

With compatibility versions, behavioral changes are decoupled from the Istio version. For example, if you want to upgrade to Istio 1.21 but don't want to adopt the changes introduced yet, simply install with `--set compatibilityVersion=1.20` to retain the 1.20 behavior.
对于兼容性版本，行为更改与 Istio 版本分离。 例如，如果您想升级到 Istio 1.21，但不想采用尚未引入的更改，只需使用 `--set CompatibilityVersion=1.20` 安装即可保留 1.20 行为。

Not sure if you need the old behavior? Not a problem, `istioctl` can tell you!
不确定您是否需要旧的行为？ 没问题，`istioctl` 可以告诉你！

{{< text shell >}}
$ istioctl experimental precheck --from-version {{< istio_previous_version >}}
Warning [IST0168] (DestinationRule default/tls) The configuration "ENABLE_AUTO_SNI"
changed in release 1.20: previously, no SNI would be set; now it will be automatically
set. Or, install with `--set compatibilityVersion=1.20` to retain the old default.

Error: Issues found when checking the cluster. Istio may not be safe to install or upgrade.
See https://istio.io/v1.21/docs/reference/config/analysis for more information about
causes and resolutions.
{{< /text >}}

In this release, the following changes are gated behind compatibility versions:
在此版本中，以下更改被限制在兼容性版本之后：
* Improved `ExternalName` service support
* Automatic SNI for `SIMPLE` TLS origination in `DestinationRule`
* Default-on TLS verification for TLS origination in `DestinationRule`
* 改进了`ExternalName`服务支持
* “DestinationRule”中“SIMPLE” TLS 起源的自动 SNI
* “DestinationRule”中 TLS 来源的默认 TLS 验证

`istioctl experimental precheck` can detect possibly impacted resources for all of these changes. For more info on these changes, see the [Upgrade Notes](/news/releases/1.21.x/announcing-1.21/upgrade-notes).
“istioctl 实验性预检查”可以检测所有这些更改可能受影响的资源。 有关这些更改的更多信息，请参阅[升级说明](/news/releases/1.21.x/announcing-1.21/upgrade-notes)。

Istio joins related projects like [Kubernetes](https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/4330-compatibility-versions/README.md) and [Go](https://go.dev/blog/compat) who have introduced similar features.
Istio 加入了相关项目，例如 [Kubernetes](https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/4330-compatibility-versions/README.md) 和 [Go](https:// go.dev/blog/compat）谁也引入了类似的功能。

### Binary size reductions
### 二进制大小减小

With each release, Istio gets faster, more reliable, and more stable, and this release is no different. In this release, binary sizes have dropped across the board, with roughly 10MB smaller binaries.
随着每个版本的发布，Istio 都会变得更快、更可靠、更稳定，这个版本也不例外。 在此版本中，二进制文件大小全面下降，二进制文件大约缩小了 10MB。

This is especially important with the sidecar, because its deployed alongside every workload. Coming in at 25% smaller, the sidecar image can be pulled faster improving pod startup times. Additionally, the reduced binary size typically results in a 5MB RAM reduction - across many pods, this quickly adds up to cost savings.
这对于 sidecar 来说尤其重要，因为它与每个工作负载一起部署。 Sidecar 镜像体积缩小了 25%，可以更快地拉取，从而缩短 Pod 启动时间。 此外，二进制文件大小的减小通常会导致 RAM 减少 5MB - 在许多 Pod 中，这很快就能节省成本。
