---
title: ConflictingSidecarWorkloadSelectors
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当一个命名空间中，多个 Sidecar 资源选择相同的工作负载实例时会出现此问题。这可能导致未知问题。查看 [Sidecar](/zh/docs/reference/config/networking/sidecar/) 了解更多信息。

要解决此问题，请确保同一个命名空间中的 Sidecar 的负载选择器选择的工作负载实例（例如： Pod）不会重复。
