---
title: 流量管理的最佳实践
description: 避免网络或者流量管理问题的配置的最佳实践.
force_inline_toc: true
weight: 20
aliases:
  - /zh/help/ops/traffic-management/deploy-guidelines
  - /zh/help/ops/deploy-guidelines
  - /zh/docs/ops/traffic-management/deploy-guidelines
---

本章节提供具体的部署或者配置指南，避免出现网络或者流量管理问题.

## 为服务设置默认路由

尽管我们不用设置任何的规则，默认的 Istio 行为就可以方便的从任意源地址发送流量到目标服务的所有版本，但是为每一个服务创建一个带有默认路由的 `VirtualService` 从一开始就被普遍认为是 Istio 的一个最佳实践。

即使最初你的服务只有一个版本，但只要你决定部署第二个版本，你就需要在你的新版本服务启动**之前**，就创建一个合适的路由规则，以防止它在不受控制的情况下立即收到流量。

依靠 Istio 默认轮询(round-robin)路由方式的另一个潜在问题是因为 Istio 的目标规则评估算法有些微妙。
当路由请求时，Envoy 首先评估虚拟服务中的路由规则，以确定一个特定的网格是否可以被路由到。
如果是，则它将仅仅激活与该网格相对应的所有目标规则策略。
因此，如果你**明确**地把流量路由到了对应的网格，那么 Istio 只应用你为特定网格定义的策略。

举个例子，将以下目标规则作为 *reviews* 服务的唯一配置，即相应的 `VirtualService` 定义中没有路由规则：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
{{< /text >}}

即使 Istio 的默认轮询 (round-robin) 路由机制有时也会调用 "v1" 版本的实例，甚至如果 "v1" 是唯一正在运行的版本，可能上述的流量策略永远也不会被调用。

你可以通过以下两种方法之一来修复上面的示例。你可以在 `DestinationRule` 移动流量策略到上一级，使其适用于任何版本：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
  subsets:
  - name: v1
    labels:
      version: v1
{{< /text >}}

或者更好的是，在 `VirtualService` 的定义中为这个服务定义一个合适的路由规则。
例如，为"reviews:v1"添加一个简单的路由规则：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

## 跨命名空间中共享控制配置 {#cross-namespace-configuration}

你可以在一个命名空间中定义虚拟服务、目标规则或者服务入口，如果他们被输出到其他的命名空间，他们就能在其他命名空间被重用。
默认情况下，Istio 将所有流量管理资源到输出到所有命名空间，但你可以使用 `exportTo` 字段覆盖这个可见性。
例如，只有相同命名空间下的客户端彩可以使用以下虚拟服务：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myservice
spec:
  hosts:
  - myservice.com
  exportTo:
  - "."
  http:
  - route:
    - destination:
        host: myservice
{{< /text >}}

{{< tip >}}
你可以使用类似 `networking.istio.io/exportTo` 的注解控制 Kubernetes `Service` 的可见性。
{{< /tip >}}

在特定的命名空间设置目标规则的可见性并不能保证这个规则会被使用。把目标规则输出到其他的命名空间可以让你在其他命名空间使用它，但是要在请求期间实际应用他，以下命名空间还需要在目标规则的查找路径上：

1. 客户端命名空间
1. 服务命名空间
1. Istio 根配置 (默认 `istio-system` 命名空间)

例如, 考虑以下目标规则：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: myservice
spec:
  host: myservice.default.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
{{< /text >}}

假设你在 `ns1` 命名空间中创建了这个目标规则。

如果你从 `ns1` 中的一个客户端向 `myservice` 服务发送了一个请求，这个目标规则将被应用，因为它是查找路径中的第一个命名空间，即在客户端命名空间中。

现在如果你从其他的命名空间中发出请求，例如 `ns2`，
客户端不在与目标规则处于同一个命名空间中，`ns1`。
由于相应服务 `myservice.default.svc.cluster.local` 不在命名空间 `ns1` 中，
而是在 `default` 命名空间中，因此这个目标规则也不会在查找路径中的第二个命名空间，服务命名空间中被找到。

即使服务 `myservice` 被输出到所有的命名空间且因此它在 `ns2` 中可见，并且目标规则也输出到包括 `ns2` 的所有命名空间，
它在来自 `s2` 的请求期间也不会被应用，因为它不在查找路径中的任何一个命名空间中。

你可以通过在与相应服务同一个命名空间中创建一个目标规则来避免这个问题，在这个示例中为 `default` 命名空间。然后它将被应用于来自任意一个命名空间中客户端的请求。
你也可以将目标规则移动至 `istio-system` 命名空间，即在查找路径上的第三个命名空间，除非目标规则的确是适用于所有命名空间的的全局配置，否则不建议这样做，况且这需要管理员权限。

