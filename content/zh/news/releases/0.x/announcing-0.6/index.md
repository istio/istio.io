---
title: Istio 0.6 发布公告
linktitle: 0.6
subtitle: 重大更新
description: Istio 0.6 发布公告。
publishdate: 2018-03-08
release: 0.6.0
aliases:
    - /zh/about/notes/older/0.6
    - /zh/about/notes/0.6/index.html
    - /zh/news/2018/announcing-0.6
    - /zh/news/announcing-0.6
---

除了常规的 bug 修复和性能改进，该版本还新增或更新了以下特性。

{{< relnote >}}

## 网络{#networking}

- **自定义 Envoy 配置**。Pilot 现在支持将自定义 Envoy 配置传递到 proxy。[了解更多](https://github.com/mandarjog/istioluawebhook)

## Mixer 适配器{#mixer-adapters}

- **SolarWinds**。Mixer 现在可以跟 AppOptics 和 Papertrail 交互。[了解更多](/zh/docs/reference/config/policy-and-telemetry/adapters/solarwinds/)

- **Redis 配额**。现在，Mixer 支持了一个用于速率限制跟踪的基于 Redis 的适配器。[了解更多](/zh/docs/reference/config/policy-and-telemetry/adapters/redisquota/)

- **Datadog**。现在，Mixer 提供了一个将度量标准数据传递给 Datadog 代理的适配器。[了解更多](/zh/docs/reference/config/policy-and-telemetry/adapters/datadog/)

## 其它{#other}

- **独立的检查、报告集群**。现在，配置 Envoy 时，具有 Mixer 检查功能的实例和具有 Mixer 报告功能的实例可以来自不同的群集。这在大型部署中可能有用，以更好地扩展 Mixer 实例。

- **监控仪表盘**。Grafana 现在有了初步的 Mixer&Pilot 监控仪表盘。

- **存活及就绪检测**。Istio 组件现在提供了规范的存活及就绪检测支持，以帮助确保网格基础结构的健康。[了解更多](/zh/docs/tasks/security/citadel-config/health-check/)

- **Egress 策略和遥测**。Istio 可以监控由 `EgressRule` 或 External Service 定义的外部服务的流量。也可以将 Mixer 策略应用于该流量。
