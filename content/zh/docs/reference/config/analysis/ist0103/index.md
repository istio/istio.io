---
title: PodMissingProxy
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 Sidecar 不存在或不能正常工作时，将出现此消息。

最常见的情况是，您开启了自动注入，但之后没有重新启动您的 Pod，导致还未被注入 Sidecar。

为了解决这个问题，请重新启动您的 Pod 以便进行注入。

例如，可以使用以下命令重新启动 Pod：

{{< text bash >}}
$ kubectl rollout restart deployment
{{< /text >}}
