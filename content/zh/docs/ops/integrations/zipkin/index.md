---
title: Zipkin
description: How to integrate with Zipkin.
weight: 31
keywords: [integration,zipkin,tracing]
owner: istio/wg-environments-maintainers
test: n/a
---
 
[Zipkin](https://zipkin.io/)是一个分布式追踪系统。它帮助收集在定位服务架构延迟问题时所需的计时数据。包括数据的收集和查找等特性。

## 安装

### 选项1：快速开始

Istio提供了一个基本的安装示例来快速启动和运行Zipkin:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/extras/zipkin.yaml
{{< /text >}}

通过kubectl apply -f 将Zipkin部署到集群中。仅用于演示，没有针对性能或安全性进行调优。

### 选项2： 定制化安装

查阅[Zipkin文档](https://zipkin.io/)开始安装。Zipkin配合Istio使用时没有特别的地方需要修改。

Zipkin安装完成后，你需要指定Istio代理用来向deployment发送追踪数据。在安装时候可以通过`--set values.global.tracer.zipkin.address=<zipkin-collector-address>:9411`
指定配置参数。高级配置例如：TLS配置可以参考[`ProxyConfig.Tracing`](/docs/reference/config/istio.mesh.v1alpha1/#Tracing)链接。

## 使用

有关使用Zipkin的更多信息，请参阅[Zipkin task](/docs/tasks/observability/distributed-tracing/zipkin/).