Istio 使用受限制的目标规则查找路径有以下两个原因：

1. 避免定义一个可以覆盖完全不相关的命名空间中的服务行为的目标规则。
1. 一旦同一个主机有多个目标规则，请有一个清晰的查找顺序。

## 将大型虚拟服务和目标规则拆分为多个资源 {#split-virtual-services}

在不方便定义完整路由规则集的情况下或者托管在单个 `VirtualService` 或 `DestinationRule` 资源的特定策略，最好逐步指定多资源的主机配置。
如果把他们绑定到一个网关，Pilot 将合并此类目标规则并且合并这些虚拟服务。

考虑绑定一个 `VirtualService` 到一个入口网关的情况，该网关暴露了一个使用基于路径委派给多个实施服务的应用主机，类似这样：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

这种配置的缺点是任何基础微服务的其他配置(例如路由规则)，也将需要包含在此单配置文件中，而不是
在各个相关独立的服务团队并可能由其拥有独立的资源中。
请参阅 [路由规则对入口网关的请求没有生效](/zh/docs/ops/common-problems/network-issues/#route-rules-have-no-effect-on-ingress-gateway-requests)获取更多信息。

为了避免这个问题，最好将 `myapp.com` 的配置拆分成多个 `VirtualService` 片段，即每个后端服务一个。例如:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-service1
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-service2
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-...
{{< /text >}}

当现有主机应用第二个和后续的 `VirtualService` 时， `istio-pilot` 将会合并新加入的路由规则进入现有的主机配置中。然而在使用该特性时有几个必须仔细考虑的注意事项。

1. 虽然对任何给定的源 `VirtualService` 中规则的评估规则将被保留，
   但是跨资源的顺序是未定义的。换句话说，对于跨片段配置的规则，没有没有明确的评估顺序，因此只有在跨片段的规则之间没有冲突的规则或者顺序依赖时，才会有可预测的行为。
1. 在片段中应该只有一个“一揽子”规则（例如一个匹配任何请求路径或头的规则）。
   所有这些“一揽子”规则都应该被移动到被合并配置中列表的末尾，但是由于它们捕获所有的请求，首先应用的规则将覆盖和禁用其他规则。
1. 一个 `VirtualService` 只有绑定到了一个网关，它才能被分割。
   Sidecar 不支持主机合并。
1. `DestinationRule` 也可以用类似的合并语义和限制来分割。
1. 对于同一主机，跨多个目标规则的任何给定的网格应该只有一个定义。
   如果有多个具有相同名称的定义，则使用第一个定义，并且丢弃后面的任何副本。
   不支持合并网格的内容。
1. 对于同一个主机，应该只有一个顶级的 `trafficPolicy` 。
   当在多个目标规则中定义顶级流量策略时，将使用第一个。
   后面的任何顶级 `trafficPolicy` 配置都将被丢弃。
1. 与虚拟服务合并不同，目标规则的合并可以同时在 sidecar 和网关中工作。

## 在重新配置服务路由时避免503错误

当设置路由规则将流量导向一个服务特定的版本（网格）时，必须确保这些网格在路由中被使用之前是可用的。否则在重新配置期间，对服务的调用可能会返回 503 错误。

使用单个 `kubectl` 调用创建定义相应网格的 `VirtualServices` 和 `DestinationRules`（例如 `kubectl apply -f myVirtualServiceAndDestinationRule.yaml`）是不充分的，因为资源以最终一致的方式传播（从配置服务，例如 Kubernetes API server）到Pilot实例。 如果使用网格的 `VirtualService` 比定义了网格的 `DestinationRule` 先到达，那么有Pilot生成的Envoy配置将会引用不存在的上游池。这将导致 HTTP 503 错误，直到对于 Pilot，所有的配置对象都可使用。

为了确保在配置网格的路由时，服务没有中断时间，请遵循下面所描述的先合后断的流程：

* 当添加新网格时:

    1. 在更新任何使用了 `DestinationRules` 的网格之前，首先更新它以添加一个新的网格。使用 `kubectl` 或者任何特定平台的工具在应用规则。

    1. 等待几秒钟，让 `DestinationRule` 的配置传播到 Envoy 的 sidecar 。

    1. 更新 `VirtualService` 以引用新添加的网格。

* 当删除网格时：

    1. 在从一个 `DestinationRule` 中删除网格之前，更新 `VirtualServices` 以删除对网格的任何引用。

    1. 等待几秒钟，让 `DestinationRule` 的配置传播到 Envoy 的 sidecar 。

    1. 更新 `DestinationRule` 以删除不再使用的网格。


