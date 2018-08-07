---
title: Kubernetes - 我可以将已安装的Istio 0.1.x迁移到0.2.x吗？
weight: 30
---

不支持从Istio 0.1.x升级到0.2.x。您必须完整卸载Istio 0.1，_包括所有的 pods 和其 Istio sidecars_，并全新安装Istio 0.2之后再重新开始。
