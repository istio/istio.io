---
title: Service Registry
---

Istio 维护了一个内部服务注册表 (service registry)，它包含在服务网格中运行的一组[服务](#service)及其相应的[服务 endpoints](#service-endpoint)。Istio 使用服务注册表生成 [Envoy](#envoy) 配置。

Istio 不提供[服务发现](https://en.wikipedia.org/wiki/Service_discovery)，尽管大多数服务都是通过 [Pilot](#pilot) adapter 自动加入到服务注册表里的，而且这反映了底层平台（Kubernetes、Consul、plain DNS）的已发现的服务。还有就是，可以使用 [`ServiceEntry`](/zh/docs/concepts/traffic-management/#service-entries) 配置手动进行注册。
