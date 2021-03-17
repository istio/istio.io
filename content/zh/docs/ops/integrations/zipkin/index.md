---
title: Zipkin
description: 如何与 Zipkin 进行集成。
weight: 31
keywords: [integration,zipkin,tracing]
owner: istio/wg-environments-maintainers
test: n/a
---

[Zipkin](https://zipkin.io/) 是一个分布式追踪系统。它帮助收集在定位服务架构延迟问题时所需的计时数据。包括数据的收集和查找等特性。

## 安装 {#installation}

### 方法1：快速开始 {#quick-start}

Istio 提供了一个基本的安装示例来快速启动和运行 Zipkin:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/extras/zipkin.yaml
{{< /text >}}

通过 kubectl apply -f 将 Zipkin 部署到集群中。仅用于演示，没有针对性能或安全性进行调优。

### 方法2：定制化安装 {#customizable-install}

查阅 [Zipkin 文档](https://zipkin.io/) 开始安装。Zipkin 集成 Istio 使用时没有特别的地方需要修改。

Zipkin 安装完成后，您需要指定 Istio 代理用来向 Deployment 发送追踪数据。可以在安装时候可以通过配置参数 `--set values.global.tracer.zipkin.address=<zipkin-collector-address>:9411` 指定。更高级配置例如：TLS 配置可以参考 [`ProxyConfig.Tracing`](/zh/docs/reference/config/istio.mesh.v1alpha1/#Tracing) 链接。

## 使用 {#usage}

有关使用 Zipkin 的更多信息，请参阅 [Zipkin](/zh/docs/tasks/observability/distributed-tracing/zipkin/)。