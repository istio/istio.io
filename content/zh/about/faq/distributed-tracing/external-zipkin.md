---
title: Istio 是否能发送追踪信息到外部与 Zipkin 兼容的后端？
weight: 70
---

可以这么做，但是必须用 Zipkin 兼容实例的完全合格的域名。比如：`zipkin.mynamespace.svc.cluster.local`。
