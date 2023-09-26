---
title: 状态字段配置
description: 描述“状态”字段在配置工作流程中的作用。
weight: 21
---

{{< warning >}}
此功能处于 Alpha 阶段，请参见 [Istio功能状态](/zh/about/feature-stages/)。
欢迎您的反馈意见 [Istio用户体验讨论](https://discuss.istio.io/c/UX/23)。
当前，此功能仅针对具有单个控制平面版本的单个小规模集群进行了测试。

{{< /warning >}}

Istio 1.6及更高版本使用资源的 `status` 字段提供有关配置更改在网格中传播的信息。
默认情况下，状态为禁用，可以在安装过程中使用以下命令启用状态：

{{< text bash >}}
$ istioctl install --set values.pilot.env.PILOT_ENABLE_STATUS=true --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set values.global.istiod.enableAnalysis=true
{{< /text >}}

`status` 字段包含资源配置的状态，其中包含各种信息性消息，包括：

* 资源的准备情况。
* 有多少个数据平面实例与之关联。
* 工具输出信息，例如 `istioctl analyze`。

例如，`kubectl wait` 命令监视 `status` 字段以确定是否取消阻止配置并继续。
有关更多信息，请参见[等待资源状态以应用配置](/zh/docs/ops/configuration/mesh/config-resource-ready/)。

## 查看 `status` 字段 {#view-the-status-field}

您可以使用 `kubectl get` 查看资源中 `status` 字段的内容。
例如，要查看虚拟服务的状态，请使用以下命令：

{{< text bash >}}
$ kubectl get virtualservice <service-name> -o yaml
{{< /text >}}

在输出结果中，`status` 字段包含多个嵌套字段，
其中包含详细信息关于通过网格传播配置更改的过程。

{{< text yaml >}}
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2019-12-26T22:06:34Z"
    message: "61/122 complete"
    reason: "stillPropagating"
    status: "False"
    type: Reconciled
  - lastProbeTime: null
    lastTransitionTime: "2019-12-26T22:06:56Z"
    message: "1 Error and 1 Warning found. See validationMessages field for details"
    reason: "errorsFound"
    status: "False"
    type: PassedAnalysis
  validationMessages:
  - code: IST0101
    level: Error
    message: 'Referenced gateway not found: "bogus-gateway"'
  - code: IST0102
    level: Warn
    message: 'mTLS not enabled for virtual service'
{{< /text >}}

## `conditions` 字段 {#the-conditions-field}

conditions 字段代表资源的可能状态。
一个 condition 的 `type` 字段可以具有以下值：

* `PassedAnalysis`
* `Reconciled`

当您应用配置时，每种类型的条件都会添加到 `conditions` 字段中。

`Reconciled` 类型条件的 `status` 字段被初始化为 `False`，
以表明资源仍在分配给所有代理的过程中。

当协调完成后，状态将变为 `True`。
根据集群的速度，`status` 字段可能会立即转换为 `True`。

`PassedAnalysis` 类型条件的 `status` 字段的值为 `True` 或 `False`，
取决于 Istio 的后台分析器是否检测到您的配置有问题。
如果为 `False`，则将在 `validationMessages` 字段中详细说明问题。

`PassedAnalysis` 类型条件仅是一个信息字段。
它不会阻止应用无效的配置。该状态可能表示验证失败，但是应用配置成功。
这意味着 Istio 能够设置新配置，但是该配置无效，可能是由于语法错误或类似问题。

## `validationMessages` 字段 {#the-validation-messages-field}

如果验证失败，请检查 `validationMessages` 字段以了解更多信息。
`validationMessages` 字段包含有关验证过程的详细信息，
例如指示 Istio 无法应用配置的错误消息，以及未导致错误的警告或参考消息。

如果类型为 `PassedValidation` 的条件的状态为 `False`，
则会有 `validationMessages` 字段来解释该问题。
当 `PassedValidation` 状态为 `True` 时，可能会出现消息，因为这些消息是信息性消息。

有关验证消息的示例，请参见[配置分析消息](/zh/docs/reference/config/analysis/)。
