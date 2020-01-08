---
title: 变更说明
description: Istio 1.3 发行说明。
weight: 10
aliases:
    - /zh/about/notes/1.3
---

## 安装{#installation}

- **添加** 实验性的[清单和配置文件命令](/zh/docs/setup/install/istioctl/)，用于安装和管理 Istio 控制平面，以便进行评估。

## 流量管理{#traffic-management}

- **添加**。当未根据 Istio 的[约定](/zh/docs/ops/deployment/requirements/)命名端口时，添加了对 HTTP、TCP 出站流量[自动检测协议](/zh/docs/ops/configuration/traffic-management/protocol-selection/)的功能。
- **添加**。为实现双向 TLS 操作，添加了一个模型至 Gateway API。
- **修复**。修复了当服务第一次使用宽容双向 TLS 模式，与 MySQL 和 MongoDB 之类的协议进行网络通信时会出现的问题。
- **改进**。改进了 Envoy 代理的就绪检查。现在会检查 Envoy 的就绪状态。
- **改进**。pod spec 中不再需要的容器端口，所有端口均为[默认捕获](/zh/faq/traffic-management/#controlling-inbound-ports)。
- **改进**。改进了 `EnvoyFilter` API。您现在可以添加或更新所有配置。
- **改进**。使用 Redis 代理时，改进了 Redis 负载均衡，现在默认为 [`MAGLEV`](https://www.envoyproxy.io/docs/envoy/v1.6.0/intro/arch_overview/load_balancing#maglev)。
- **改进**。改进了负载均衡，默认会直接将流量导向[相同的地区和区域](/zh/faq/traffic-management/#controlling-inbound-ports)。
- **改进**。改进了 Pilot 的 CPU 利用率。在特殊部署场景，减少幅度接近 90%。
- **改进**。改进了 `ServiceEntry` API，允许在不同命名空间中使用相同的主机名。
- **改进**。针对自定义 `OutboundTrafficPolicy` 策略，改进了 [Sidecar API](/zh/docs/reference/config/networking/sidecar/#OutboundTrafficPolicy)。

## 安全{#security}

- **添加**。为使用双向 TLS 的服务添加了信任域验证。默认情况下，服务器仅对来自同一信任域的请求进行身份验证。
- **添加**。添加了一些[标签](/zh/docs/ops/configuration/mesh/secret-creation/)，其用于按命名空间控制服务帐户密码的生成。
- **添加**。添加了 SDS 支持，以实现向每个 Istio 控制平面服务传递私钥和证书。
- **添加**。为 Citadel 添加了对[自检](/zh/docs/ops/diagnostic-tools/controlz/)支持。
- **添加**。为 15014 端口的 Citadel Agent 的 `/metrics`  endpoint 添加了指标，用于监控 SDS 服务。
- **添加**。使用 8080 端口上的 `/debug/sds/workload` 和 `/debug/sds/gateway` 向 Citadel Agent 添加了诊断程序。
- **改进**。改进了 ingress gateway，以实现使用 SDS 时[从另一个 secret 加载受信任的 CA 证书](/zh/docs/tasks/traffic-management/ingress/secure-ingress-sds/#configure-a-mutual-TLS-ingress-gateway)。
- **改进**。通过强制使用 [Kubernetes Trustworthy JWT](/zh/blog/2019/trustworthy-jwt-sds) 改进了 SDS 的安全性。
- **改进**。通过统一日志记录模式，改进了 Citadel Agent 日志记录。
- **移除**。移除对 [Kubernetes 1.13 之前版本](/zh/blog/2019/trustworthy-jwt-sds) 的 Istio SDS 支持。
- **移除**。暂时移除与 Vault CA 的集成。SDS 的一些要求导致了本次临时移除，但我们将在之后的版本中重新引入 Vault CA 集成。
- **启用**。默认情况下启用 Envoy JWT 过滤器以提高安全性和可靠性。

## 遥测{#telemetry}

- **添加**。为 Envoy gRPC 添加了访问日志服务 [ALS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/service/accesslog/v2/als.proto#grpc-access-log-service-als) 的支持。
- **添加**。为 Citadel 监控添加了一个 Grafana 仪表盘。
- **添加**。为 sidecar 注入 webhook 监控添加了[指标](/zh/docs/reference/commands/sidecar-injector/#metrics)。
- **添加**。添加了控制平面指标，用于监控 Istio 的配置状态。
- **添加**。添加了流向目标是 `Passthrough` 和 `BlackHole` 集群的流量的遥测报告。
- **添加**。添加了对使用 Prometheus 代理生成服务指标的 alpha 支持。
- **添加**。在 Envoy 节点 metadata 中添加了对环境 metadata 的 alpha 支持。
- **添加**。添加了对代理 Metadata 交换的 alpha 支持。
- **添加**。添加了对 OpenCensus 追踪驱动的 alpha 支持。
- **改进**。通过移除添加服务条目的要求，改进了对外部服务的报告。
- **改进**。改进了网格仪表板，以提供对 Istio 配置状态的监控。
- **改进**。改进了 Pilot 仪表板，以显示更多的关键指标，并能更清楚地识别错误。
- **移除**。移除了不推荐使用的 `Adapter` 和 `Template` 自定义资源（CRD）。
- **弃用**。弃用可用于产生 API 属性的 HTTP API 规范。我们将在 Istio 1.4 中移除对生成 API 属性的支持。

## 策略{#policy}

- **改进**。改进了速率限制的实现，当配额后端不可用时，仍允许通信。

## 配置管理{#configuration-management}

- **修复**。修复了阻止过多 gRPC ping 关闭连接的情况。
- **改进**。改进了 Galley，以避免控制平面升级失败。

## `istioctl`

- **添加**。添加了 [`istioctl` 实验清单](/zh/docs/reference/commands/istioctl/#istioctl-manifest) 来管理新的实验安装清单。
- **添加**。添加了 [`istioctl` 实验配置文件](/zh/docs/reference/commands/istioctl/#istioctl-profile) 来管理新的实验安装配置文件。
- **添加**。添加了[`istioctl experimental metrics`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-metrics)
- **添加**。添加了 [`istioctl experimental describe pod`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-describe-pod)，其用于描述 Istio pod 的配置。
- **添加**。添加了 [`istioctl experimental add-to-mesh`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-add-to-mesh)，其用于将 Kubernetes 服务或虚拟机添加到现有 Istio 服务网格中。
- **添加**。添加了 [`istioctl experimental remove-from-mesh`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-remove-from-mesh)，其用于从已存在的 Istio 服务网格中移除 Kubernetes 服务或虚拟机。
- **提升**。将命令 [`istioctl experimental convert-ingress`](/zh/docs/reference/commands/istioctl/#istioctl-convert-ingress) 提升为 `istioctl convert-ingress`。
- **提升**。将命令 [`istioctl experimental dashboard`](/zh/docs/reference/commands/istioctl/#istioctl-dashboard) 提升为 `istioctl dashboard`。

## 杂项{#miscellaneous}

- **添加**。添加了基于 [distroless](/zh/docs/ops/configuration/security/harden-docker-images/) 基础镜像的新镜像。
- **改进**。改进了 Istio CNI Helm 图表，使其具有与 Istio 一致的版本。
- **改进**。改进了 Kubernetes Job 的行为。当 Job 手动调用 `/quitquitquit` endpoint 时，Kubernetes Job 现在可以正常退出。
