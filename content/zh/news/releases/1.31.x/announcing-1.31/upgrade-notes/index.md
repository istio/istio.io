---
title: 升级说明
description: 升级到 Istio 1.31.0 时要考虑的重要变更。
weight: 20
---

当您从 Istio 1.30.x 升级到 Istio 1.31.0 时，需要注意此页面上的变更。
这些说明详细说明了有意破坏与 Istio 1.30.x 向后兼容性的变更。
此外，这些说明还提及了在保持向后兼容性的同时引入新行为的变更。
只有当新行为对 Istio 1.30.x 用户而言是意料之外的，才会包含这些变更。

## GCP 基础设施和托管服务已弃用 {#deprecation-of-gcp-infrastructure-and-hosting}

从 Istio 1.31 开始，我们将不再将工件发布到 `gcr.io/istio-release`、
`registry.istio.io` 和 `istio-release.storage.googleapis.com`。

- Docker 镜像仍可在 Docker Hub 上使用。
- Helm Chart 将在 `blob.istio.io/istio-release/charts` 上提供。
- 其他制品将在 `blob.istio.io/istio-release` 上提供。
- OCI Helm Chart 将在 `ghcr.io/istio/release/charts` 上提供。

我们将进行尖叫测试，我们将在短时间内禁用所有 GCP 托管的工件。

首次尖叫测试将于 UTC 时间 2026 年 9 月 15 日下午 3:00 至 4:00 进行。
第二次尖叫测试将于 UTC 时间 2026 年 10 月 13 日下午 3:00 至 6:00 进行。
第三次尖叫测试将于 UTC 时间 2026 年 11 月 17 日下午 3:00 至晚上 9:00 进行。
第四次也是最后一次尖叫测试将于 2026 年 12 月 8 日下午 3:00 UTC 至 2026 年 12 月 9 日下午 3:00 UTC 进行。

有关更多详细信息，请参阅[此博文](/zh/blog/2026/retirement-of-gcp/)。

## 发送不健康端点的默认行为 {#default-behavior-for-sending-unhealthy-endpoints}

默认情况下，Istio 现在会发送不健康的端点，除非在 `Service` 上配置了 `OutlierDetection.minHealthPercent`。
可以通过将 `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` 设置为 `false` 或使用兼容性配置文件来禁用此功能。

## 现有自动注册的 `WorkloadEntry` 资源需要重新注册或为 HBONE 手动添加标签 {#existing-auto-registered-workloadentry-resources-need-re-registration-or-a-manual-label-for-hbone}

仅当自动创建 `WorkloadEntry` 时，才会应用 HBONE 隧道标签，
因此升级前自动注册的工作负载将继续通过明文进行访问，直到它们重新注册（重新连接新实例）
或将标签 (`networking.istio.io/tunnel=http`) 添加到其现有的 `WorkloadEntry`。

## 已移除 `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` 功能标志 {#pilot_spawn_upstream_span_for_gateway-feature-flag-removed}

环境变量 `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` 已被删除。
它控制的行为（使用遥测 API 时为网关的每个上游请求生成单独的跟踪范围）现在始终启用。
明确将此变量设置为 `false` 以选择退出此行为的用户应注意，选择退出不再可用。

## 在大型 Ambient 网格网络中，WDS 重连请求更大 {#wds-reconnect-requests-are-larger-in-big-ambient-meshes}

重新连接时，ztunnel 会报告其拥有的每个工作负载 (WDS) 资源的名称和版本。
此请求可能会超出 istiod 的默认 4MiB gRPC 接收限制，从而使 ztunnel 处于重新连接循环中，
并出现 `ResourceExhausted: grpc: received message larger than max` 错误。
网格在大约 55,000 个工作负载时可能已经达到限制，因为在此更改之前报告了资源名称；
添加的版本使请求增加了大约三分之一，将触发点降低到大约 40,000 个工作负载（对于长资源名称或许多服务，触发点会更快）。
如果您的网格接近此规模，请提高 istiod 上的 `ISTIO_GPRC_MAXRECVMSGSIZE` — 每 10,000 个工作负载和服务大约预算 1MiB；例如，
`--set Pilot.env.ISTIO_GPRC_MAXRECVMSGSIZE=33554432` (32MiB) 覆盖的网格远远超过 300,000 个资源 — 并在升级后观察 istiod 日志中是否有上述错误。

## XDS `api` 生成器现在需要控制平面身份 {#the-xds-api-generator-now-requires-a-control-plane-identity}

从非系统命名空间连接到 istiod 的 `api` 生成器的自定义 MCP 使用者现在被拒绝。
标准 Sidecar、网关和 ztunnel 流量不受影响。要恢复以前的行为，
请设置 `ENABLE_XDS_API_GENERATOR_AUTH=false`。
