---
title: Istio 1.0.3
publishdate: 2018-10-30
icon: notes
---

本次发布中针对社区在使用 Istio 1.0.2 的过程中发现的严重问题进行了修补。下文将陈述 Istio 1.0.2 和 Istio 1.0.3 之间的差异。

{{< relnote_links >}}

## 行为变化

- [验证 Webhook](/zh/help/ops/setup/validation) 变成了必选项。如果禁用这一 Webhook 将会导致 Pilot 崩溃。

- [Service entry](/zh/docs/reference/config/istio.networking.v1alpha3/#serviceentry) 校验当配置了 DNS 解析的时候将拒绝不使用通配符主机名（`*`）。相关 API 从未允许这种行为，但在前一版本中，`ServiceEntry` 对象的验证过程错误的忽略了这一错误。

- `istio-proxy` 的 Core dump 路径变为 `/var/lib/istio`。

## 网络

- 缺省启用 [双向 TLS](/zh/docs/tasks/security/mutual-tls) 的 `PERMISSIVE` 模式。

- Pilot 的性能和伸缩性有了很大提升。现在每秒钟之内，Pilot 可以向 500 个 Sidecar 发送端点更新信息。

- 缺省的[追踪采样]被设置为 `1%`。

## 策略和遥测

- Mixer（`istio-telemetry`）现在可以根据请求速率和延迟进行减载。

- Mixer 客户端（`istio-policy`）现已支持 `FAIL_OPEN` 设置。

- 在 Grafana 中加入了 Istio 性能 Dashboard。

- `istio-telemetry` 的 CPU 消耗降低了 10%。

- 不再进行 `statsd-to-prometheus` 的部署。Prometheus 现在直接从 `istio-proxy` 进行数据采集。
