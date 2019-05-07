---
title: Istio 能将追踪信息发送到外部 ZipKin 实例吗？
weight: 110
---

要实现该功能，必须使用 Zipkin 实例的完全限定域名。例如：

`zipkin.mynamespace.svc.cluster.local`。