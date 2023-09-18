---
title: 为什么 Istio 不能代替应用程序传播标头？
weight: 20
---

尽管 Istio Sidecar 将处理关联应用程序实例的入站和出站请求，
它没有将出站请求与导致它们的入站请求相关联的隐式方法。可以实现这种关联的唯一方法是通过应用程序传播相关信息
（例如标头）从入站请求到出站请求。头传播可以通过客户端库或手动完成。
提供了进一步的讨论[使用 Istio 进行分布式跟踪需要什么？](/zh/faq/distributed-tracing/#how-to-support-tracing)。
