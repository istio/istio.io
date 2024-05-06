---
title: NamespaceNotInjected
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当命名空间缺少 `istio-injection` 标签（用于启用/禁用 Sidecar 注入）或
`istio.io/rev` 标签（用于指定sidecar的Istio控制平面修订版）或者
`.values.sidecarInjectorWebhook.enableNamespacesByDefault`
未被启用时，会出现此消息。

例如，您可能看到以下错误：

{{< text plain >}}
Warn [IST0102] (Namespace default) The namespace is not enabled for Istio
injection. Run 'kubectl label namespace default istio-injection=enabled' to
enable it, or 'kubectl label namespace default istio-injection=disabled' to
explicitly mark it as not needing injection Error: Analyzer found issues.
{{< /text >}}

要解决此问题，请您使用标签明确声明您是否希望命名空间被自动注入。例如：

{{< text bash >}}
$ kubectl label namespace <namespace-name> istio-injection=enabled
{{< /text >}}

强烈建议您明确定义需要的注入行为。忘记对命名空间打标签是导致错误的常见原因。
