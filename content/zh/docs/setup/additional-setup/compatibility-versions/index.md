---
title: Compatibility Versions 兼容版本
description: How to configure "compatibility versions", to decouple behavioral changes from releases. 如何配置“兼容版本”，以将行为更改与版本分离。
weight: 36
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

With each new version of Istio, there may be some intentional behavioral changes. These can be to improve security, fix incorrect behavior, or otherwise improve Istio for users. Generally, these types of changes impact only edge cases.
Istio 的每个新版本都可能会出现一些有意的行为变化。 这些可以是为了提高安全性、修复不正确的行为或以其他方式为用户改进 Istio。 一般来说，这些类型的更改仅影响边缘情况。

While beneficial on the long term, each behavioral change introduces risk during upgrades. Historically, when upgrading users should read the release notes for any behavioral changes and determine if they are impacted; this can be tedious and error prone.
虽然从长远来看是有益的，但每次行为改变都会在升级过程中带来风险。 从历史上看，升级时用户应该阅读发行说明以了解任何行为变化并确定它们是否受到影响； 这可能很乏味并且容易出错。

Compatibility versions give users an additional option, allowing release versions to be decoupled from behavioral changes. For instance, you can install Istio {{< istio_version >}}, but configure it to behave like {{< istio_previous_version >}}.
兼容性版本为用户提供了额外的选项，允许发布版本与行为更改解耦。 例如，您可以安装 Istio {{< istio_version >}}，但将其配置为类似于 {{< istio_previous_version >}}。

## Using compatibility versions
## 使用兼容版本

To use a compatibility version, simply set the `compatibilityVersion` field.
要使用兼容版本，只需设置“compatibilityVersion”字段即可。

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

## When should I use compatibility versions?
## 我什么时候应该使用兼容版本？

Compatibility versions are recommended to be used only when an incompatibility is found, rather than as the default. Each compatibility version will only persist for a few releases, so eventually you will need to migrate to the new behavior. Currently, each compatibility version is intended to remain for at least two versions, though this is subject to change.
建议仅在发现不兼容时才使用兼容版本，而不是默认使用。 每个兼容性版本只会持续几个版本，因此最终您将需要迁移到新的行为。 目前，每个兼容性版本都打算保留至少两个版本，尽管这可能会发生变化。

To help detect if a compatibility version should be used, `istioctl x precheck` can be used with the `--from-version` flag. For instance, if you are upgrading from version {{< istio_previous_version >}}:
为了帮助检测是否应使用兼容性版本，可以将“istioctl x precheck”与“--from-version”标志一起使用。 例如，如果您要从版本 {{< istio_previous_version >}} 升级：

{{< text shell >}}
$ istioctl x precheck --from-version {{< istio_previous_version >}}
Warning [IST0168] (DestinationRule default/tls) The configuration "ENABLE_AUTO_SNI" changed in release 1.20: previously, no SNI would be set; now it will be automatically set. Or, install with `--set compatibility-version=1.20` to retain the old default.
Error: Issues found when checking the cluster. Istio may not be safe to install or upgrade.
See https://istio.io/v1.21/docs/reference/config/analysis for more information about causes and resolutions.
{{< /text >}}
