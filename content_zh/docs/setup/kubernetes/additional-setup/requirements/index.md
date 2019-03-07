---
title: Istio 对 Pod 和服务的要求
description:  这里讲述了 Istio 对 Kubernetes 中 Pod 和服务的要求。
weight: 50
keywords: [kubernetes,sidecar,sidecar-injection]
---

要成为服务网格的一部分，Kubernetes 集群中的 Pod 和服务必须满足以下几个要求：

* _**需要给端口正确命名**_：服务端口必须进行命名。端口名称只允许是`<协议>[-<后缀>-]`模式，其中`<协议>`部分可选择范围包括 `grpc`、`http`、`http2`、`https`、`mongo`、`redis`、`tcp`、`tls` 以及 `udp`，Istio 可以通过对这些协议的支持来提供路由能力。例如 `name: http2-foo` 和 `name: http` 都是有效的端口名，但 `name: http2foo` 就是无效的。如果没有给端口进行命名，或者命名没有使用指定前缀，那么这一端口的流量就会被视为普通 TCP 流量（除非[显式](https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service)的用 `Protocol: UDP` 声明该端口是 UDP 端口）。

* _**Pod 端口**:_ Pod 必须包含每个容器将监听的明确端口列表。在每个端口的容器规范中使用 `containerPort`。任何未列出的端口都将绕过 Istio Proxy。

* _**关联服务**_：Pod 必须关联到 [Kubernetes 服务](https://kubernetes.io/docs/concepts/services-networking/service/)，如果一个 Pod 属于多个服务，这些服务不能再同一端口上使用不同协议，例如 HTTP 和 TCP。

* _**Deployment 应带有 `app` 以及 `version` 标签**_：在使用 Kubernetes `Deployment` 进行 Pod 部署的时候，建议显式的为 `Deployment` 加上 `app` 以及 `version` 标签。每个 Deployment 都应该有一个有意义的 `app` 标签和一个用于标识 `Deployment` 版本的 `version` 标签。`app` 标签在分布式追踪的过程中会被用来加入上下文信息。Istio 还会用 `app` 和 `version` 标签来给遥测指标数据加入上下文信息。

* _**Application UID**_：**不要**使用 ID（UID）值为 **1337** 的用户来运行应用。

* _**`NET_ADMIN` 功能**:_ 如果您的群集中实施了 pod 安全策略，除非您使用 [Istio CNI 插件](/docs/setup/kubernetes/additional-setup/cni/)，您的 pod 必须具有`NET_ADMIN`功能。
                                请参阅[必需的 Pod 功能](/help/ops/setup/required-pod-capabilities/)。
