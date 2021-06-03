---
title: NamespaceMultipleInjectionLabels
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当某个命名空间**同时**定义了新老版本的自动注入标签时，会出现此消息。

## 示例{#example}

当集群有下面的命名空间资源时:

{{< text yaml >}}
apiVersion: v1
kind: Namespace
metadata:
  name: busted
  labels:
    istio-injection: enabled
    istio.io/rev: canary
{{< /text >}}

您会收到这条消息:

{{< text plain >}}
Warning [IST0123] (Namespace busted) The namespace has both new and legacy injection labels. Run 'kubectl label namespace busted istio.io/rev-' or 'kubectl label namespace busted istio-injection-'
{{< /text >}}

在这个样例中, 命名空间 `busted` 同时使用了新老版本的自动注入标签.

## 如何修复{#how-to-resolve}

- 移除 `istio-injection` 标签
- 移除 `istio.io/rev` 标签
