---
title: IstioProxyVersionMismatch
layout: analysis-message
---

以下情况，会关于pod出现这条消息：

* 启用了sidecar自动注入（除非在安装过程中明确禁用，否则默认启用。）
* pod在启用了sidecar注入的名称空间中运行（命名空间带有标签`istio-injection=enabled`）
* sidecar上运行的代理版本与自动进注入使用的版本不匹配

升级Istio控制平面后，通常会出现这种情况；升级Istio（包括sidecar注入）后，必须重新创建Istio sidecar的所有正在运行的工作负载，以允许注入新版本的sidecar。

解决这个问题，通过使用常规的部署策略重新部署应用来更新sidecar版本。对于Kubernetes deployment：

* 如果您使用的是Kubernetes 1.15或更高版本，则可以运行 `kubectl rollout restart <my-deployment>`来重新部署。
* 或者，您可以修改deployment的`template`字段来强制进行新的部署。通常是通过在pod模板定义中添加一个类似`force-redeploy=<current-timestamp>`的标签来完成的 。
