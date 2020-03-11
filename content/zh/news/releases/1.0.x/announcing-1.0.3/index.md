---
title: Istio 1.0.3 发布公告
linktitle: 1.0.3
subtitle: 补丁发布
description: Istio 1.0.3 补丁发布。
publishdate: 2018-10-30
release: 1.0.3
aliases:
    - /zh/about/notes/1.0.3
    - /zh/blog/2018/announcing-1.0.3
    - /zh/news/2018/announcing-1.0.3
    - /zh/news/announcing-1.0.3
---

我们很高兴的宣布 Istio 1.0.3 现已正式发布。下面是更新详情。

{{< relnote >}}

## 行为变更{#behavior-changes}

- 现在强制使用[验证 webhook](/zh/docs/ops/common-problems/validation)。禁用它可能导致 Pilot 崩溃。

- 现在，[Service entry](/zh/docs/reference/config/networking/service-entry/) 验证会在配置为 DNS 解析时拒绝通配主机名（`*`）。API 从未允许这样做，只是在以前的版本中，`ServiceEntry` 被错误地排除在验证之外。把通配符作为主机名的一部分，例如 `*.bar.com`，将保持不变。

- `istio-proxy` 的核心转储路径已更改为 `/var/lib/istio`。

## 网络{#networking}

- [双向 TLS](/zh/docs/tasks/security/authentication/mutual-tls) 宽容模式现在是默认启用的。

- Pilot 性能和可扩展性已大大增强。Pilot 现在可以在不到 1 秒的时间内向 500 个 sidecar 提供 endpoint 更新。

- [追踪采样](/zh/docs/tasks/observability/distributed-tracing/overview/#trace-sampling)默认设置为 1%。

## 策略和遥测{#policy-and-telemetry}

- Mixer（`istio-telemetry`）现在支持基于请求速率和预期延迟的减载。

- Mixer 客户端（`istio-policy`）现在支持 `FAIL_OPEN` 设置。

- Istio 性能仪表盘已添加至 Grafana。

- `istio-telemetry` CPU 使用率降低 10%。

- 淘汰 `statsd-to-prometheus` deployment。Prometheus 现在可以直接从 `istio-proxy` 中抓取指标。
