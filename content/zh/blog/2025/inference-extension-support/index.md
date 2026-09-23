---
title: "将 AI 感知流量管理引入 Istio：Gateway API 推理扩展支持"
description: 以一种基于实时指标和推理工作负载的独特特性来优化 AI 流量路由的更智能、动态的方法。
publishdate: 2025-07-28
attribution: "Lior Lieberman (Google), Keith Mattix (Microsoft), Aslak Knutsen (Red Hat); Translated by Wilson Wu (DaoCloud)"
keywords: [istio,AI,inference,gateway-api-inference-extension]
---

Kubernetes 上的 AI 推理领域面临着独特的挑战，而传统的流量路由架构并非为此而设计。
尽管 Istio 长期以来凭借其先进的负载均衡、安全性和可观测性功能，
在管理微服务流量方面表现出色，但大型语言模型（LLM）工作负载的需求需要专门的功能。

这就是为什么我们很高兴地宣布 Istio 支持 Gateway API 推理扩展，
为 Istio 带来智能、模型感知和 LoRA 感知路由。

## 为什么 AI 工作负载需要特殊处理 {#why-ai-workloads-need-special-treatment}

传统的 Web 服务通常处理以毫秒为单位的快速、无状态请求。
而 AI 推理工作负载则以完全不同的模式运行，这在几个根本方面对传统的负载平衡方法提出了挑战。

### 规模和持续时间的挑战 {#the-scale-and-duration-challenge}

与典型的 API 响应（以毫秒为单位）不同，
AI 推理请求的处理时间通常要长得多 - 有时甚至需要几秒钟甚至几分钟。
这种处理时间的巨大差异意味着路由决策的影响远大于传统的 Web 服务。
一个路由不当的请求可能会长时间占用昂贵的 GPU 资源，从而对整个系统造成连锁反应。

负载特性同样具有挑战性。AI 推理请求通常涉及更大的负载，
尤其是在处理检索增强生成（RAG）系统、包含大量上下文的多轮对话，
或包含图像、音频或视频等多模态输入时。这些大型负载需要与传统
HTTP API 不同的缓冲、流式传输和超时策略。

### 资源消耗模式 {#resource-consumption-patterns}

或许最关键的是，单个推理请求在处理过程中可能会消耗掉整个 GPU 的资源。
这与传统的请求服务有着根本的不同，在传统的请求服务中，
多个请求可以在同一计算资源上同时处理。当 GPU 完全处理一个请求时，
其他请求必须排队，这使得调度和路由决策比标准 API 工作负载的决策更具影响力。

这种资源独占性意味着简单的循环或最小连接算法可能会造成严重的不平衡。
向正在处理复杂推理任务的服务器发送请求不仅会增加延迟，还可能导致资源争用，从而影响所有排队请求的性能。

### 状态考虑和内存管理 {#stateful-considerations-and-memory-management}

AI 模型通常会维护内存缓存，这会显著影响性能。
KV 缓存存储先前处理过的 Token 的中间注意力计算，在生成过程中是 GPU 内存的主要消耗者，
并且通常成为最常见的瓶颈。当 KV 缓存利用率接近极限时，性能会急剧下降，因此缓存感知路由至关重要。

