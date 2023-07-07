---
title: Service Registry
test: n/a
---

Istio 维护了一个内部服务注册表 (service registry)，它包含在服务网格中运行的一组[服务](/zh/docs/reference/glossary/#service)及其相应的[服务 endpoints](/zh/docs/reference/glossary/#service-endpoint)。
Istio 使用服务注册表生成 [Envoy](/zh/docs/reference/glossary/#envoy) 配置。

Istio 不提供[服务发现](https://zh.wikipedia.org/wiki/%E6%9C%8D%E5%8A%A1%E5%8F%91%E7%8E%B0)，
尽管大多数服务都是通过 [Pilot](/zh/docs/reference/glossary/#pilot) adapter 自动加入到服务注册表里的，
而且这反映了底层平台（Kubernetes、Consul、plain DNS）的已发现的服务。还有就是，可以使用
[`ServiceEntry`](/zh/docs/concepts/traffic-management/#service-entries) 配置进行手动注册。
