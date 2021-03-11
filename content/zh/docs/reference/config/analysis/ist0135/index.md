---
title: DeprecatedAnnotation
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

在 Istio 或 Kubernetes 资源中使用已弃用的 Istio 注解时，会出现该消息。

## 解决方案{#how-to-resolve}

当 Istio 控制平面升级时可能会出现该消息。在升级之前，请移除或使用替代方案替换相关注解。

关于 Istio 的注解列表，请查阅 [Istio 注解文档](/zh/docs/reference/config/annotations/)。

Istio 的版本说明中可能存在将被删除注解的建议和替代方案。
