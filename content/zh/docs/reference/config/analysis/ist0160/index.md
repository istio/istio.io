---
title: MultipleTelemetriesWithoutWorkloadSelectors
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当同一命名空间中有多个未定义任何工作负载选择器的 Telemetry 资源时，
会出现 `MultipleTelemetriesWithoutWorkloadSelectors` 消息。
如果没有任何工作负载选择器，这些 Telemetry 资源默认适用于命名空间中的所有工作负载。
拥有多个此类资源可能会导致在确定应将哪个 Telemetry 资源应用于特定 Pod 时产生歧义。

满足以下条件时会生成此消息：

1. 同一命名空间内存在多个 Telemetry 资源。

1. 这些 Telemetry 资源没有定义任何工作负载选择器。

要解决此问题，请查看冲突的 Telemetry 资源并为每个资源定义适当的工作负载选择器。
通过指定工作负载选择器，您可以确保将每个 Telemetry 资源应用于预期的 Pod 集，
从而避免遥测配置中的潜在冲突和歧义。
