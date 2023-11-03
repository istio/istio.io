---
title: “为 Istio 环境服务网格引入基于 Rust 的 Ztunnel"
description: 专门为 Istio Ambient Mesh 构建的每节点代理。
publishdate: 2023-02-28
attribution: "Lin Sun (Solo.io), John Howard (Google)"
keywords: [istio,ambient,ztunnel]
---

Ztunnel（零信任隧道）组件是专门为 Istio Ambient Mesh 的每个节点构建的代理。
Ztunnel 负责在 Ambient Mesh 中安全地连接和验证工作负载，
专门为 Ambient Mesh 中的工作负载处理 mTLS、身份验证、L4 授权和遥测等这部分功能，
这样就无需终止工作负载 HTTP 流量或解析工作负载 HTTP 标头。
Ztunnel 确保流量高效、安全地传输到 waypoint proxy，从而实现 HTTP 遥测和负载均衡等 Istio 的全套功能
由于 Ztunnel 被设计为在所有 Kubernetes 工作节点上运行，所以保持其资源占用小是至关重要的。Ztunnel 被设计为服务网格的一个无形的部分，对您的工作负载几乎没有影响。

## Ztunnel 架构{#ztunnel-architecture}

与 Sidecar 类似，Ztunnel 也充当 xDS 客户端和 CA 客户端：

1. 在启动期间，它使用服务账户令牌。一旦从 Ztunnel 到 Istiod 的连接使用 TLS 建立连接，它就开始作为一个 xDS 客户端获取 xDS 配置。
    这种工作方式类似于 Sidecar 或 Gateway 或 waypoint proxy，只是 Istiod 识别来自 Ztunnel 的请求，并为 Ztunnel 发送特制的 xDS 配置。
    并发送专门为 Ztunnel 设计的 xDS 配置，您将很快了解到更多。
1. 它还充当 CA 客户端，代表其管理的所有位于同一位置的工作负载管理和提供 mTLS 证书。
1. 当流量输入或输出时，它充当核心代理，为其管理的所有位于同一位置的工作负载处理入站和出站流量（网格外纯文本或网格内HBONE）。
1. 它提供 L4 遥测（指标和日志）以及带有调试信息的管理服务器，以帮助您在需要时调试 Ztunnel。

{{< image width="100%"
    link="ztunnel-architecture.png"
    caption="ztunnel architecture"
    >}}

## 为什么不重用 Envoy?{#why-not-reuse-envoy}

当 Istio 环境服务网格于 2022 年 9 月 7 日发布时，Ztunnel 是使用 Envoy 代理实现的。
鉴于我们将 Envoy 用于 Istio 的其余部分（Sidecar、Gateway 和 waypoint proxy），
我们很自然地开始使用 Envoy 实现 Ztunnel。

然而，我们发现，虽然 Envoy 非常适合其他用例，但在 Envoy 中实现 Ztunnel 是一个挑战，
因为许多权衡、需求和用例与 Sidecar 代理或入口网关的情况有着显著的不同。
此外，使 Envoy 非常适合那些其他用例的大部分东西，如其丰富的 L7 特性集和可扩展性，
在不需要这些特性的 Ztunnel 中被浪费了。

## 一个特制的 Ztunnel{#a-purpose-built-ztunnel}

在 Envoy 难以满足我们的需求后，我们开始研究如何实现 Ztunnel。
我们的假设是，从一开始就着眼于单一的用例设计，这样可以开发一个更简单、更高性能的解决方案，
而不是根据我们定制的用例来塑造一个通用的项目。使 Ztunnel 变得简单的明确决定是这一假设的关键；
例如，类似的逻辑无法支持重写网关，因为重写时需要大量受支持的功能和集成。

这个专门特制的 Ztunnel 涉及两个关键领域：

* Ztunnel 及其 Istiod 之间的配置协议

* Ztunnel 的运行时实现

### 配置协议{#configuration-protocol}

Envoy 代理使用 [xDS 协议进行配置](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol)，
这是 Istio 工作良好的关键部分，它提供了丰富的动态配置更新。然而，随着我们走出老路，配置变得越来越定制，
这意味着它的规模更大，生成成本也更高。在一个 Sidecar 中，一个带有 1 个 Pod 的服务生成大约 350 行 xDS（在 YAML 中），
这在规模上已经具有挑战性。基于 Envoy 的 Ztunnel 要糟糕得多，在某些区域具有 N^2 级的扩缩属性。

为了使 Ztunnel 配置尽可能小，我们研究了使用专门构建的配置协议，该协议以有效的格式精确地包含我们所需的信息（仅此而已）。
例如，一个 Pod 可以被简洁地表示出来。

