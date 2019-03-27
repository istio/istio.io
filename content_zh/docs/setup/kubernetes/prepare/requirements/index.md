---
title: Pods 和服务
description: 准备 Kubernetes Pods 和服务来运行启用了 Istio 的集群.
weight: 5
keywords: [kubernetes,sidecar,sidecar-injection]
---

作为 Istio 服务网格的一部分, Kubernetes 集群中的 pods 和服务必须满足如下条件:

- **服务端口命名**：服务端口必须被命名。端口名称键值对必须使用如下格式: `name: <protocol>[-<suffix>]`。要想利用 Istio 的路由功能，请把 `<protocol>` 替换为如下协议中的一个：

    - `grpc`
    - `http`
    - `http2`
    - `https`
    - `mongo`
    - `redis`
    - `tcp`
    - `tls`
    - `udp`

    例如，`name: http2-foo` 或者 `name: http` 都是有效的端口命名，但 `name: http2foo` 就不是。如果端口名称不以特定前缀开头或者没有被命名，这个端口的流量将被作为简单 TCP 流量来处理，除非这个端口[明确地](https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service)使用 `Protocol: UDP` 来表示一个 UDP 端口。

- **Pod 端口**：Pods 必须明确包含每个容器监听的端口列表。容器的每个端口都要使用 `containerPort` 配置。任何没有被列出的端口都将绕过 Istio 代理。

- **服务关联**: 每一个 pod 都必须关联至少一个 Kubernetes 服务即使这个 pod **没有**暴露任何端口。如果一个 pod 属于多个 [Kubernetes 服务](https://kubernetes.io/docs/concepts/services-networking/service/)，这些服务不能把相同的端口号用于不同协议，比如 HTTP 和 TCP。

- **使用 app 和 version 标签部署**：我们建议在部署中添加明确的 `app` 标签和 `version` 标签。在使用 Kubernetes `Deployment` 部署 pod 时添加这些标签，`app` 和 `version` 标签会添加上下文关联信息到 Istio 收集的度量和遥测数据中。

    - `app` 标签：每一个部署定义都应该有一个包含有意义值的 `app` 标签。`app` 标签被用来添加上下文信息到分布式跟踪中。

    - `version` 标签：这个标签标示了特定部署相关应用的版本号。

- **应用 UIDs**：确保您的 pods **不会** 使用一个值为 **1337** 的用户ID (UID) 启动应用程序。

- **`NET_ADMIN` 功能**：如果您的集群启用了 pod 安全策略，pods 必须启用 `NET_ADMIN` 功能。如果您使用了 [Istio CNI 插件](/docs/setup/kubernetes/additional-setup/cni/)，这个功能就不需要了。要了解更多关于 `NET_ADMIN` 的功能，请访问 [Pod 的必要功能](/zh/help/ops/setup/required-pod-capabilities/)。

## Istio 使用的端口

如下端口和协议都被 Istio 所使用。确保不要有 headless 类型的服务占用任何一个被 Istio 服务使用到的 TCP 端口。

| 端口 | 协议 | 使用者 | 描述 |
|----|----|----|----|
| 8060 | HTTP | Citadel | GRPC 服务器 |
| 9090 | HTTP |  Prometheus | Prometheus |
| 9091 | HTTP | Mixer | Policy/Telemetry |
| 9093 | HTTP | Citadel | |
| 15000 | TCP | Envoy | Envoy 管理端口 (命令/诊断) |
| 15001 | TCP | Envoy | Envoy |
| 15004 | HTTP | Mixer, Pilot | Policy/Telemetry - `mTLS` |
| 15010 | HTTP | Pilot | Pilot 服务 - XDS pilot - 服务发现 |
| 15011 | TCP | Pilot | Pilot 服务 - `mTLS` - Proxy - 服务发现 |
| 15014 | HTTP | Citadel, Mixer, Pilot | 控制平面监控 |
| 15030 | TCP | Prometheus | Prometheus |
| 15090 | HTTP | Mixer | Proxy |
| 42422 | TCP | Mixer | Telemetry - Prometheus |
