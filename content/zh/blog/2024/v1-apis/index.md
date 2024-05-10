---
title: "引入 Istio API v1 版"
description: 为了体现 Istio 功能的稳定性，我们的网络、安全和 Telemetry API 在 1.22 中升级为 v1 版。
publishdate: 2024-05-13
attribution: Whitney Griffith - Microsoft; Translated by Wilson Wu (DaoCloud)
keywords: [istio, traffic, security, telemetry, API]
target_release: 1.22
---

Istio 提供了至关重要的[网络](/zh/docs/reference/config/networking/)、
[安全](/zh/docs/reference/config/security/)和 [Telemetry](/zh/docs/reference/config/telemetry/) API
确保服务网格内服务的强大安全性、无缝连接和有效可观测性。
这些 API 被应用于全球数千个集群，保护并增强关键基础设施。

这些 API 提供的大多数功能经过了一段时间已经[被认为是稳定的](/zh/docs/releases/feature-stages/)，
但 API 版本仍保持在 `v1beta1`。为了体现这些资源的稳定性、采用率和价值，
Istio 社区决定在 Istio 1.22 中将这些 API 升级到 `v1`。

在 Istio 1.22 中，我们很高兴地宣布，我们已共同努力将以下 API 升级到 `v1`：
* [Destination Rule](/zh/docs/reference/config/networking/destination-rule/)
* [Gateway](/zh/docs/reference/config/networking/gateway/)
* [Service Entry](/zh/docs/reference/config/networking/service-entry/)
* [Sidecar](/zh/docs/reference/config/networking/sidecar/)
* [Virtual Service](/zh/docs/reference/config/networking/virtual-service/)
* [Workload Entry](/zh/docs/reference/config/networking/workload-entry/)
* [Workload Group](/zh/docs/reference/config/networking/workload-group/)
* [Telemetry API](/zh/docs/reference/config/telemetry/)*
* [Peer Authentication](/zh/docs/reference/config/security/peer_authentication/)

## 功能稳定性和 API 版本 {#feature-stability-and-api-versions}

声明式 API，例如 Kubernetes 和 Istio 使用的 API，
将资源的**描述**与对其进行操作的**实现**解耦。

[Istio 的功能阶段定义](/zh/docs/releases/feature-stages/)描述了一个稳定的功能 - 被认为已准备好用于任何规模的生产使用，
并附带正式的弃用政策 - 相关 API 应与 `v1` 版本相匹配。
我们现在正在兑现这一承诺，我们的 API 版本与我们的功能稳定性相匹配，
包括已经稳定了一段时间的功能以及在此版本中新指定为稳定的功能。

尽管目前没有计划停止对之前的 `v1beta1` 和 `v1alpha1` API 版本的支持，
但鼓励用户通过更新现有的 YAML 文件来手动过渡到使用 `v1` API。

## Telemetry API {#telemetry-api}

`v1` Telemetry API 是唯一一个与之前的 API 版本相比有所更改升级的 API。
以下 `v1alpha1` 功能未被升级至 `v1`：
* `metrics.reportingInterval`
    * 报告间隔允许配置调用指标报告之间的时间。
      目前它仅支持 TCP 指标，但我们将来可能会将其用于持续时间较长的 HTTP 流。

      **目前，Istio 缺乏使用数据来支持此功能的需求。**
* `accessLogging.filter`
    * 如果指定，此过滤器将用于选择特定的请求/连接进行日志记录。

      **此功能基于 Envoy 中相对较新的功能，Istio 需要进一步开发用例和实现，然后才能将其升级到 `v1`。**