此外，许多现代 AI 部署使用 [LoRA](https://arxiv.org/abs/2106.09685)（低秩自适应）等经过微调的适配器，
针对特定用户、组织或用例定制模型行为。这些适配器在切换时会消耗 GPU 内存并延长加载时间。
已加载所需 LoRA 适配器的模型服务器可以立即处理请求，
而未加载该适配器的服务器则面临高昂的加载开销，可能需要数秒才能完成。

### 队列动态和关键性 {#queue-dynamics-and-criticality}

AI 推理工作负载还引入了传统服务中不太常见的“请求关键性”概念。
实时交互式应用程序（例如聊天机器人或实时内容生成）需要低延迟，
因此应优先处理；而批处理作业或实验性工作负载则可以容忍更高的延迟，甚至在系统过载时被丢弃。

传统的负载均衡器缺乏根据关键性做出决策的上下文信息。
它们无法区分时间敏感的客户支持查询和后台批处理作业，导致在高峰需求期间资源分配不理想。

推理感知路由至关重要。我们不应该将所有后端视为等效的黑匣子，
而是需要制定能够理解每个模型服务器当前状态和功能的路由决策，
包括其队列深度、内存利用率、已加载的适配器以及处理不同关键级别请求的能力。

## Gateway API 推理扩展：Kubernetes 原生解决方案 {#gateway-api-inference-extension--a-kubernetes-native-solution}

[Kubernetes Gateway API 推理扩展](https://gateway-api-inference-extension.sigs.k8s.io)为这些挑战提供了解决方案，
它基于 Kubernetes Gateway API 成熟的基础架构，并添加了 AI 专属智能。
该扩展无需企业自行拼凑定制解决方案或放弃现有的 Kubernetes 基础架构，
而是提供了一种标准化、与供应商无关的智能 AI 流量管理方法。

该扩展引入了两个关键的自定义资源定义（CRD），它们协同工作以解决我们概述的路由挑战。
**InferenceModel** 资源为 AI 推理工作负载所有者提供了一个抽象概念，
用于定义逻辑模型端点；而 **InferencePool** 资源则为平台运营商提供了管理后端基础设施的工具，
并具备 AI 工作负载感知能力。

通过扩展熟悉的 Gateway API 模型，而非创建全新的范式，
推理扩展使组织能够利用其现有的 Kubernetes 专业知识，
同时获得 AI 工作负载所需的专业功能。这种方法确保团队能够采用与熟悉的网络知识和工具相一致的智能推理路由。

注意：InferenceModel 可能会在未来的 Gateway API 推理扩展版本中发生变化。

### InferenceModel

InferenceModel 资源允许推理工作负载所有者定义抽象后端部署复杂性的逻辑模型端点。

{{< text yaml >}}
apiVersion: inference.networking.x-k8s.io/v1alpha2
kind: InferenceModel
metadata:
  name: customer-support-bot
  namespace: ai-workloads
spec:
  modelName: customer-support
  criticality: Critical
  poolRef:
    name: llama-pool
  targetModels:
    - name: llama-3-8b-customer-v1
      weight: 80
    - name: llama-3-8b-customer-v2
      weight: 20
{{< /text >}}

此配置公开了一种客户支持模型，该模型可在两个后端变体之间智能路由，
从而能够安全推出新模型版本，同时保持服务可用性。

### InferencePool

InferencePool 充当专门的后端服务，可以了解 AI 工作负载的特征：

{{< text yaml >}}
apiVersion: inference.networking.x-k8s.io/v1alpha2
kind: InferencePool
metadata:
  name: llama-pool
  namespace: ai-workloads
spec:
  targetPortNumber: 8000
  selector:
    app: llama-server
    version: v1
  extensionRef:
    name: llama-endpoint-picker
{{< /text >}}

当与 Istio 集成时，该池会通过 Istio 的服务发现自动发现模型服务器。

## Istio 中的推理路由工作原理 {#how-inference-routing-works-in-istio}

Istio 的实现建立在服务网格久经考验的流量管理基础之上。
当请求通过 Kubernetes 网关进入网格时，它会遵循标准的网关 API HTTPRoute 匹配规则。
然而，它并非使用传统的负载均衡算法，而是由端点选择器（EPP）服务来选择后端。

EPP 评估多种因素来选择最佳后端：

* **请求关键性评估**：关键请求将优先路由到可用的服务器，而关键性较低的请求（标准或可削减）可能会在高利用率期间被负载削减。

* **资源利用率分析**：该扩展监控 GPU 内存使用情况，特别是 KV 缓存利用率，以避免接近容量限制的服务器不堪重负。

* **适配器亲和性**：对于使用 LoRA 适配器的模型，请求优先路由到已经加载所需适配器的服务器，从而消除昂贵的加载开销。

* **前缀缓存感知负载均衡**：路由决策考虑跨模型服务器的分布式 KV 缓存状态，并优先考虑缓存中已有前缀的模型服务器。

* **队列深度优化**：通过跟踪后端的请求队列长度，系统避免创建会增加整体延迟的热点。

这种智能路由在 Istio 现有架构内透明运行，
并保持与相互 TLS、访问策略和分布式链路追踪等功能的兼容性。

### 推理路由请求流程 {#inference-routing-request-flow}

{{< image width="100%"
    link="./inference-request-flow.svg"
    alt="具有 Gateway API 推理扩展路由的推理请求流程。"
    >}}

## 未来之路 {#the-road-ahead}

未来的路线图包括与 Istio 相关的功能，例如：

* **对 waypoint 的支持** - 随着 Istio 继续向 Ambient 网格架构发展，
  推理感知路由将集成到 waypoint 代理中，为 AI 工作负载提供集中的、可扩展的策略实施。

除了 Istio 特定的创新之外，Gateway API 推理扩展社区还积极开发多项高级功能，
这些功能将进一步增强 Kubernetes 上 AI 推理工作负载的路由：

* **HPA 集成 AI 指标**：基于特定于模型的指标（而不仅仅是 CPU 和内存）的水平 Pod 自动缩放。

* **多模式输入支持**：针对大型多模式输入和输出（图像、音频、视频）进行优化路由，具有智能缓冲和流媒体功能。

* **异构加速器支持**：跨不同加速器类型（GPU、TPU、专用 AI 芯片）的智能路由，具有延迟和成本感知负载平衡。

## Istio 推理扩展入门 {#getting-started-with-istio-inference-extension}

准备好尝试推理感知路由了吗？该实现已从 Istio 1.27 开始正式可用！

有关安装和指南，请遵循 [Gateway API 推理扩展网站上](https://gateway-api-inference-extension.sigs.k8s.io/guides/#__tabbed_3_2) Istio 特定的指南。

## 性能影响和收益 {#performance-impact-and-benefits}

早期评估表明，推理感知路由可显著提高性能，与传统负载平衡相比，
在更高查询率下 P90 延迟显著降低，端到端尾部延迟减少。

有关详细的基准测试结果和方法，请参阅使用 H100 GPU 和 vLLM 部署的测试数据进行的
[Gateway API 推理扩展性能评估](https://kubernetes.io/zh-cn/blog/2025/06/05/introducing-gateway-api-inference-extension/#benchmarks)。

与 Istio 现有基础设施的集成意味着这些好处只需极少的运营开销，
并且您现有的监控、安全和流量管理配置可以继续保持不变。

## 结论 {#conclusion}

Gateway API 推理扩展代表着 Kubernetes 在真正实现 AI 就绪方面迈出了重要一步，
而 Istio 的实现将这种智能带到了服务网格层，使其能够发挥最大作用。
通过将推理感知路由与 Istio 久经考验的安全性、可观测性和流量管理功能相结合，
我们使组织能够以与传统服务相同的卓越运营来运行 AI 工作负载。

---

**有疑问或想参与？[加入 Kubernetes Slack](https://slack.kubernetes.io/)，
然后在 [#gateway-api-inference-extension](https://kubernetes.slack.com/archives/C08E3RZMT2P) 频道上找到我们，
或者 [在 Istio Slack 上讨论](https://slack.istio.io)。**
