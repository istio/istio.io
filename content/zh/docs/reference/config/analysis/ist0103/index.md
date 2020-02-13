---
title: PodMissingProxy
layout: analysis-message
---

当 sidecar 不存在或不能正常工作时，将触发此消息。

最常见的情况是，你开启了自动注入，但之后没有重新启动你的 pod，导致 sidecar 丢失。

为了解决这个问题，重新启动你的 pod，然后重试一次。

例如，要重新启动 pod，可以使用以下命令:

{{< text bash >}}
$ kubectl rollout restart deployment
{{< /text >}}
