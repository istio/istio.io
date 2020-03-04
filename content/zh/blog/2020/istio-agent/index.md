---
title: 移除跨 pod Unix domain socket
description: 一种更安全的秘密管理方式。
publishdate: 2020-02-20
attribution: Lei Tang (Google)
keywords: [security, secret discovery service, unix domain socket]
target_release: 1.5
---

在 Istio 1.5 之前，执行秘密发现服务（SDS）期间，SDS 客户端和 SDS 服务器通过跨 pod Unix domain socket（UDS）进行通信，该法需要 Kubernetes pod 安全策略提供保护。

在 Istio 1.5 中，Pilot Agent、Envoy 和 Citadel Agent 将运行在同一个容器中（体系结构如下图所示）。为了防止攻击者窃听 Envoy（SDS 客户端）和 Citadel Agent（SDS 服务器）之间的跨 pod UDS，Istio 1.5 将 Pilot Agent 和 Citadel Agent 合并为一个 Istio Agent，并将 Envoy 和 Citadel Agent 之间的 UDS 变为 Istio Agent 专用的（私有的）。Istio Agent 容器被部署为应用服务容器的 sidecar。

{{< image width="70%"
    link="./istio_agent.svg"
    caption="Istio Agent 的体系结构"
    >}}