{{< text yaml >}}
name: helloworld-v1-55446d46d8-ntdbk
namespace: default
serviceAccount: helloworld
node: ambient-worker2
protocol: TCP
status: Healthy
waypointAddresses: []
workloadIp: 10.244.2.8
canonicalName: helloworld
canonicalRevision: v1
workloadName: helloworld-v1
workloadType: deployment
{{< /text >}}

它的信息通过 xDS 传输 API 传输，但使用自定义环境特定类型。
请参阅[工作负载 xDS 配置](#workload-xds-configuration)一节，以了解有关配置详情。

通过使用专门构建的 API，我们可以将逻辑推送到代理中，而不是在 Envoy 配置中。
例如，要在 Envoy 中配置 mTLS，我们需要添加一组相同的大型配置，以调整每个服务的精确 TLS 设置；
使用 Ztunnel，我们只需要一个枚举来声明是否应该使用 mTLS。其余的复杂逻辑直接嵌入 Ztunnel 代码中。

通过 Istiod 和 Ztunnel 之间的这个高效 API，我们发现我们可以使用有关大型网格（例如具有 100000 个 Pod 的网格）
的信息来配置 Ztunnel，配置数量级更少，这意味着更少的 CPU、内存和网络成本。

### 运行时的实现{#runtime-implementation}

顾名思义，Ztunnel 使用 [HTTPS 隧道](/zh/blog/2022/introducing-ambient-mesh/#building-an-ambient-mesh)来承载用户请求。
虽然 Envoy 支持这种隧道，但我们发现其配置模式对我们的需求有限制。
粗略地说，Envoy 的操作是通过一系列的"过滤器"来发送请求，从接受请求开始，到发送请求结束。
由于我们的需求有多层请求（隧道本身和用户的请求），以及需要在负载均衡后应用每个节点的策略，
我们发现在实现我们之前基于 Envoy 的 Ztunnel 时，我们需要在每个连接中循环通过这些过滤器4次。
虽然 Envoy 有[一些优化](https://www.envoyproxy.io/docs/envoy/latest/configuration/other_features/internal_listener)，
基本上是在内存中 “向自己发送一个请求"，但这仍然是非常复杂和昂贵。

通过建立我们自己的实现，我们可以从头开始围绕这些限制进行设计。
此外，我们在设计的各个方面都有更大的灵活性。例如，我们可以选择跨线程共享连接，或者围绕服务账户之间的隔离实现更多定制的要求。
在确定了一个特制的代理是可行的之后，我们开始选择实施细节。

#### 基于 Rust 的 Ztunnel{#a-rust-based-ztunnel}

为了使 Ztunnel 快速、安全、轻便，[Rust](https://www.rust-lang.org/) 是一个明显的选择。
然而，这不是我们的第一次。考虑到 Istio 目前广泛使用 Go 语言，我们希望能够使基于 Go 的实现满足这些目标。
在最初的原型中，我们构建了一些基于 Go 的实现和基于 Rust 的实现的简单版本。
从我们的测试中，我们发现基于 Go 的版本不符合我们的性能和占地面积要求。
虽然我们可能已经进一步优化了它，但我们觉得基于 Rust 的代理将为我们提供长期的最佳实现。

还考虑了 C++ 语言实现——可能重用 Envoy 的部分。然而，由于缺乏内存安全性、开发人员体验问题以及行业普遍倾向于 Rust，因此没有采用此选项。

这个淘汰过程给我们留下了 Rust，这是一个完美的选择。
Rust 在高性能、低资源利用率的应用程序，特别是在网络应用程序（包括服务网格）中有着悠久的历史。
我们选择在 [Tokio](https://tokio.rs/)和[Hyper](https://hyper.rs/) 库上构建，
这是生态系统中的两个事实上的标准，经过了广泛的实战测试，易于编写高性能异步代码。

## 快速浏览基于 Rust 的 Ztunnel{#a-quick-tour-of-rust-based-ztunnel}

### 工作负载 xDS 配置{#workload-xds-configuration}

工作负载 xDS 配置非常容易理解和调试。您可以通过从 Ztunnel Pod 之一向 `localhost:15000/config_dump` 发送请求来查看它们，
或者使用方便的 `istioctl pc workload` 命令。有两个关键的工作负载 xDS 配置：工作负载和策略。

在您的工作负载被纳入 Ambient Mesh 之前，您仍然能够在 Ztunnel 的配置转储中看到它们，
因为 Ztunnel 知道所有工作负载，无论它们是否启用环境。
例如，下面包含一个新部署的 helloworld v1 pod 的示例工作负载配置，该 Pod 脱离了 `protocol:TCP` 所指示的网格：

{{< text plaintext >}}
{
  "workloads": {
    "10.244.2.8": {
      "workloadIp": "10.244.2.8",
      "protocol": "TCP",
      "name": "helloworld-v1-cross-node-55446d46d8-ntdbk",
      "namespace": "default",
      "serviceAccount": "helloworld",
      "workloadName": "helloworld-v1-cross-node",
      "workloadType": "deployment",
      "canonicalName": "helloworld",
      "canonicalRevision": "v1",
      "node": "ambient-worker2",
      "authorizationPolicies": [],
      "status": "Healthy"
    }
  }
}
{{< /text >}}

当 Pod 包含在环境中后（通过将命名空间默认值标记为 `istio.io/dataplane mode=ambient`），
`protocol` 值替换为 `HBONE`，指示 Ztunnel 将 helloworld-v1 pod 中的所有传入和传出通信升级为 HBONE 。

{{< text plaintext >}}
{
  "workloads": {
    "10.244.2.8": {
      "workloadIp": "10.244.2.8",
      "protocol": "HBONE",
      ...
}
{{< /text >}}

部署任何工作负载级别授权策略后，策略配置将作为 xDS 配置从 Istiod 推送到 Ztunnel ，并显示在 `policies` 下：

{{< text plaintext >}}
{
  "policies": {
    "default/hw-viewer": {
      "name": "hw-viewer",
      "namespace": "default",
      "scope": "WorkloadSelector",
      "action": "Allow",
      "groups": [[[{
        "principals": [{"Exact": "cluster.local/ns/default/sa/sleep"}]
      }]]]
    }
  }
  ...
}
{{< /text >}}

您还将注意到工作负载的配置是参照授权策略更新的。

{{< text plaintext >}}
{
  "workloads": {
    "10.244.2.8": {
    "workloadIp": "10.244.2.8",
    ...
    "authorizationPolicies": [
        "default/hw-viewer"
    ],
  }
  ...
}
{{< /text >}}

### 由 Ztunnel 提供的 L4 遥测数据 {#l4-telemetry-provided-by-ztunnel}

您可能会惊喜地发现 Ztunnel 的日志很容易理解。
例如，您会看到目的地 Ztunnel 上的 HTTP 连接请求，表明源 Pod IP（`peer_ip`）和目的地 Pod IP。

{{< text plaintext >}}
2023-02-15T20:40:48.628251Z  INFO inbound{id=4399fa68cf25b8ebccd472d320ba733f peer_ip=10.244.2.5 peer_id=spiffe://cluster.local/ns/default/sa/sleep}: Ztunnel::proxy::inbound: got CONNECT request to 10.244.2.8:5000
{{< /text >}}

您可以通过访问 `localhost:1502/metrics` API 来查看工作负载的 L4 指标，
该 API 提供了一组完整的 TCP [标准指标](/zh/docs/reference/config/metrics/)，其标签与 Sidecar 公开的标签相同。例如：

{{< text plaintext >}}
istio_tcp_connections_opened_total{
  reporter="source",
  source_workload="sleep",
  source_workload_namespace="default",
  source_principal="spiffe://cluster.local/ns/default/sa/sleep",
  destination_workload="helloworld-v1",
  destination_workload_namespace="default",
  destination_principal="spiffe://cluster.local/ns/default/sa/helloworld",
  request_protocol="tcp",
  connection_security_policy="mutual_tls"
  ...
} 1
{{< /text >}}

如果您安装 Prometheus 和 Kiali，您可以从 Kiali 的 UI 轻松查看这些指标。

{{< image width="100%"
    link="kiali-ambient.png"
    caption="Kiali dashboard - L4 telemetry provided by Ztunnel"
    >}}

## 结束语{#wrapping-up}

我们超级兴奋的是新的[基于 Rust 的 Ztunnel](https://github.com/istio/Ztunnel/) 比之前基于 Envoy 的 Ztunnel 大大简化，
更加轻巧，性能更强。通过为基于 Rust 的 Ztunnel 特意设计的工作负载 xDS，您不仅能更容易地理解 xDS 的配置，而且还能大幅减少
Istiod 控制平面和 Ztunnel 之间的网络流量和成本。随着 Istio Ambient 模式现在合并到上游主站，
您可以按照我们的[入门指南](/zh/docs/ops/ambient/getting-started/)尝试新的基于 Rust 的 Ztunnel。
