---
title: 我能在 Istio 中使用 Prometheus 抓取应用指标么？
weight: 90
---

可以。Istio 发行包中带有 [Prometheus 配置]({{< github_file >}}/install/kubernetes/helm/istio/charts/prometheus/templates/configmap.yaml)，不论是否启用了双向 TLS，都可以借此配置来收集应用的指标数据。

在没有启用双向 TLS 的环境中，`kubernetes-pods` 任务会从 Pod 中收集应用的指标数据。如果 Istio 启用了双向 TLS，就由 `kubernetes-pods-istio-secure` 任务完成应用指标数据的收集工作。

两个 Job 都需要在欲抓取指标的应用 Pod 中加入如下注解：

- `prometheus.io/scrape: "true"`
- `prometheus.io/path: "<metrics path>"`
- `prometheus.io/port: "<metrics port>"`

一点说明：

- 如果在 Citadel Pod 能够生成必要证书并分发给 Prometheus 之前启动了 Prometheus Pod，为了能够在双向 TLS 环境下抓取应用指标，必须重启 Prometheus Pod。

- 如果你的应用在一个单独的端口上开放 Prometheus 指标接口，这个端口需要加入 Service 和 Deployment 清单之中。
