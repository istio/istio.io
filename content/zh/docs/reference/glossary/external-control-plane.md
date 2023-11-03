---
title: External Control Plane
test: n/a
---

External Control Plane 是从外部管理运行在自己的 [Cluster](/zh/docs/reference/glossary/#cluster)
或者其他基础设施中的网格工作负载的 [Control Plane](/zh/docs/reference/glossary/#control-plane)。
Control Plane 可以部署在一个 Cluster 中，尽管不能部署在它所控制的网格的一部分 Cluster 中。
它的目的是将 Control Plane 与网格的 Data Plane 完全分离。
