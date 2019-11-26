---
title: 我可以使用 Prometheus 配合 Istio 抓取应用程序指标吗？
weight: 90
---

是的。Istio 附带 [Prometheus 的配置]({{< github_file >}}/install/kubernetes/helm/istio/charts/prometheus/templates/configmap.yaml)，在启用或禁用双向 TLS 时启动收集应用程序指标的功能。

`kubernetes-pods` job 从没有双向 TLS 环境中的 pod 收集应用程序指标。当为 Istio 启用双向 TLS 时，`kubernetes-pods-istio-secure` job 从应用程序的 pod 中收集指标。

这两个 job 都要求将以下注释添加到需要从中收集应用程序指标的所有 deployment 中：

- `prometheus.io/scrape: "true"`
- `prometheus.io/path: "<metrics path>"`
- `prometheus.io/port: "<metrics port>"`

一些注意事项：

- 如果 Prometheus pod 在 Istio Citadel pod 生成所需证书并将其分发给 Prometheus 之前启动，则 Prometheus pod 需要重启以便收集双向 TLS 保护的目标信息。
- 如果您的应用程序在专用端口上公开了 Prometheus 指标，则应将该端口添加到 service 和 deployment 规范中。
