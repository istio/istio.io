---
title: 配置范围
description: 展示如何确定 Istio 中的配置范围，以获得运营和性能优势。
weight: 60
keywords: [scalability]
owner: istio/wg-networking-maintainers
test: no
---

In order to program the service mesh, the Istio control plane (Istiod) reads a variety of configurations, including core Kubernetes types like `Service` and `Node`, and Istio's own types like `Gateway`. These are then sent to the data plane (see [Architecture](/docs/ops/deployment/architecture/) for more information).
为了对服务网格进行编程，Istio 控制平面 (Istiod) 读取各种配置，包括核心 Kubernetes 类型（如“Service”和“Node”）以及 Istio 自己的类型（如“Gateway”）。 然后将它们发送到数据平面（有关更多信息，请参阅[架构](/docs/ops/deployment/architecture/)）。

By default, the control plane will read all configuration in all namespaces. Each proxy instance will receive configuration for all namespaces as well. This includes information about workloads that are not enrolled in the mesh.
默认情况下，控制平面将读取所有命名空间中的所有配置。 每个代理实例也将接收所有命名空间的配置。 这包括有关未在网格中注册的工作负载的信息。

This default ensures correct behavior out of the box, but comes with a scalability cost. Each configuration has a cost (in CPU and memory, primarily) to maintain and keep up to date. At large scales, it is critical to limit the configuration scope to avoid excessive resource consumption.
此默认值可确保开箱即用的正确行为，但会带来可扩展性成本。 每个配置都需要一定的维护和更新成本（主要是 CPU 和内存）。 在大规模情况下，限制配置范围以避免过多的资源消耗至关重要。

## Scoping mechanisms
## 范围机制

Istio offers a few tools to help control the scope of a configuration to meet different use cases. Depending on your requirements, these can be used alone or together.
Istio 提供了一些工具来帮助控制配置范围以满足不同的用例。 根据您的要求，这些可以单独使用或一起使用。

* `Sidecar` provides a mechanism for specific workloads to _import_ a set of configurations
* `exportTo` provides a mechanism to _export_ a configuration to a set of workloads
* `discoverySelectors` provides a mechanism to let Istio completely ignore a set of configurations
* `Sidecar` 为特定工作负载提供了一种机制来_导入_一组配置
* `exportTo` 提供了一种将配置导出到一组工作负载的机制
* `discoverySelectors` 提供了一种机制让 Istio 完全忽略一组配置

### `Sidecar` import
### `Sidecar` 导入