* `tracing.useRequestIdForTraceSampling`
    * 该值默认为 true。该请求 ID 的格式是 Envoy 特定的，
      如果首先接收用户流量的代理生成的请求 ID 不是 Envoy 特定的，
      Envoy 将中断链路，因为它无法解释该请求 ID。通过将此值设置为 false，我们可以阻止
      [Envoy 根据请求 ID 进行采样](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing#trace-context-propagation)。

      **没有强大的用例支持可以通过 Telemetry API 对其进行配置。**

请通过[在 GitHub 上创建 Issue](https://github.com/istio/istio/issues)
分享对这些内容的任何反馈。

## Istio CRD 概述 {#overview-of-istio-crds}

这是被支持 API 版本的完整列表：

| 类别 | API | 版本 |
| ---------|-----|----------|
| 网络 | [Destination Rule](/zh/docs/reference/config/networking/destination-rule/) |  `v1`, `v1beta1`, `v1alpha3` |
| | Istio [Gateway](/zh/docs/reference/config/networking/gateway/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Service Entry](/zh/docs/reference/config/networking/service-entry/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Sidecar](/zh/docs/reference/config/networking/sidecar/) scope |  `v1`, `v1beta1`, `v1alpha3` |
| | [Virtual Service](/zh/docs/reference/config/networking/virtual-service/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Workload Entry](/zh/docs/reference/config/networking/workload-entry/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Workload Group](/zh/docs/reference/config/networking/workload-group/) |  `v1`, `v1beta1`, `v1alpha3` |
| | [Proxy Config](/zh/docs/reference/config/networking/proxy-config/) |  `v1beta1` |
| | [Envoy Filter](/zh/docs/reference/config/networking/envoy-filter/) |  `v1alpha3` |
| 安全 | [Authorization Policy](/zh/docs/reference/config/security/authorization-policy/) |  `v1`, `v1beta1` |
| | [Peer Authentication](/zh/docs/reference/config/security/peer_authentication/) |  `v1`, `v1beta1` |
| | [Request Authentication](/zh/docs/reference/config/security/request_authentication/) |  `v1`, `v1beta1` |
| Telemetry | [Telemetry](/zh/docs/reference/config/telemetry/) |  `v1`, `v1alpha1` |
| 扩展 | [Wasm Plugin](/zh/docs/reference/config/proxy_extensions/wasm-plugin/) |  `v1alpha1` |

还可以[使用 Kubernetes Gateway API](/zh/docs/setup/additional-setup/getting-started/) 配置 Istio。

## 使用 `v1` 版本的 Istio API {#using-the-v1-istio-apis}

Istio 中的一些 API 仍在被积极开发中，并且可能会在版本之间发生潜在变化。
例如，Envoy Filter、Proxy Config 和 Wasm Plugin API。

此外，由于 [CRD 版本控制](https://kubernetes.io/zh-cn/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/)的限制，
Istio 在 API 的所有版本中维护严格相同的模型。
因此，即使存在 `v1` Telemetry API，在声明 `v1` Telemetry API
资源时仍然可以使用[上述](#telemetry-api)提到的三个 `v1alpha1` 字段。

对于风险敏感的环境，我们添加了**稳定验证策略**，
[验证准入策略](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/validating-admission-policy/)可以确保只有 `v1` API 和字段被在 Istio API 中使用。

在新环境中，在安装 Istio 时选择稳定的验证策略将保证将来创建或更新的所有自定义资源都是 `v1` 并且仅包含 `v1` 功能。

如果该策略部署到现有 Istio 安装中，
而该安装中的自定义资源不符合该策略，则唯一允许的操作是删除该资源或删除违规字段的使用。

使用稳定验证策略安装 Istio：

{{< text bash >}}
$ helm install istio-base -n istio-system --set experimental.stableValidationPolicy=true
{{< /text >}}

要在使用策略安装 Istio 时设置特定修订版：

{{< text bash >}}
$ helm install istio-base -n istio-system --set experimental.stableValidationPolicy=true -set revision=x
{{< /text >}}

此功能与 [Kubernetes 1.30](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/validating-admission-policy/)
及更高版本兼容。验证是使用 [CEL](https://github.com/google/cel-spec)
表达式创建的，用户可以根据自己的特定需求修改验证。

## 总结 {#summary}

Istio 项目致力于提供稳定的 API 和功能，这对于服务网格的成功运行至关重要。
我们很乐意收到您的反馈，以帮助指导我们做出正确的决定，
因为我们将继续完善我们功能的相关用例和稳定性障碍。
请通过创建 [Issue](https://github.com/istio/istio/issues)、
在相关[Istio Slack 频道](https://slack.istio.io/)中发帖或参加我们每周[工作组会议](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings)来分享您的反馈。
