---
title: Workload
test: n/a
---

[operators](/zh/docs/reference/glossary/#operator) 部署的二进制文件，用于提供服务网格应用的一些功能。
工作负载有自己的名称，命名空间，和唯一的 id。
这些属性可以通过下面的[属性](/zh/docs/reference/glossary/#attribute)被策略配置和遥测配置使用：

* `source.workload.name`, `source.workload.namespace`, `source.workload.uid`
* `destination.workload.name`, `destination.workload.namespace`, `destination.workload.uid`

在 Kubernetes 环境中，一个工作负载通常对应一个 Kubernetes deployment，
并且一个[工作负载实例](/zh/docs/reference/glossary/#workload-instance)对应一个独立的被 deployment 管理的 [pod](/zh/docs/reference/glossary/#pod)。
