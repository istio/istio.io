---
title: 兼容版本
description: 如何配置“兼容版本”，来将行为变更与版本解耦。
weight: 36
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

Istio 的每个新版本都可能会出现一些有意而为的行为变更。
这些变更可能是为了提高安全性、修复不正确的行为或以其他方式为用户改进 Istio。
一般来说，这些类型的变更仅影响边缘情况。

虽然从长远来看是有益的，但每次行为改变都会在升级过程中带来风险。
从以往经验上看，升级时用户应该通过阅读发布说明来了解任何行为变更并确定它们是否会产生影响；
这可能很乏味并且容易出错。

兼容性版本为用户提供了额外的选项，允许发布版本与行为变更解耦。
例如，您可以安装 Istio {{< istio_version >}}，
但将其配置为类似于 {{< istio_previous_version >}}。

## 使用兼容版本 {#using-compatibility-versions}

要使用兼容版本，只需设置 `compatibilityVersion` 字段即可。

{{< tabset category-name="安装" >}}
{{< tab name="IstioOperator" category-value="iop" >}}

{{< text shell >}}
$ istioctl install --set values.compatibilityVersion={{< istio_previous_version >}}
{{< /text >}}

{{< /tab >}}
{{< tab name="Helm" category-value="helm" >}}

{{< text shell >}}
$ helm install ... --set compatibilityVersion={{< istio_previous_version >}}
{{< /text >}}

{{< /tab >}}
{{< /tabset >}}

## 我什么时候应该使用兼容版本？ {#when-should-i-use-compatibility-versions}

建议仅在发现不兼容时才使用兼容版本，而不是默认使用。
每个兼容性版本只会在几个发布版本中持续，因此最终您将需要迁移到新的行为。
目前，每个兼容性版本都打算保留至少两个版本，尽管这也可能会发生变化。

为了帮助检测是否应使用兼容性版本，可以将
`istioctl x precheck` 与 `--from-version` 标志一同使用。
例如，如果您要从版本 {{< istio_previous_version >}} 升级：

{{< text shell >}}
$ istioctl x precheck --from-version {{< istio_previous_version >}}
Warning [IST0168] (DestinationRule default/tls) The configuration "ENABLE_AUTO_SNI" changed in release 1.20: previously, no SNI would be set; now it will be automatically set. Or, install with `--set compatibility-version=1.20` to retain the old default.
Error: Issues found when checking the cluster. Istio may not be safe to install or upgrade.
See https://istio.io/v1.21/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}
