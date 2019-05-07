---
title: Kubernetes - 我可以将已安装的 Istio 0.1.x 迁移到 0.2.x 吗？
weight: 30
---

不支持从 Istio 0.1.x 升级到 0.2.x 。您必须完整卸载 Istio 0.1 ，_包括所有的 pods 和其 Istio sidecar_，并全新安装 Istio 0.2 之后再重新开始。
