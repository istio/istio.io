---
title: Workload Instance
test: n/a
---

工作负载实例是[工作负载](/zh/docs/reference/glossary/#workload)的一个二进制实例化对象。
一个工作负载实例可以开放零个或多个[服务 endpoint](/zh/docs/reference/glossary/#service-endpoint)，
也可以消费零个或多个[服务](/zh/docs/reference/glossary/#service)。

工作负载实例具有许多属性：

- 名称和命名空间
- 唯一的 ID
- IP 地址
- 标签
- 主体

通过访问 [`source.*` 和 `destination.*` 下面的属性](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)，在 Istio 的策略和遥测配置功能中，可以用到这些属性。
