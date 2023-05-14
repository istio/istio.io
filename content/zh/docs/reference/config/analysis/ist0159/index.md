---
title: ConflictingTelemetryWorkloadSelectors
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当同一命名空间中的多个 Telemetry 资源具有重叠的工作负载选择器时，
由于无法确定应将哪个 Telemetry 资源应用于特定 Pod，
会出现 `ConflictingTelemetryWorkloadSelectors` 消息。
这可能会导致受影响的工作负载的 Telemetry 配置出现意外。

满足以下条件时会生成此消息：

1. 同一命名空间内存在多个 Telemetry 资源。

1. 这些 Telemetry 资源具有匹配到同一组 Pod 的工作负载选择器。

要解决此问题，请查看冲突的 Telemetry 资源并更新其工作负载选择器，
以确保每个 Pod 仅与一个 Telemetry 资源匹配。
您可能需要调整标签选择器或重新组织 Telemetry 资源以避免选择器产生重叠。
