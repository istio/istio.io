---
title: Apache SkyWalking
description: 如何集成 Apache SkyWalking。
weight: 32
keywords: [integration,skywalking,tracing]
owner: istio/wg-environments-maintainers
test: no
---

[Apache SkyWalking](http://skywalking.apache.org) 是一个专门设计用于微服务、
云原生和容器等架构的应用性能监控 (APM) 系统。SkyWalking 是可观测性的一站式解决方案，
不仅具有像 Jaeger 和 Zipkin 的分布式追踪能力，像 Prometheus 和 Grafana
的指标能力，像 Kiali 的日志记录能力，还能将可观测性扩展到许多其他场景，
例如将日志与链路关联，收集系统事件并将事件与指标关联，基于 eBPF 的服务性能分析等。

## 安装 {#installation}

### 选项 1：快速开始 {#option-1-quick-start}

Istio 提供了基本的安装样例以快速搭建并运行 SkyWalking：

{{< text bash >}}
$ kubectl apply -f @samples/addons/extras/skywalking.yaml@
{{< /text >}}

以上命令将 SkyWalking 部署到您的集群。此样例仅用于演示，
并未包含性能或安全调优。

Istio 代理默认不向 SkyWalking 发送链路追踪。您也需要通过添加以下字段到您的配置来启用
SkyWalking 追踪扩展提供程序：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    extensionProviders:
      - skywalking:
          service: tracing.istio-system.svc.cluster.local
          port: 11800
        name: skywalking
    defaultProviders:
        tracing:
        - "skywalking"
{{< /text >}}

### 选项 2：自定义安装 {#option-2-customizable-install}

请参阅 [SkyWalking 文档](http://skywalking.apache.org)开始安装。
若想在 Istio 上运行 SkyWalking，无需任何特殊改动。

一旦安装了 SkyWalking，记住要修改指向 `skywalking-oap` Deployment
的 `--set meshConfig.extensionProviders[0].skywalking.service` 选项。
有关 TLS 设置的高级配置信息，请参见 [`ProxyConfig.Tracing`](/zh/docs/reference/config/istio.mesh.v1alpha1/#Tracing)。

## 使用 {#usage}

有关使用 SkyWalking 的更多信息，请参阅
[SkyWalking 任务](/zh/docs/tasks/observability/distributed-tracing/skywalking/)。
