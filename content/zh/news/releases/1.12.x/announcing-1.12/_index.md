---
title: Istio 1.12 公告
linktitle: 1.12
subtitle: 重大更新
description: Istio 1.12 发布公告。
publishdate: 2021-11-18
release: 1.12.0
skip_list: true
aliases:
    - /zh/news/announcing-1.12
    - /zh/news/announcing-1.12.0
---

我们很高兴地宣布 Istio 1.12 的发布！

{{< relnote >}}

这是 2021 年的最后一个版本。我们要感谢整个 Istio 社区，特别是来自 Red Hat 的发行经理 [Daniel Grimm](https://github.com/dgn) 和来自 Aspen Mesh 的 [Kenan O'Neal](https://github.com/Kmoneal)，感谢他们帮助我们发布了 1.12.0。

{{< tip >}}
Istio 1.12.0 在 Kubernetes `1.19` 到 `1.22` 版本上得到了官方支持。
{{< /tip >}}

以下是该版本的一些亮点：

## WebAssembly API{#WebAssembly-API}

[WebAssembly](/zh/docs/concepts/wasm/) 一直是一个重要的项目，已经开发了 [3 年多](/zh/blog/2020/wasm-announce/)，通过允许用户在运行时动态加载自定义扩展，为 Istio 带来高级的可扩展性。
然而，到目前为止，配置 WebAssembly 插件还处于实验阶段，并且很难使用。

在 Istio 1.12 中，我们增加了一流的 API 来配置 WebAssembly 插件，从而改善了这种体验：[WasmPlugin](/zh/docs/reference/config/proxy_extensions/wasm-plugin/)。

使用 `WasmPlugin`，您可以很容易地将自定义插件部署到单个代理，甚至整个网格。

该 API 目前处于 alpha 阶段并在不断发展。感谢[您的反馈](/zh/get-involved/)！

## Telemetry API{#Telemetry-API}

在 Istio 1.11 中，我们引入了一个全新的 [`Telemetry` API](/zh/docs/reference/config/telemetry/)，带来了一个标准化的 API，用于在 Istio 中配置跟踪、日志记录和指标。

在 1.12 中，我们继续朝这个方向努力，扩展了对 API 配置指标和访问日志记录的支持。

要开始，请查看以下文档：

* [Telemetry API 概述](/zh/docs/tasks/observability/telemetry/)
* [追踪](/zh/docs/tasks/observability/distributed-tracing/)
* [指标](/zh/docs/tasks/observability/metrics/)
* [访问日志](/zh/docs/tasks/observability/logs/access-log/)

该 API 目前处于 alpha 阶段并在不断发展。感谢[您的反馈](/zh/get-involved/)！

## Helm 支持{#helm-support}

Istio 1.12 对我们的 [Helm 安装支持](/zh/docs/setup/install/helm/)进行了许多改进，并为该功能在未来升级到测试版铺平了道路。

一个官方的 Helm 库已经发布，以进一步简化加载流程，适应了[最流行的 GitHub  特性请求](https://github.com/istio/istio/issues/7505)之一。
查看新的[入门](/zh/docs/setup/install/helm/#prerequisites)说明以获取更多信息。

这些图表也可以在 [ArtifactHub](https://artifacthub.io/packages/search?org=istio) 上找到。

此外，还发布了新的精制的 [`gateway` chart](https://artifacthub.io/packages/helm/istio-official/gateway) 图表。
这个 chart 取代了旧的 `istio-ingressgateway` 和 `istio-egressgateway` charts，极大地简化了网关的管理，并遵循 Helm 的最佳实践。请访问网关注入页面，了解迁移到 helm chart 的说明。

## Kubernetes Gateway API{#Kubernetes-Gateway-API}

Istio 已经完全支持 `v1alpha2` 版本的 [Kubernetes Gateway API](http://gateway-api.org/)。
该 API 的目的是统一 Istio、Kubernetes `Ingress` 和其他代理使用的各种 API 集，以定义一个强大的、可扩展的 API 来配置流量路由。

虽然 API 还没有针对生产工作负载，但 API 和 Istio 的实现正在迅速发展。
要试用它，请查看 [Kubernetes Gateway API](/zh/docs/tasks/traffic-management/ingress/gateway-api/) 文档。

## 还有很多很多{#and-much-much-more}

* Default Retry Policies 已经被添加到 [Mesh Config](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)，允许用户在单个位置配置默认的重试策略，而不是在每个 VirtualService 中重复配置。
* 一个新的 `failoverPriority` 配置已经添加到[Locality Load Balancing 配置](/zh/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting)中，允许自定义 Pod 的优先级。例如，同一网络中的 Pod 可以被赋予额外的优先级。
* 添加了新的配置使[安全 TLS 发起更简单](/zh/docs/ops/best-practices/security/#configure-tls-verification-in-destination-rule-when-using-tls-origination)。
* 如果您错过了：已经为 [gRPC 原生 "Proxyless" Service Mesh](/zh/blog/2021/proxyless-grpc/) 添加了初始支持。
* [添加了](https://github.com/istio/istio/wiki/Experimental-QUIC-and-HTTP-3-support-in-Istio-gateways)对 HTTP/3 Gateway 的额实验性支持。
* 有关更改的完整列表，请参阅 [Change Notes](/zh/news/releases/1.12.x/announcing-1.12/change-notes/)。
