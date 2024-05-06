---
title: Data Plane
test: n/a
---

数据平面是网格的一部分，直接处理和路由工作负载实例之间的流量。

在 {{< gloss "sidecar" >}}Sidecar{{< /gloss >}} 模式下，
Istio 的数据平面使用部署为 Sidecar 的 [Envoy](/zh/docs/reference/glossary/#envoy)
代理来协调和控制网格内服务发送和接收的所有流量。

在 {{< gloss "ambient" >}}Ambient{{< /gloss >}} 模式下，
Istio 的数据平面使用部署为 DaemonSet 的节点级 {{< gloss >}}ztunnel{{< /gloss >}}
代理来调解和控制网格服务发送和接收的所有流量。
