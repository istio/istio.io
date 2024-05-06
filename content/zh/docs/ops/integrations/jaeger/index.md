---
title: Jaeger
description: 如何与 Jaeger 集成。
weight: 28
keywords: [integration,jaeger,tracing]
owner: istio/wg-environments-maintainers
test: n/a
---

[Jaeger](https://www.jaegertracing.io/) 是一个开源的端到端的分布式跟踪系统，
允许用户在复杂的分布式系统中监控和排查故障。

## 安装 {#installation}

### 方式一：快速开始 {#option-1-quick-start}

Istio 提供一个基础的示例安装，可快速启动和运行 Jaeger：

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/jaeger.yaml
{{< /text >}}

以上命令会把 Jaeger 部署到您的集群中。这个只是例子，并不针对性能和安全性的配置。

### 方式二：手动安装 {#option-2-customizable-install}

参考 [Jaeger 文档](https://www.jaegertracing.io/)开始使用。
Jaeger 与 Istio 一起使用时无需特殊的配置。

安装 Jaeger 完毕后，需要指定 Istio 代理向 Deployment 发送流量。
在安装时，可以使用 `--set meshConfig.defaultConfig.tracing.zipkin.address=<jaeger-collector-address>:9411`
进行配置。参考更多 [`ProxyConfig.Tracing`](/zh/docs/reference/config/istio.mesh.v1alpha1/#Tracing)
高级配置，如 TLS 设置。

## 使用 {#usage}

有关使用 Jaeger 的更多信息，请参考 [Jaeger Task](/zh/docs/tasks/observability/distributed-tracing/jaeger/)。
