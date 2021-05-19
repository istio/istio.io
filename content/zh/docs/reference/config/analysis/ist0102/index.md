---
title: NamespaceNotInjected
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当命名空间缺少[注解](/zh/docs/reference/config/annotations/)来标记命名空间是否自动注入时会出现此错误，例如 `sidecar.istio.io/inject` 。

例如，您可能看到以下错误：

{{< text plain >}}
Warn [IST0102] (Namespace default) The namespace is not enabled for Istio
injection. Run 'kubectl label namespace default istio-injection=enabled' to
enable it, or 'kubectl label namespace default istio-injection=disabled' to
explicitly mark it as not needing injection Error: Analyzer found issues.
{{< /text >}}

要解决此问题，请您使用注解明确声明您是否希望命名空间被自动注入。例如：

{{< text bash >}}
$ kubectl label namespace <namespace-name> istio-injection=enabled
{{< /text >}}

强烈建议您明确定义需要的注入行为。忘记对命名空间标记注解是导致错误的常见原因。
