---
title: MisplacedAnnotation
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 Istio {{< gloss >}}annotation{{< /gloss >}}
被添加到无效的资源上或目标资源的位置错误时，将出现此错误消息。

比如，当您创建一个 Deployment 并且把注解添加 Deployment
上而不是它创建的 Pod 上时就会出现此消息。

为了解决此问题，请检查您的注解是否被放在了正确的地方，然后重试。
