---
title: 配置范围
description: 展示如何确定 Istio 中的配置范围，以获得运营和性能优势。
weight: 60
keywords: [scalability]
owner: istio/wg-networking-maintainers
test: no
---

为了对服务网格进行编程，Istio 控制平面（Istiod）会读取各种配置，
包括如 `Service` 和 `Node` 之类的核心 Kubernetes 类型，
以及如 `Gateway` 这样的 Istio 自身的类型。
然后将它们发送到数据平面（有关更多信息，请参阅[架构](/zh/docs/ops/deployment/architecture/)）。

默认情况下，控制平面将读取所有命名空间中的所有配置。
每个代理实例也将接收所有命名空间的配置。这包括未在网格中注册的工作负载的信息。

此默认值可确保开箱即用的正确行为，但会带来可扩展性成本。
每个配置都需要一定的成本（主要是 CPU 和内存）来维护和保持其更新。
在大规模情况下，限制配置范围以避免过多的资源消耗至关重要。

## 范围机制 {#scoping-mechanisms}

Istio 提供了一些工具来帮助控制配置范围以满足不同的用例。
根据您的要求，这些范围可以单独使用或一起使用。

* `Sidecar` 为特定工作负载提供了一种机制来**导入**一组配置
* `exportTo` 提供了一种将配置**导出**到一组工作负载的机制
* `discoverySelectors` 提供了一种机制让 Istio 完全忽略一组配置

### `Sidecar` 导入 {#sidecar-import}

`Sidecar` 中的 [`egress.hosts`](/zh/docs/reference/config/networking/sidecar/#IstioEgressListener)
字段允许指定要导入的配置列表。受 `Sidecar` 资源影响的 Sidecar 只能看到符合指定条件的配置。

例如：

{{< text yaml >}}
apiVersion: networking.istio.io/idecar
metadata:
  name: default
spec:
  egress:
  - hosts:
    - "./*" # 从我们自有命名空间导入所有配置
    - "bookinfo/*" # 从 bookinfo 命名空间导入所有配置
    - "external-services/example.com" # 仅从 external-services 命名空间导入 'example.com'
{{< /text >}}

### `exportTo` {#exportto}

Istio 的 `VirtualService`、`DestinationRule` 和 `ServiceEntry`
提供了 `spec.exportTo` 字段。同样，`Service` 可以使用 `networking.istio.io/exportTo` 注解进行配置。

与允许工作负载所有者控制其依赖项的 `Sidecar` 不同，
`exportTo` 以相反的方式工作，并允许服务所有者控制自己服务的可见性。

例如，此配置使 `details` `Service` 仅对其自己的命名空间和 `client` 命名空间可见：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: details
  annotations:
    networking.istio.io/exportTo: ".,client"
spec: ...
{{< /text >}}

### `DiscoverySelectors` {#discoveryselectors}

虽然以前的控制操作在工作负载或服务所有者级别上运行，
但 [`DiscoverySelectors`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)
提供了对配置可见性的网格范围控制。发现选择器允许指定命名空间对控制平面可见的标准。
任何不匹配的命名空间都会被控制平面完全忽略。

这可以在安装过程中被配置为 `meshConfig` 的一部分。例如：

{{< text yaml >}}
meshConfig:
  discoverySelectors:
    - matchLabels:
        # 允许在任何命名空间使用 `istio-discovery=enabled`
        istio-discovery: enabled
    - matchLabels:
        # 允许“kube-system”；Kubernetes 会自动将此标签添加到每个命名空间
        kubernetes.io/metadata.name: kube-system
{{< /text >}}

{{< warning >}}
Istiod 将始终向 Kubernetes 开放所有命名空间的监视。
然而，发现选择器将忽略在处理早期未选择的对象，从而最大限度地降低成本。
{{</ warning >}}

## 常见问题 {#frequently-asked-questions}

### 我该如何了解某种配置的成本？ {#how-can-i-understand-the-cost-of-a-certain-configuration}

为了获得缩小配置范围的最佳投入回报，了解每个对象的成本会很有帮助。
不幸的是，没有一个简单的答案。可扩展性取决于很多因素。但是，有一些一般准则：

在 Istio 中，配置**更改**的成本很高，因为它们需要重新计算。
虽然 `Endpoints` 更改（通常来自 Pod 向上或向下扩展）经过了大量优化，
但大多数其他配置的代驾都相当高昂。当控制器不断地对对象进行更改时，
这可能特别有害（有时这种情况是意外发生的！）。有一些用于检测哪些配置正在更改的工具：
* Istiod 将记录每个更改，例如：`Push debounce stable 1 for config Gateway/default/gateway: ..., full=true`。
  这会展示 `default` 命名空间中的 `Gateway` 对象已被更改。
  `full=false` 将表示并优化例如 `Endpoint` 的更新。
  注意：对 `Service` 和 `Endpoints` 的更改都将已 `ServiceEntry` 进行展示。
* Istiod 会通过 `pilot_k8s_cfg_events` 和 `pilot_k8s_reg_events` 暴露每次变更的指标。
* `kubectl get <resource> --watch -oyaml --show-managed-fields` 可以展示对一个或多个对象的更改，
  以帮助了解正在更改的内容以及更改者。

[无头服务（Headless Services）](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#headless-services)
（除了被声明为 [HTTP](/zh/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)）随着实例数量的变化而增减。
这使得大型无头服务变得代价高昂，并且是使用 `exportTo` 或等效项排除的良好候选者。

### 如果我连接到我设置的范围之外的服务会发生什么？ {#what-happens-if-i-connect-to-a-service-outside-of-my-scope}

当连接到已通过范围机制之一排除的服务时，数据平面将不知道有关目标的任何信息，
因此它将被视为[未匹配的流量](/zh/docs/ops/configuration/traffic-management/traffic-routing/#unmatched-traffic)。

### 针对网关怎么样？ {#what-about-gateways}

虽然[网关](/zh/docs/setup/additional-setup/gateway/)将遵循 `exportTo`
和 `DiscoverySelectors`，但 `Sidecar` 对象不会影响网关。
然而，与 Sidecar 不同的是，网关默认没有整个集群的配置。
相反，每个配置都显式附加到网关，这在很大程度上避免了这个问题。

然而，[目前](https://github.com/istio/istio/issues/29131) 数据平面配置的一部分
（用 Envoy 术语来说是“集群”）总是为整个集群发送，即使它没有被明确引用。
