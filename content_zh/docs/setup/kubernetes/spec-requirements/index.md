---
title: Istio 对 Pod 和服务的要求
description:  这里讲述了 Istio 对 Kubernetes 中 Pod 和服务的要求。
weight: 80
keywords: [kubernetes,sidecar,sidecar-injection]
---

要成为服务网格的一部分，Kubernetes 集群中的 Pod 和服务必须满足以下几个要求：

1. **需要给端口正确命名**：服务端口必须进行命名。端口名称只允许是`<协议>[-<后缀>-]`模式，其中`<协议>`部分可选择范围包括 `http`、`http2`、`grpc`、`mongo` 以及 `redis`，Istio 可以通过对这些协议的支持来提供路由能力。例如 `name: http2-foo` 和 `name: http` 都是有效的端口名，但 `name: http2foo` 就是无效的。如果没有给端口进行命名，或者命名没有使用指定前缀，那么这一端口的流量就会被视为普通 TCP 流量（除非[显式](https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service)的用 `Protocol: UDP` 声明该端口是 UDP 端口）。

1. **关联服务**：Pod 必须关联到 [Kubernetes 服务](https://kubernetes.io/docs/concepts/services-networking/service/)，如果一个 Pod 属于多个服务，这些服务不能再同一端口上使用不同协议，例如 HTTP 和 TCP。

1. **Deployment 应带有 `app` 标签**：在使用 Kubernetes `Deployment` 进行 Pod 部署的时候，建议显式的为 Deployment 加上 `app` 标签。每个 Deployment 都应该有一个有意义的 `app` 标签。`app` 标签在分布式跟踪的过程中会被用来加入上下文信息。