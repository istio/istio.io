---
title: ztunnel 存在单点故障吗？
weight: 25
---

Istio 的 ztunnel 不会将单点故障（SPOF）引入 Kubernetes 集群。
ztunnel 的故障仅限于单个节点，该节点被视为集群中的易出错组件。
它的行为与每个集群上运行的其他节点关键基础设施（如 Linux 内核、容器运行时等）相同。
在设计合理的系统中，节点中断不会导致集群中断。[了解更多](https://blog.howardjohn.info/posts/ambient-spof/)。
