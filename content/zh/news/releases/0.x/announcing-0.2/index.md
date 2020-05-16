---
title: 宣布 Istio 0.2
linktitle: 0.2
description: Istio 0.2 公告。
publishdate: 2017-10-10
subtitle: 改善网格并支持多种环境
aliases:
    - /zh/blog/istio-0.2-announcement.html
    - /zh/about/notes/older/0.2
    - /zh/blog/2017/0.2-announcement
    - /zh/docs/welcome/notes/0.2.html
    - /zh/about/notes/0.2/index.html
    - /zh/news/2017/announcing-0.2
    - /zh/news/announcing-0.2
---

我在 2017 年 5 月 24 日发布了 Istio ，它是一个用于连接、管理、监控和保护微服务的开放平台。看着饱含浓厚兴趣的开发者、运营商、合作伙伴和不断发展的社区，我们感到十分的欣慰。我们 0.1 版本的重点是展示 Istio 在 Kubernetes 中的所有概念。

今天我们十分高兴地宣布推出 0.2 版本，它提高了稳定性和性能、允许在 Kubernetes 集群中广泛部署并自动注入 sidecar 、为 TCP 服务添加策略和身份验证、同时保证扩展网格收录那些部署在虚拟机中的服务。此外，Istio 可以利用 Consul/Nomad 或 Eureka 在 Kubernetes 外部运行。除了核心功能，Istio 的扩展已经准备由第三方公司和开发人员编写。

## 0.2 版本的亮点{#highlights-for-the-0.2-release}

### 可用性改进{#usability-improvements}

- _支持多命名空间_: Istio 现在可以跨多个名称空间在集群范围内工作，这也是来自 0.1 版本中社区最强烈的要求之一。

- _TCP 服务的策略与安全_: 除了 HTTP ，我们还为 TCP 服务增加了透明双向 TLS 认证和策略实施。这将让拥有像遥测，策略和安全等 Istio 功能的同时，保护更多 Kubernetes deployment 。

- _自动注入 sidecar_: 通过利用 Kubernetes 1.7 提供的 alpha [初始化程序](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) ，当您的集群启用了该程序时，envoy sidecar 就可以自动注入到应用的 deployment 里。这使得你可以使用 `kubectl` 命令部署微服务，这与您通常在没有 Istio 的情况下部署微服务的命令完全相同。

- _扩展 Istio_ : 改进的 Mixer 设计，可以允许供应商编写 Mixer 适配器以实现对其自身系统的支持，例如应用管理或策略实施。该 [Mixer 适配器开发指南](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide)可以轻松的帮你将 Istio 集成于你的解决方案。

- _使用您自己的 CA 证书_: 允许用户提供自己的密钥和证书给 Istio CA 和永久 CA 密钥/证书存储，允许在持久化存储中提供签名密钥/证书，以便于 CA 重启。

- _改进路由和指标_: 支持 WebSocket 、MongoDB 和 Redis 协议。您可以将弹性功能（如熔断器）应用于第三方服务。除了 Mixer 的指标外，数以百计 Envoy 指标现在已经在 Prometheus 中可见，它们用于监控 Istio 网格中的流量吞吐。

### 跨环境支持{#cross-environment-support}

- _网格扩展_: Istio 网格现在可以在 Kubernetes 之外跨服务 —— 就像那些运行在虚拟机中的服务一样，他们同时享受诸如自动双向 TLS 认证、流量管理、遥测和跨网格策略实施带来的好处。

- _运行在 Kubernetes 外部_: 我们知道许多客户使用其他的服务注册中心和 orchestration 解决方案（如 Consul/Nomad 和 Eureka），Istio Pilot 可以在 Kubernetes 外部单独运行，同时从这些系统中获取信息，并在虚拟机或容器中管理 Envoy fleet 。

## 加入到塑造 Istio 未来的队伍中{#get-involved-in-shaping-the-future-of-Istio}

呈现在我们面前的是一幅不断延伸的[蓝图](/zh/about/feature-stages/) ，它充满着强大的潜能。我们将在下个版本致力于 Istio 的稳定性，可靠性，第三方工具集成和多集群用例。

