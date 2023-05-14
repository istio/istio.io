---
title: PodsIstioProxyImageMismatchInNamespace
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当命名空间开启了自动注入 Sidecar，
但命名空间中的某些 Pod 没有正确的完成 Sidecar 注入时，会出现此消息。

如果命名空间中的任何 Pod 未运行正确版本的 Sidecar，此消息将被报告。
这些 Pod 的名称将被列在消息的详情中。

这样的结果通常会在升级 Istio 控制平面的时候触发；
当升级 Istio（包括 Sidecar 注入器）后，
所有运行中带有 Istio Sidecar 的工作负载必须被重新创建，以便注入新版本的 Sidecar
使得新版本 Sidecar 被允许注入。

要解决该问题，请使用正常滚动策略重新部署应用程序来更新其 Sidecar 版本。
对于 Kubernetes Deployment：

* 如果您正在使用 Kubernetes 1.15 或更高版本，
您可以运行 `kubectl rollout restart <my-deployment>` 来触发一次新的滚动操作。

* 或者，您可以修改 Deployment 的 'template' 字段来强制执行一次新的滚动操作。
该操作通常会通过在 Pod 定义模板中添加一个如同 `force-redeploy=<current-timestamp>` 的标签来完成。
