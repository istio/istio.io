---
title: IstioProxyVersionMismatch
layout: analysis-message
---

在以下情况，会触发有关 pod 的这条信息：

* 启用 sidecar 自动注入功能（默认启用，除非通过 helm 模版变量 `sidecarInjectorWebhook.enabled` 明确禁用。）
* pod 在启用了 sidecar 注入的命名空间中运行（命名空间带有标签 `istio-injection=enabled`）
* sidecar 上运行的代理版本与自动注入使用的版本不匹配

升级 Istio 控制平面后，通常会出现这种情况；升级 Istio（包括 sidecar 注入）后，必须重新创建 Istio sidecar 的所有正在运行的工作负载，以允许注入新版本的 sidecar。

通过使用常规的部署策略重新部署应用来更新 sidecar 版本是最简单的方式。对于 Kubernetes deployment：

* 如果您使用的是 Kubernetes 1.15 或更高版本，则可以运行 `kubectl rollout restart <my-deployment>` 来重新部署。
* 或者，您可以修改 deployment 的 `template` 字段来强制进行新的部署。通常是通过在 pod 模板定义中添加一个类似 `force-redeploy=<current-timestamp>` 的标签来完成的。
