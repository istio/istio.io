---
title: Data Plane
test: n/a
---

数据平面是网格中直接处理并路由工作负载实例之间流量的那一部分。

在 {{< gloss >}}sidecar{{< /gloss >}} 模式下，Istio 的数据平面使用部署为 Sidecar
的 [Envoy](/zh/docs/reference/glossary/#envoy) 代理来调解和控制网格服务的所有收发流量。

在 {{< gloss >}}ambient{{< /gloss >}} 模式下，Istio 的数据平面使用以 DaemonSet 部署的节点级
{{< gloss >}}ztunnel{{< /gloss >}} 代理来调解和控制网格服务的所有收发流量。
