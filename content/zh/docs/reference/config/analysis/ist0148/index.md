---
title: NamespaceInjectionEnabledByDefault
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 Istio 安装时将 `sidecarInjectorWebhook.enableNamespacesByDefault` 设置为 `true`，
且某个命名空间没有注入标签时，会出现此消息。

使用此设置时，Istio 会向所有没有注入标签的命名空间注入 Sidecar。此消息仅供参考。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Info [IST0148] (Namespace bookinfo) is enabled for Istio injection, as Istio is installed with enableNamespacesByDefault as true.
{{< /text >}}

## 如何修复 {#how-to-resolve}

如果您希望该命名空间中有 Sidecar，则无需执行任何操作。

如果您不希望该命名空间中有 Sidecar，请添加 `istio-injection=disabled` 标签：

{{< text bash >}}
$ kubectl label namespace bookinfo istio-injection=disabled
{{< /text >}}
