---
title: Kubernetes - 我该如何调试 sidecar 自动注入的问题？
weight: 20
---

为了支持 sidecar 自动注入，请确保你的集群符合此[前提条件](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)。如果你的微服务是部署在 kube-system、kube-public 或者 istio-system 这些命名空间，那么就会被免除 sidecar 自动注入。请使用其他命名空间替代。