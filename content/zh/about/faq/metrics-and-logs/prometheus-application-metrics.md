---
title: 我可以使用 Prometheus 配合 Istio 抓取应用程序指标吗？
weight: 90
---

是的。[Prometheus](https://prometheus.io/) 是一款开源监控系统和时间序列数据库。
您可以将 Prometheus 与 Istio 结合使用来记录跟踪 Istio 和服务网格内应用程序运行状况的指标。
您可以使用 [Grafana](/zh/docs/ops/integrations/grafana/) 和
[Kiali](/zh/docs/tasks/observability/kiali/) 等工具对指标进行可视化。
请参阅 [Prometheus 配置](/zh/docs/ops/integrations/prometheus/#Configuration)以了解如何启用指标收集。

一些注意事项：

- 如果 Prometheus Pod 在 Istio Citadel Pod 生成所需证书并将其分发给 Prometheus 之前启动，
  则 Prometheus pod 需要重启以便收集双向 TLS 保护的目标信息。
- 如果您的应用程序在专用端口上公开了 Prometheus 指标，则应将该端口添加到 Service 和 Deployment 规范中。
