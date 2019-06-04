---
title: 为什么 Istio 不能取代应用程序来传播 header？
weight: 20
---

尽管 Istio sidecar 将处理与之关联的应用程序实例的入站和出站请求，但它并不能隐式地将出站请求和与该出站请求对应的入站请求建立联系。
实现这种相关性的唯一方法是应用程序[传递从入站请求到出站请求的关联信息](/zh/docs/tasks/telemetry/distributed-tracing/overview/#understanding-what-happened)（比如，header）。
header 的传播可以通过客户端库或手动完成。
[使用 Istio 进行分布式追踪需要什么？](/zh/faq/distributed-tracing/#how-to-support-tracing)提供了进一步的讨论。
