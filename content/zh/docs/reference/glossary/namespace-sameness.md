---
title: Namespace Sameness
test: n/a
---

在多集群网格中，[命名空间相同](https://github.com/kubernetes/community/blob/master/sig-multicluster/namespace-sameness-position-statement.md)，
具有给定名称的所有命名空间都被认为是相同的命名空间。
如果多个集群包含一个具有相同命名空间名称的 `Service` ，它们将被识别为单个组合服务。
默认情况下，对于给定的服务，流量是跨网格中的所有集群进行负载均衡的。
