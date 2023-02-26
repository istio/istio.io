---
title: Istio 1.15 升级说明
description: 升级到 Istio 1.15.0 时需要考虑的重要更改。
publishdate: 2022-08-31
weight: 20
---

当您从 Istio 1.14.x 升级到 Istio 1.15.0 时，您需要考虑此页面上所描述的变化。
这些说明详细介绍了有意地破坏与 Istio 1.14.0 的向后兼容性所带来的变化。
说明中还提到了在引入新行为的同时保留向后兼容性的变化。
只有当新的行为对 Istio `1.14.x` 的用户来说是意想不到的时候，才会包括这些变化。
从 1.13.x 升级到 Istio 1.15.0 的用户还应该参考 [1.15.0 变更日志](/zh/news/releases/1.15.x/announcing-1.15/change-notes/)。

## 远程集群管理 {#remote-cluster-management}

从 Istio 1.15.0 开始，一个远程集群不再由它所连接的控制平面自动管理。
只有当远程集群的集群 ID 所在的系统命名空间上指定 `topology.istio.io/controlPlaneClusters` 注解，远程集群才会被控制平面管理。
在升级相应的之前，必须将此注解添加到远程集群外部或主集群上的控制平面。

有关更多详细信息，请参考[外部控制平面](/zh/docs/setup/install/external-controlplane/#register-the-new-cluster)和[主从架构的安装](/zh/docs/setup/install/multicluster/primary-remote/#attach-cluster2-as-a-remote-cluster-of-cluster1)说明。
