---
title: 工作负载
---
工作负载是通过操作部署的二进制文件，用于在 Istio 里提供某种功能。工作负载有名字，命名空间和唯一的 id。工作负载的属性可以通过下面这些[属性](#%E5%B1%9E%E6%80%A7)在策略和遥测配置功能里获取：

* `source.workload.name`, `source.workload.namespace`, `source.workload.uid`
* `destination.workload.name`, `destination.workload.namespace`, `destination.workload.uid`

在 Kubernetes里，一个工作负载通常对应一个 Kubernetes 的 deployment，然后一个工作负载的实例对应一个 deployment 管理的其中一个 pod。
