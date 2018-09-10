---
title: Istio 0.2
weight: 99
icon: /img/notes.svg
---

## General

- **更新了配置模型**。Istio 在Kubernetes中运行时，使用 Kubernetes [自定义资源](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)模型来描述和存储其配置,现在可以使用 `kubectl` 命令选择性地管理配置。

- **多命名空间支持**。Istio 控制平面组件现在位于专用的 "istio-system" 命名空间中, Istio 可以管理其他非系统命名空间中的服务。

- **网格扩展**。初始支持将非 Kubernetes 服务（以 VM 和/或物理机的形式）添加到网格中,这是此功能的早期版本，并且存在一些限制（例如需要跨容器和 VM 的扁平网络）。

- **多环境支持**。最初支持将 Istio 与其他服务注册表结合使用，包括 Consul 和 Eureka。

- **自动注入 sidecar**。使用 Kubernetes 中的[Initializers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) alpha 功能，可以在部署时自动将 Istio sidecar 注入到Pod 中。

## 性能和质量

整个系统中有许多性能和可靠性改进,我们还没有考虑将 Istio 0.2 用于生产，但我们在这个方向上取得了很好的进展,以下是一些注意事项：

- **客户端缓存**。Envoy 使用的 Mixer 客户端库现在为 Check 调用和批处理 Report 调用提供缓存，大大减少了端到端开销。

- **避免热重启**。通过有效使用 LDS/RDS/CDS/EDS，大部分消除了热重启 Envoy 的需要。

- **减少内存使用**。显着减小了 sidecar 的 helper agent的内存占用，从 50Mb 降低到 7Mb。

- **改进的 Mixer 延迟**。Mixer 现在可以清楚地描述配置时间与请求时间计算，从而避免在请求时为初始请求执行额外的设置工作，从而提供更平滑的平均延迟,更好的资源缓存也有助于提高端到端性能。

- **减少出口流量的延迟**。我们现在直接从 sidecar 转发到外部服务。

## 流量管理

- **出口规则**。现在可以为出口流量指定路由规则。

- **新协议**。Mesh 范围内对 WebSocket 连接的支持，MongoDB 代理和 Kubernetes [Headless 服务](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)。

- **其他改进**。Ingress 正确支持 gRPC 服务，更好地支持健康检查和 Jaeger 跟踪。

## 遥测和增强策略

- **入口策略**。除了东西向流量支持 0.1 ,现在可以将策略应用于南北向流量。

- **支持TCP服务**。除了 0.1 中提供的 HTTP 级策略控制之外，0.2 还引入了 TCP 服务的策略控制。

- **新的Mixer API**。Envoy 用于与 Mixer 交互的 API 已经过全面重新设计，以提高稳健性，灵活性，并支持丰富的代理端缓存和批处理以提高性能。

- **新的 Mixer 适配器模型**。新的适配器组合模型通过模板添加全新的适配器类，可以更轻松地扩展Mixer,这个新模型将成为未来许多功能的基础构建模块,请参阅[适配器开发人员指南](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide)了解具体写适配器的方法。

- **改进的 Mixer 构建模型**。现在，构建包含自定义适配器的 Mixer 二进制文件变得更加容易。

- **Mixer 适配器更新**。所有内置适配器都已重写，以适应新的适配器型号,已为此版本添加了 `stackdriver` 适配器,实验性 redis 配额适配器已在 0.2 版本中删除，但预计将在 0.3 版本中恢复生产质量。

- **Mixer 呼叫跟踪**。现在可以在 Zipkin 仪表板中跟踪和分析 Envoy 和 Mixer 之间的调用。

## 安全

- **TCP 流量的双向 TLS**。除 HTTP 流量外，TCP 流量现在也支持相互 TLS。

- **虚拟机和物理机的身份配置**。`Auth` 支持使用每节点代理进行身份配置的新机制,此代理在每个节点（VM /物理机）上运行，并负责生成和发送 CSR（证书签名请求）以从 Istio CA 获取证书。

- **带上您自己的CA证书**。允许用户为 Istio CA 提供自己的密钥和证书。

- **持久性CA密钥/证书存储**。Istio CA 现在将签名密钥/证书存储在持久存储中以便于 CA 重新启动。

## 已知的问题

- **用户在访问应用程序时可能会获得定期404**:  我们注意到 Envoy 偶尔不会正确获取路由，因此 404 会返回给用户,我们正积极致力于[问题](https://github.com/istio/istio/issues/1038)。

- **在Pilot实际准备就绪之前，Istio Ingress 或 Egress 报告已准备就绪**：您可以在 `istio-system` 命名空间中检查 istio-ingress 和 istio-egress pods 状态，并在所有 Istio pod 达到就绪状态后等待几秒钟,我们正积极致力于[问题](https://github.com/istio/istio/pull/1055)。

- **启用了 `Istio Auth` 的服务无法与没有 Istio 的服务通信**：此限制将在不久的将来删除。
