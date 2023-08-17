---
title: MultipleSidecarsWithoutWorkloadSelectors
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当一个命名空间中超过一个 Sidecar 资源没有定义任何工作负载选择器时，会出现此信息。这种情况会导致行为未被定义。更多信息详见 [Sidecar](/zh/docs/reference/config/networking/sidecar/) 资源参考资料。

解决该问题，需确保每个命名空间有且仅有一个没有定义工作负载选择器的 Sidecar 资源。
