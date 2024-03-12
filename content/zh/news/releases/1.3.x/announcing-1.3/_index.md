---
title: Istio 1.3 发布公告 
linktitle: 1.3
subtitle: 重大更新
description: Istio 1.3 发布公告。
publishdate: 2019-09-12
release: 1.3.0
skip_list: true
aliases:
    - /zh/blog/2019/announcing-1.3
    - /zh/news/2019/announcing-1.3
    - /zh/news/announcing-1.3.0
    - /zh/news/announcing-1.3
---

我们很高兴的宣布 Istio 1.3 发布了！

{{< relnote >}}

Istio 1.3 的主题是用户体验：

- 改善新用户使用 Istio 的体验
- 改善用户调试问题的体验
- 支持更多应用程序，无需任何其他配置

Istio 团队每发布几个版本，都会在可用性、API 和整体系统性能方面进行重大改进。Istio 1.3 就是这样的一个版本，团队非常高兴推出这些关键更新。

## 智能协议检测（实验性）{#intelligent-protocol-detection-experimental}

为了利用 Istio 的路由功能，服务端口必须使用特殊的端口命名格式来显式声明协议。对于未在部署应用程序时命名其端口的用户，此要求可能会引起问题。
从 1.3 开始，如果未按照 Istio 的约定命名端口，则出站流量协议将自动检测为 HTTP 或 TCP。我们会在即将发布的版本中完善此功能，并支持对入站流
量的协议嗅探以及识别 HTTP 以外的协议。

## 无 Mixer 的遥测（实验性）{#mixer-less-telemetry-experimental}

是的，你看的没错！我们直接在 Envoy 中实实现了大多数常见的安全策略，例如 RBAC。我们以前默认关闭 `istio-policy` 服务，现在可以将大多数 Mixer 遥测功
能迁移到 Envoy。在此版本中，我们增强了 Istio 代理，以直接向 Prometheus 发送 HTTP 指标，而无需该 `istio-telemetry` 服务来完善信息。如果您只关
心 HTTP 服务的遥测，则此增强功能非常有用。请按照[无 Mixer 的 HTTP 遥测概述](https://github.com/istio/istio/wiki/Mixerless-HTTP-Telemetry)进行操作，以试用此功能。在接下来的几个月里，我们将加强此功能，以便在您启用 Istio 双向 TLS 时增加对 TCP 服务的遥测支持。

## 不再需要容器端口{#container-ports-are-no-longer-required}

以前的版本中，作为一项安全措施，要求 Pod 明确声明每个容器的 `containerPort`。Istio 1.3 有一种安全和简单的方法，可以将任何端口上的所有入站流量处
理为 {{< gloss "workload instance" >}}工作负载实例{{< /gloss >}}，而无需声明 `containerPort`。当工作负载实例向自己发送流量时，我们还完全消除了 IP 表
规则中造成的无限循环。

## 完全自定义生成 Envoy 配置{#fully-customize-generated-Envoy-configuration}

虽然 Istio 1.3 着重于可用性，但专家用户可以使用 Envoy 中的高级功能，这些功能不属于 Istio Networking API。
我们增强了 `EnvoyFilter` API，以允许用户完全自定义：

- LDS 返回 HTTP/TCP 侦听器及其过滤器链
- RDS 返回 Envoy HTTP 路由配置
- CDS 返回集群集

您可以从这两个方面中获得优势：

利用 Istio 与 Kubernetes 集成，并以高效的方式处理大量 Envoy，同时还可以自定义生成
的 Envoy 配置，以满足基础设施内的特定需求。

## 其他增强{#other-enhancements}

- `istioctl` 增加了许多调试功能，可帮助您突出显示网格安装中的各种问题。可在 `istioctl` [参考页面](/zh/docs/reference/commands/istioctl/)
查看所有受支持功能的集合。

- 在此版本中，支持区域性的负载均衡也从实验级转变为默认级。Istio 现在利用现有的位置信息来确定负载均衡池的优先级，并将请求发送到最近的后端。

- 使用 Istio 双向 TLS 更好地支持 headless 服务。

- 我们通过以下方式增强了控制平面监控：

    - 添加新指标以监视配置状态
    - 添加 sidecar 注入相关的指标
    - 为 Citadel 添加了新的 Grafana 仪表板
    - 改进 Pilot 仪表板，以显示其他关键指标

- 添加 [Istio 部署模型概念](/zh/docs/ops/deployment/deployment-models/)以帮助您确定哪种部署模型适合您的需求。

- 更新[操作指南](/zh/docs/ops/)中的内容，并创建[包含所有故障排除内容的章节](/zh/docs/ops/common-problems)，以帮助您更快地找到所需信息。

与往常一样，很多事情发生在[社区会议](https://github.com/istio/community#community-meeting)上；你可以在每隔一个星期四的太平洋时间
上午 11 点加入我们。

Istio 的成长和成功归功于其 300 多家公司的 400 多个贡献者。
加入我们的 [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，帮助我们使 Istio 变得更好。

要加入讨论，请使用您的 GitHub 账号登录 [discuss.istio.io](https://discuss.istio.io) 并加入我们！
