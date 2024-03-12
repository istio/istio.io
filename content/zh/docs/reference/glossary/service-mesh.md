---
title: Service Mesh
test: n/a
---

**服务网格** （简称 **网格** ）是一个可管理、可观测以及支持[工作负载实例](/zh/docs/reference/glossary/#workload-instance)之间进行安全通信的基础设施层。

在一个网格中，服务名称与命名空间组合具有唯一性。例如，在一个[多集群](/zh/docs/reference/glossary/#multicluster)的网格中，
`cluster-1` 集群的 `foo` 命名空间中的 `bar` 服务和 `cluster-2` 集群的 `foo` 命名空间中的 `bar` 服务被认为是同一个服务。

由于服务网格会共享这种[标识](/zh/docs/reference/glossary/#identity)，
因此同一服务网格内的[工作负载实例](/zh/docs/reference/glossary/#workload-instance)可以相互认证通信。
