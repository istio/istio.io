---
title: MisplacedAnnotation
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

此消息发生在当 Istio {{< gloss >}}annotation{{< /gloss >}} 被添加到无效的资源上或资源的错误位置时。

比如，当你创建一个 deployment 并且把 annotation 添加 deployment 上而不是它创建的 pod 上时就会发生。

为了解决此问题，检查你的 annotation 是否被放在了正确的地方然后重试。