The [`egress.hosts`](/docs/reference/config/networking/sidecar/#IstioEgressListener) field in `Sidecar` allows specifying a list of configurations to import. Only configurations matching the specified criteria will be seen by sidecars impacted by the `Sidecar` resource.
`Sidecar` 中的 [`egress.hosts`](/docs/reference/config/networking/sidecar/#IstioEgressListener) 字段允许指定要导入的配置列表。 受“Sidecar”资源影响的 sidecar 只能看到符合指定条件的配置。

For example:
例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: default
spec:
  egress:
  - hosts:
    - "./*" # Import all configuration from our own namespace 从我们自己的命名空间导入所有配置
    - "bookinfo/*" # Import all configuration from the bookinfo namespace 从 bookinfo 命名空间导入所有配置
    - "external-services/example.com" # Import only 'example.com' from the external-services namespace 仅从外部服务命名空间导入“example.com”
{{< /text >}}

### `exportTo`

Istio's `VirtualService`, `DestinationRule`, and `ServiceEntry` provide a `spec.exportTo` field. Similarly, `Service` can be configured with the `networking.istio.io/exportTo` annotation.
Istio 的“VirtualService”、“DestinationRule”和“ServiceEntry”提供了“spec.exportTo”字段。 同样，“Service”可以使用“networking.istio.io/exportTo”注释进行配置。

Unlike `Sidecar` which allows a workload owner to control what dependencies it has, `exportTo` works in the opposite way, and allows the service owners to control their own service's visibility.
与允许工作负载所有者控制其依赖项的“Sidecar”不同，“exportTo”以相反的方式工作，并允许服务所有者控制自己的服务的可见性。

For example, this configuration makes the `details` `Service` only visible to its own namespace, and the `client` namespace:
例如，此配置使“details”“Service”仅对其自己的命名空间和“client”命名空间可见：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: details
  annotations:
    networking.istio.io/exportTo: ".,client"
spec: ...
{{< /text >}}

### `DiscoverySelectors`

While the previous controls operate on a workload or service owner level, [`DiscoverySelectors`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) provides mesh wide control over configuration visibility. Discovery selectors allows specifying criteria for which namespaces should be visible to the control plane. Any namespaces not matching are ignored by the control plane entirely.
虽然以前的控件在工作负载或服务所有者级别上运行，但 [`DiscoverySelectors`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) 提供了对配置可见性的网格范围控制。 发现选择器允许指定命名空间对控制平面可见的标准。 任何不匹配的命名空间都会被控制平面完全忽略。

This can be configured as part of `meshConfig` during installation. For example:
这可以在安装过程中配置为“meshConfig”的一部分。 例如：

{{< text yaml >}}
meshConfig:
  discoverySelectors:
    - matchLabels:
        # Allow any namespaces with `istio-discovery=enabled` 允许使用“istio-discovery=enabled”的任何命名空间
        istio-discovery: enabled
    - matchLabels:
        # Allow "kube-system"; Kubernetes automatically adds this label to each namespace 允许“kube-system”； Kubernetes 会自动将此标签添加到每个命名空间
        kubernetes.io/metadata.name: kube-system
{{< /text >}}

{{< warning >}}
Istiod will always open a watch to Kubernetes for all namespaces. However, discovery selectors will ignore objects that are not selected very early in its processing, minimizing costs.
Istiod 将始终向 Kubernetes 开放所有命名空间的监视。 然而，发现选择器将忽略在处理早期未选择的对象，从而最大限度地降低成本。
{{</ warning >}}

## Frequently asked questions
## 常见问题

### How can I understand the cost of a certain configuration?
### 我如何了解某种配置的成本？

In order to get the best return-on-investment for scoping down configuration, it can be helpful to understand the cost of each object. Unfortunately, there is not a straightforward answer; scalability depends on a large number of factors. However, there are a few general guidelines:
为了获得缩小配置范围的最佳投资回报，了解每个对象的成本会很有帮助。 不幸的是，没有一个简单的答案。 可扩展性取决于很多因素。 但是，有一些一般准则：

Configuration *changes* are expensive in Istio, as they require recomputation. While `Endpoints` changes (generally from a Pod scaling up or down) are heavily optimized, most other configurations are fairly expensive. This can be especially harmful when controllers are constantly making changes to an object (sometimes this happens accidentally!). Some tools to detect which configurations are changing:
在 Istio 中，配置*更改*的成本很高，因为它们需要重新计算。 虽然“端点”更改（通常来自 Pod 向上或向下扩展）经过了大量优化，但大多数其他配置都相当昂贵。 当控制器不断地对对象进行更改时，这可能特别有害（有时这种情况是意外发生的！）。 一些用于检测哪些配置正在更改的工具：
* Istiod will log each change like: `Push debounce stable 1 for config Gateway/default/gateway: ..., full=true`. This shows a `Gateway` object in the `default` namespace changed. `full=false` would represent and optimized update such as `Endpoint`. Note: changes to `Service` and `Endpoints` will all show as `ServiceEntry`.
* Istiod 将记录每个更改，例如：`Push debounce stable 1 for config Gateway/default/gateway: ..., full=true`。 这显示“default”命名空间中的“Gateway”对象已更改。 `full=false` 将表示并优化更新，例如 `Endpoint`。 注意：对“Service”和“Endpoints”的更改都将显示为“ServiceEntry”。
* Istiod exposes metrics `pilot_k8s_cfg_events` and `pilot_k8s_reg_events` for each change.
* Istiod 公开每次更改的指标 `pilot_k8s_cfg_events` 和 `pilot_k8s_reg_events`。
* `kubectl get <resource> --watch -oyaml --show-managed-fields` can show changes to an object (or objects) to help understand what is changing, and by whom.
* `kubectl get <resource> --watch -oyaml --show-managed-fields` 可以显示对一个或多个对象的更改，以帮助了解正在更改的内容以及更改者。

[Headless services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) (besides ones declared as [HTTP](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)) scale with the number of instances. This makes large headless services expensive, and a good candidate for exclusion with `exportTo` or equivalent.
[无头服务](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)（除了声明为 [HTTP](/docs/ops/configuration/traffic-management/protocol- Selection/#explicit-protocol-selection)) 随着实例数量的变化而缩放。 这使得大型无头服务变得昂贵，并且是使用“exportTo”或等效项排除的良好候选者。

### What happens if I connect to a service outside of my scope?
### 如果我连接到我范围之外的服务会发生什么？

When connecting to a service that has been excluded through one of the scoping mechanisms, the data plane will not know anything about the destination, so it will be treated as [Unmatched traffic](/docs/ops/configuration/traffic-management/traffic-routing/#unmatched-traffic).
当连接到已通过范围机制之一排除的服务时，数据平面将不知道有关目的地的任何信息，因此它将被视为[不匹配的流量](/docs/ops/configuration/traffic-management/traffic -路由/#unmatched-traffic）。

### What about Gateways?
### 网关怎么样？

While [Gateways](/docs/setup/additional-setup/gateway/) will respect `exportTo` and `DiscoverySelectors`, `Sidecar` objects do not impact Gateways. However, unlike sidecars, gateways do not have configuration for the entire cluster by default. Instead, each configuration is explicitly attached to the gateway, which mostly avoids this problem.
虽然 [Gateways](/docs/setup/additional-setup/gateway/) 将尊重 `exportTo` 和 `DiscoverySelectors`，但 `Sidecar` 对象不会影响网关。 然而，与 sidecar 不同的是，网关默认没有整个集群的配置。 相反，每个配置都显式附加到网关，这在很大程度上避免了这个问题。

However, [currently](https://github.com/istio/istio/issues/29131) part of the data plane configuration (a "cluster", in Envoy terms), is always sent for the entire cluster, even if it is not referenced explicitly.
然而，[目前](https://github.com/istio/istio/issues/29131) 数据平面配置的一部分（用 Envoy 术语来说是“集群”）总是为整个集群发送，即使它 没有明确引用。
