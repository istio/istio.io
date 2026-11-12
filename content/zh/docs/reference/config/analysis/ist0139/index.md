---
title: InvalidWebhook
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 Sidecar 注入器 Webhook 无效时，会出现此消息。原因有两种：

- 两个或多个 Istio 注入器 Webhook 选择了相同的命名空间和 Pod，这可能导致注入发生两次。
- 注入器 Webhook 引用了一个不存在的控制平面 `Service`。

这些问题通常发生在旧的 Istio 安装或修订版本没有被正确移除的情况下。

## 示例 {#example}

当 Webhook 重叠时，您将收到如下消息：

{{< text plain >}}
Error [IST0139] (MutatingWebhookConfiguration istio-sidecar-injector-canary) Webhook overlaps with others: [istio-sidecar-injector/namespace.sidecar-injector.istio.io]. This may cause injection to occur twice.
{{< /text >}}

或者当控制平面服务缺失时，您将收到如下消息：

{{< text plain >}}
Error [IST0139] (MutatingWebhookConfiguration istio-sidecar-injector-canary) Injector refers to a control plane service that does not exist: istio-system/istiod-canary.
{{< /text >}}

## 如何修复 {#how-to-resolve}

1. 列出 Webhook：

    {{< text bash >}}
    $ kubectl get mutatingwebhookconfigurations
    {{< /text >}}

1. 移除您不再使用的修订版本的 Webhook。如果您使用了修订版本标签，请使用
   [`istioctl tag`](/zh/docs/reference/commands/istioctl/#istioctl-tag) 对其进行管理。

1. 确保每个 Webhook 引用的控制平面 `Service` 存在。
