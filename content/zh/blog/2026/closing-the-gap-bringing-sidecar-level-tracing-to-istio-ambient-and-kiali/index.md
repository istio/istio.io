---
title: "弥合差距：借助 Kiali 为 Istio Ambient 模式带来 Sidecar 级别的链路追踪"
description: 随着 Istio 1.29 和 Kiali 2.25 的发布，Ambient 模式与 Sidecar 模式的链路追踪能力实现对等，弥合了工作负载可见性方面的差距。
publishdate: 2026-10-20
attribution: "Josune Córdoba; Translated by Wilson Wu (DaoCloud)"
keywords: [istio, ambient, tracing, kiali, telemetry, observability]
target_release: "1.30"
---

Istio 的 Ambient 模式在最近几个版本中持续稳步演进。
尽管它已在 1.24 版本中正式发布（GA），
但随着后续版本中各项功能的变化和趋于稳定，其行为也在不断演变。
随着 Istio 1.29 和 Kiali 2.25 的发布，
我们现在可以自信地说，Ambient 模式下的链路追踪已与 Sidecar 模式完全对等。

## waypoint 代理的作用 {#the-role-of-waypoint-proxies}

作为背景，需要注意的是，L7 遥测数据（包括指标和链路追踪）
均由 **[waypoint 代理](/zh/docs/ambient/overview/#waypoint-proxies)**提供。
在 Sidecar 模式下，代理与应用程序位于同一个 Pod 中；
而 waypoint 则是一种共享的、解耦的资源，
其作用范围可以是一个命名空间、一个服务，甚至是特定的工作负载。
它充当其所处理流量的“守门人”，负责处理所有 L7 逻辑。
相比之下，Ambient 节点代理 [ztunnel](/zh/docs/ambient/overview/#ztunnel)
仅在 L4 运行，因此无法生成 L7 遥测数据。

{{< image width="90%" link="./waypoint-traffic-graph.png" caption="处理流量的 waypoint - Kiali 流量图视图" >}}

## 身份的转变：从服务到 waypoint {#the-shift-in-identity-from-service-to-waypoint}

由于 waypoint 代理位于工作负载外部，
确定一条链路追踪的“归属者”一直是一项架构上的挑战。
在 Istio 1.27 中，waypoint 代理在创建链路追踪时，
会将 **waypoint 名称**用作服务名。

{{< image width="90%" link="./service-traces-istio-127.png" caption="Istio 1.27 中的服务链路追踪" >}}

Istio 1.28 引入了一项变更，将链路追踪直接归属于目标服务，
而不是 waypoint。这一行为在 1.29 的各个版本中一直保持不变。

{{< tip >}}
请注意，这一转变仅适用于 OpenTelemetry（OTel）提供程序；
Zipkin 等传统格式仍继续使用 waypoint 的身份。
{{< /tip >}}

{{< image width="90%" link="./service-traces-istio-129.png" caption="Istio 1.29 中的服务链路追踪" >}}

Istio 1.30 将 waypoint 视为“一等公民”，进一步完善了这一状况。
现在，waypoint 既如实保留了这一跳在架构上的存在，又不会使真正的目标变得模糊。
其中，Span 的**操作名称**能够正确反映被重定向的服务流量，
而**基础设施元数据**则指向 waypoint。

{{< image width="90%" link="./service-traces-istio-130.png" caption="Istio 1.30 中的服务链路追踪" >}}

## 缺失的一环：工作负载可见性 {#the-missing-link-workload-visibility}

虽然服务到服务的链路追踪已经能够正常工作，
但仍存在一个明显的缺口：工作负载级别的粒度。
在 Sidecar 模式下，我们依靠 `node_id` 属性来识别具体的 Pod。
而在 Ambient 模式下，这一信息是缺失的。
如果某个服务将流量路由到某个工作负载的多个版本（例如 v1、v2 和 v3），
我们虽然能够看到服务这一跳，却无法精确定位究竟是哪个具体的工作负载在处理请求，
从而丢失了重要的调试信息。

{{< image width="90%" link="./workload-visibility-gap.png" caption="缺少工作负载信息导致可追溯性不完整" >}}

这一缺口已在 Istio 1.29 中得到弥合。
通过引入 `istio.source_workload` 和 `istio.destination_workload` 等显式属性，
并利用 waypoint 所处的特殊“中间人”位置，
我们现在可以完整地看到请求的来源和最终目标。

{{< image width="90%" link="./span-attributes-trace.png" caption="一条链路追踪中的 span 属性" >}}

## Kiali：统一的可观测性平面 {#kiali-the-unified-observability-plane}

[Kiali](https://kiali.io/) 是 Istio 服务网格的控制台。
它通过将指标、链路追踪和配置关联到同一个视图中，
帮助您对网格进行配置、可视化、验证和故障排查。

那么，这些链路追踪方面的改进在 Kiali 中是如何体现的呢？
得益于这些新属性，Kiali 的 **Trace Overlay**（链路追踪叠加）功能比以往任何时候都更加强大。
选中一条链路追踪时，Kiali 会高亮显示整个请求路径，
包括所涉及的服务和具体的工作负载，
从而在版本化应用图（Versioned App Graph）中完整呈现该链路追踪的视图。

Kiali 基于指标数据构建流量图，指标数据提供了拓扑结构，
并以可视化的方式展示请求如何在网格中流转。
随后，Trace Overlay 功能会利用所选的链路追踪，
高亮显示属于该特定请求路径的节点和边。
换句话说，指标提供了图的结构，
而链路追踪则确定了请求在该结构中实际经过的确切路线。

这一过程是逐跳进行的。所选的链路追踪提供了一系列 Span，
而现在每个 Span 都包含能够标识该跳所涉及的服务和工作负载的属性。
借助这些信息，Kiali 可以将每个 Span 与版本化应用图中的相应元素进行匹配，
并重建请求的完整路径，包括实际处理该流量的具体工作负载版本。

{{< image width="90%" link="./kiali-trace-overlay.png" caption="Kiali 链路追踪叠加" >}}

Kiali 的使命之一是简化故障排查。在 Workload Details（工作负载详情）视图中，
Kiali 会自动关联数据，因此您无需再手动搜寻隐藏在 waypoint 名称下的链路追踪。
它会识别与工作负载关联的 waypoint，查询链路追踪提供程序，并为您过滤结果。

{{< image width="90%" link="./kiali-service-details-traces.png" caption="Kiali 服务详情页面中的服务链路追踪" >}}

默认情况下，Kiali 使用服务名称来查找链路追踪，但您可以对这一行为进行微调。
如果您的环境有此需要（取决于 Istio 版本以及是否使用 Ambient 模式），
您可以通过将 Kiali 配置项 `external_services.tracing.use_waypoint_name` 设置为 `true`，
来配置 Kiali 映射这些身份的方式。

除了可视化之外，这种遥测数据的丰富还为更多高级能力打开了大门。
借助整个网格中一致的链路追踪和指标，
Kiali 的 AI 驱动功能（包括 [Kiali 助手](https://kiali.io/docs/ai/kiali-chatbot/)）
现在能够更准确地协助进行根因分析。
当拼图的所有碎片都已就位时，
该助手便能主动识别您的 Ambient 网格中的瓶颈或错误配置，
将原始的可观测性数据转化为自动化的智能洞察。

{{< image width="90%" link="./kiali-chatbot-trace-overview.png" caption="Kiali 助手基于当前上下文提供链路追踪概览" >}}

{{< quote >}}
随着 Istio 的不断成熟，Kiali 确保迁移到 Ambient 模式并不意味着失去掌控。
它补全了拼图，让您可以专注于自己的服务，
而由 Kiali 来处理网格中错综复杂的映射关系。
{{< /quote >}}

本文的一个版本最初发布于 [Medium 上的 Kiali 博客](https://medium.com/kialiproject/closing-the-gap-bringing-sidecar-level-tracing-to-istio-ambient-and-kiali-817b1f9bc61d)。
欢迎在那里关注我们，以获取更频繁的更新。
