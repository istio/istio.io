---
title: 高级安装选项
description: 定制 Istio 安装的介绍
weight: 20
keywords: [kubernetes]
draft: true
---

本节介绍了一些 Istio 组件的碎片式安装的选项。

## 仅安装 Ingress 控制器

将 Istio 用作 Ingress 控制器是可行的，可以用于在七层提供路由方面的支撑，例如基于版本的路由、基于 Header 的路由、gRPC/HTTP2 代理、跟踪等。仅部署 Istio Pilot，并禁用其他组件。不要部署 Istio 的 `initializer`。

## Ingress 控制器，并提供遥测和策略支持

部署 Istio Pilot 和 Mixer 之后，上面提到的 Ingress 控制器配置就能够得到增强，进一步提供深入的遥测和策略实施能力了，其中包含了速率控制、访问控制等功能。

## 智能路由和遥测

如果要在深度遥测和分布式请求跟踪之外，还希望享受 Istio 的七层流量管理能力，就需要部署 Istio Pilot 和 Mixer；另外还可以在 Mixer 上禁用策略支持。