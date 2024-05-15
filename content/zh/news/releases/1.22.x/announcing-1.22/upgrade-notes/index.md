---
title: Istio 1.22 升级说明
description: Important changes to consider when upgrading to Istio 1.22.x.升级到 Istio 1.22.x 时要考虑的重要变更。
weight: 20
publishdate: 2024-05-13
---

当您从 Istio 1.21.x 升级到 Istio 1.22.x 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio 1.21.x 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio 1.21.x 用户意料的新特性变更。

## Delta xDS 默认开启 {#delta-xds-on-by-default}

在之前的版本中，Istio 使用“全局状态” xDS 协议来配置 Envoy。在此版本中，
[“Delta”](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds)
xDS 协议被默认启用。

这应该是一个内部实现细节，但由于它控制着 Istio 中的核心配置协议，
因此升级通知非常谨慎。

此更改的预期影响是提高配置分发的性能。这可能会导致 Istiod 和代理中的 CPU
和内存利用率降低，以及两者之间的网络流量减少。请注意，
虽然此版本将**协议**更改为增量式，但 Istio 尚未发送完美的最小增量更新。
然而，已经针对各种关键代码路径进行了优化，并且这一更改使我们能够继续优化。

如果您遇到此更改的意外影响，请在代理中设置 `ISTIO_DELTA_XDS=false`
环境变量并提交 GitHub Issue。

## 默认链路追踪的 `zipkin.istio-system.svc` 被移除 {#default-tracing-to-zipkinistio-systemsvc-removed}

在 Istio 的早期版本中，链路追踪被自动配置为将链路发送到 `zipkin.istio-system.svc`。
此默认设置已被移除；用户将需要明确配置向哪里继续发送链路。

`istioctl x precheck --from-version=1.21` 可以自动检测您是否可能受到此变更的影响。

如果您之前隐式启用了链路追踪，则可以通过执行以下操作之一来启用它：
* 在安装时使用 `--set compatibilityVersion=1.21` 命令。
* 遵循[使用 Telemetry API 配置链路追踪](/zh/docs/tasks/observability/distributed-tracing/telemetry-api/)。

## 功能标志 `ENHANCED_RESOURCE_SCOPING` 的默认值为 true {#default-value-of-the-feature-flag-enhanced_resource_scoping-to-true}

默认情况下 `ENHANCED_RESOURCE_SCOPING` 将被启用。
这意味着 Pilot 将仅处理 `meshConfig.discoverySelectors` 指定范围内的
Istio 自定义资源配置。根 CA 证书分发也会受到影响。

如果不需要，请使用新的 `compatibilityVersion` 功能回退到旧版本行为。

## 带有 `resolution: NONE` 的 `ServiceEntry` 现在遵循 `targetPort` {#serviceentry-with-resolution-none-now-respects-targetport}

具有 `resolution: NONE` 的 `ServiceEntry` 之前忽略了任何
`targetPort` 说明符。在此版本中，现在 `targetPort` 将被遵循。
如果不需要，请设置 `--compatibilityVersion=1.21` 以恢复旧版本行为，或删除 `targetPort` 规范。

## 新的 Ambient 模式 waypoint 附加方法 {#new-ambient-mode-waypoint-attachment-method}

Istio Ambient 模式中的 waypoint 不再使用原始服务帐户或命名空间附件语义。
如果您使用的是命名空间范围的 waypoint，那么基于之前的迁移应该相当简单。
使用适当的 waypoint 标记您的命名空间，它应该以类似的方式运行。
请检查[文档](/zh/docs/ambient/usage/l7-features/#targeting-policies-or-routing-rules)。
如果您使用服务帐户附件，则会有更多需要理解的内容。

在旧的 waypoint 逻辑下，所有类型的流量（无论是发送到服务还是发送到工作负载）都会被类似地处理，
因为没有一种好的方法可以将 waypoint 正确关联到服务。通过新附件，
此限制已得到解决。这包括添加服务寻址流量和工作负载寻址流量之间的区别。
注解服务或类似服务的类型将重定向服务发送到您的 waypoint 的流量。同样，
注解工作负载将重定向工作负载寻址的流量。因此，
了解消费者如何与您的提供者联系并选择与此访问方法相对应的 waypoint 附加方法非常重要。
