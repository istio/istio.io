---
title: IneffectivePolicy
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当在 Istio 服务网格中应用的策略没有产生影响时，会出现此消息。
这可能是由于策略错误地匹配了服务网格中的工作负载或命名空间。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Warning [IST0167] (Sidecar ns-ambient/namespace-scoped testdata/sidecar-default-selector.yaml:84) The policy has no
impact: namespace is in ambient mode, the policy has no impact.
{{< /text >}}

或这个：

{{< text plain >}}
Warning [IST0167] (Sidecar ns-ambient/pod-scoped testdata/sidecar-default-selector.yaml:90) The policy has no impact:
selected workload is in ambient mode, the policy has no impact.
{{< /text >}}

这些消息表明 `Sidecar` 资源的目标是处于 Ambient 模式的工作负载或命名空间，
这意味着 `Sidecar` 资源中指定的策略没有任何效果。

## 如何修复 {#how-to-resolve}

要解决这个问题，首先需要检查原因。目前，策略无效的原因如下：

1. `Sidecar` 资源的目标是处于 Ambient 模式的工作负载或命名空间。

要解决此问题，请确保此策略被正确定义或确定此策略是否必要。
如果命名空间或 Pod 是最近被添加到 Ambient 网格中的，您可能忘记了移除不再需要的策略，
或者您可能需要更新策略的目标为正确的工作负载或命名空间。
