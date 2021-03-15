---
title: DeploymentRequiresServiceAssociated
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 Pod 资源没有与任何 Service 资源相关联时会出现该问题。

一个 Pod 即使没有暴露任何端口也必须被至少一个 Kubernetes 的 Service 资源关联。

请查看 [Istio 要求](/zh/docs/ops/deployment/requirements/)来了解更多信息。
