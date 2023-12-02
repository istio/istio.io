---
title: Namespace Sameness
test: n/a
---

在多集群网格中，适用[命名空间相同](https://github.com/kubernetes/community/blob/master/sig-multicluster/namespace-sameness-position-statement.md)规则，
即所有具有相同给定名称的命名空间都被认为是同一个命名空间。
如果多个集群包含具有相同命名空间名称的 `Service`，那这些 `Service` 将被识别为单个组合服务。
默认情况下，对于给定的服务，流量是跨网格中的所有集群进行负载均衡的。

与**端口号**匹配的端口也必须具有相同的端口**名称**，才会被视为组合的 `service port`。
