---
title: MultipleSidecarsWithoutWorkloadSelectors
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当一个命名空间中有多个 Sidecar 资源没有定义任何工作负载选择器时，会出现此消息。
这种情况会造成未定义的行为。更多信息详见 [Sidecar](/zh/docs/reference/config/networking/sidecar/) 资源参考资料。

要解决此问题，请确保每个命名空间有且仅有一个没有定义工作负载选择器的 Sidecar 资源。