想要了解如何参与并为 Istio 的未来做出贡献，请查看我们在 GitHub 的[社区](https://github.com/istio/community)项目，它将会向您介绍我们的工作组，邮件列表，各种社区会议，常规流程和指南。

我们要感谢为我们测试新版本、提交错误报告、贡献代码、帮助其他成员以及通过参与无数次富有成效的讨论塑造 Istio 的出色社区，这让我们的项目自启动以来在 GitHub 上累积了 3000 颗星，并且在 Istio 邮件列表上有着数百名活跃的社区成员。

谢谢

## 发布说明{#release-notes}

### 通用{#general}

- **更新配置模型**。Istio 现在使用了 Kubernetes 的 [Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
来描述和存储其配置。当运行在 Kubernetes 上时，现在可以使用 `kubectl` 命令来管理配置。

- **多 namespace 的支持**。Istio 控制平面组件现在位于专用的 `istio-system` namespace 下。
Istio 可以管理其他非系统名称空间中的服务。

- **Mesh 扩展**。初步支持将非 Kubernetes 服务（以 VM 和/或 物理机的形式）添加到网格中。
这是此功能的早期版本，存在一些限制（例如，要求在容器和 VM 之间建立扁平网络）。

- **多环境的支持**。初步支持将 Istio 与其他服务注册表（包括 Consul 和 Eureka ）结合使用。

- **自动注入 Sidecar**。使用 Kubernetes 中的 [Initializers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) alpha 功能，可以在部署后将 Istio 边车自动注入到 Pod 中。

### 性能及品质{#performance-and-quality}

整个系统在性能和可靠性方面都有许多改进。
我们尚未考虑将 Istio 0.2 用于生产，但我们在这一方面取得了长足的进步。以下是一些注意事项：

- **缓存客户端**。现在，Envoy 使用的 Mixer 客户端库为 Check 调用提供了缓存，为 Report 调用提供了批处理，从而大大减少了端到端的开销。

- **避免热重启**。通过有效使用 LDS/RDS/CDS/EDS，基本上消除了 Envoy 需要热重启的情况。

- **减少内存使用**。大大减少了 Sidecar 辅助代理的大小，从 50Mb 减少到了 7Mb。

- **改善 Mixer 延迟**。Mixer 现在可以清楚地描述配置时间和请求时间的计算，这样可以避免在请求时针对初始请求进行额外的设置工作，从而提供更平滑的平均延迟。
更好的资源缓存还有助于提高端到端性能。

- **减少 Egress 流量的延迟**。现在，我们直接将流量从 sidecar 转发到外部服务。

### 流量管理{#traffic-management}

- **Egress 规则**。现在可以为 Egress 流量指定路由规则。

- **新协议**。Mesh-wide 现在支持 WebSocket 链接, MongoDB 代理,
和 Kubernetes [headless 服务](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)。

- **其它改进**。Ingress 正确支持 gRPC 服务，更好的支持健康检查和 Jaeger 追踪。

### 策略执行及遥测{#policy-enforcement-telemetry}

- **Ingress 策略**。除了 0.1 中支持的东西流量。现在，策略也可以应用于南北流量。

- **支持 TCP 服务**。除了 0.1 中可用的 HTTP 级策略控制外，0.2 还引入了 TCP 服务的策略控制。

- **新的 Mixer API**。Envoy 用于与 Mixer 进行交互的 API 已进行了完全重新设计，以提高健壮性，灵活性，并支持丰富的代理端缓存和批处理以提高性能。

- **新的 Mixer Adapter 模型**。新的适配器组合模型通过模板添加全新的适配器类，使扩展 Mixer 更容易。这种新模型将作为将来许多功能的基础构建块。
请参阅[适配器开发者指南](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide)以了解如何编写适配器。

- **改进 Mixer 构建模型**。现在，构建包含自定义适配器的 Mixer 二进制文件变得更加容易。

- **Mixer Adapter 更新**。内置适配器已全部重写以适合新的适配器模型。该版本已添加了 `stackdriver` 适配器。
实验性的 `redisquota` 适配器已从 0.2 版本中删除，但有望在 生产就绪的 0.3 版本中回归。

- **Mixer 调用追踪**。现在可以在 Zipkin 仪表板中跟踪和分析 Envoy 和 Mixer 之间的调用。

### 安全{#security}

- **TCP 流量的双向 TLS**。除了 HTTP 流量外，TCP 流量现在也支持双向 TLS。

- **VM 和物理机的身份配置**。Auth 支持使用每节点代理进行身份配置的新机制。
该代理在每个节点（VM /物理机）上运行，并负责生成和发送 CSR（证书签名请求）以从 Istio CA 获取证书。

- **使用自己的 CA 证书**。允许用户向 Istio CA 提供自己的密钥和证书。

- **永久性 CA 密钥/证书存储**。Istio CA 现在将签名密钥/证书持久化存储，以方便 CA 重新启动。

## 已知问题{#known-issues}

- **用户访问应用程序时可能会收到 404**：我们注意到，Envoy 有时无法正确获取路由，因此将 404 返回给用户。
我们正在对此[问题](https://github.com/istio/istio/issues/1038)进行积极的工作。

- **在真正准备就绪之前，Istio Ingress 或 Egress 就报告了准备就绪**：您可以在 `istio-system` 名称空间中检查 `istio-ingress` 和 `istio-egress` pod 的状态，并在所有 Istio pod 报告就绪状态后等待几秒钟。我们正在对此[问题](https://github.com/istio/istio/pull/1055)进行积极的工作。

- **启用了 Istio Auth 的服务无法与一个非 Istio 服务通信**：此限制将在不久的将来消除。
