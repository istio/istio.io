---
title: 流量管理最佳实践
description: 避免网络或流量管理问题的配置最佳实践。
force_inline_toc: true
weight: 20
aliases:
  - /zh/help/ops/traffic-management/deploy-guidelines
  - /zh/help/ops/deploy-guidelines
  - /zh/docs/ops/traffic-management/deploy-guidelines
owner: istio/wg-networking-maintainers
test: n/a
---

本节提供特定的部署或配置准则，以避免网络或流量管理问题。

## 为服务设置默认路由{#set-default-routes-for-services}

尽管默认的 Istio 行为就可以在没有配置任何规则的情况下，将任何来源的流量发送到目标服务的所有版本。
但是，在 Istio 里的最佳做法是，从一开始就为每一个服务创建具有默认路由的 `VirtualService`。

即使最初您的服务只有一个版本，但是一旦你想要部署第二个版本，为了防止其以不受控制的方式接收流量，
你需要在启用新版本**之前**配置路由规则。

依赖 Istio 默认循环路由的另一个潜在问题，在于 Istio 的 `DestinationRule` 评估算法的微妙之处。
路由请求时，Envoy 首先评估 `VirtualService` 中的路由规则，以决定是否路由特定子集。
当且仅当这样才能激活与该子集相对应的 `DestinationRule` 策略。因此，如果您将流量**明确地**路由到相应的子集，
则 Istio 应该只应用您为特定子集定义的策略。

例如，将以下 `DestinationRule` 视为 **reviews** 服务定义的唯一配置，
即相应的 `VirtualService` 定义中没有路由规则：

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

即使 Istio 的默认轮询路由有时会调用 `v1` 实例，即使 `v1` 永远是唯一运行的版本，也永远不会调用上述流量策略。

您可以通过以下两种方法之一来修复上面的示例。您可以在 `DestinationRule` 中将流量策略上移以使其适用于任何版本：

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

更好的方法是，在 `VirtualService` 定义中为服务定义适当的路由规则。
例如，为 `reviews:v1` 添加一个简单的路由规则：

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

## 控制配置在命名空间之间的共享{#cross-namespace-configuration}

您可以在一个命名空间中定义 `VirtualService`，`DestinationRule` 或 `ServiceEntry`，
然后将它们导出到其他命名空间，然后在其他命名空间中重用它们。
Istio 默认情况下会将所有流量管理资源导出到所有命名空间，但是您可以使用 `exportTo`
控制其跨命名空间的可见性。例如，只有相同命名空间中的客户端可以使用以下 `VirtualService`：

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
您可以像使用 `networking.istio.io/exportTo` 批注一样控制 Kubernetes `Service` 的可见性。
{{< /tip >}}

在特定命名空间中设置 `DestinationRule` 的可见性并不能保证会使用该规则。
将 `DestinationRule` 导出到其他命名空间可以使您在其它命名空间中使用它，
但是要在请求时真正应用该 `DestinationRule`，命名空间也必须位于 `DestinationRule` 查找路径上：

1. 客户端命名空间
1. 服务命名空间
1. Istio 根配置命名空间（默认是 `istio-system`）

例如，有以下 `DestinationRule`：

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

假设您在命名空间 `ns1` 中创建此 `DestinationRule`。

如果从 `ns1` 中的客户端向 `myservice` 服务发送请求，则将应用该 `DestinationRule`，
因为它在查找路径的第一个命名空间中，即在客户端命名空间中。

如果现在从另一个命名空间（例如 `ns2`）发送请求，则客户端将不再与 `DestinationRule` 处于相同的命名空间，
即 `ns1`。因为相应的服务 `myservice.default.svc.cluster.local` 也不在 `ns1` 中，
而是在 `default` 命名空间中，所以在查找路径的第二个命名空间中也找不到 `DestinationRule`，即服务命名空间。

即使将 `myservice` 服务导出到所有命名空间，并因此在 `ns2` 中可见，
并且 `DestinationRule` 也导出到包括 `ns2` 在内的所有命名空间。来自 `ns2`
的请求依然不会应用该规则，因为它不在查找路径上的任何命名空间中。

您可以通过在与相应服务相同的命名空间（在此示例中为 `default`）中创建 `DestinationRule` 来避免此问题。
然后，它将应用于任何命名空间中的客户端请求。您也可以将 `DestinationRule` 移至 `istio-system` 命名空间，
即查找路径上的第三个命名空间，尽管不建议这样做，除非 `DestinationRule` 是适用于所有命名空间的全局配置，
并且这需要管理员权限。

Istio 使用这种受限制的 `DestinationRule` 查找路径有两个原因：

1. 防止定义覆盖完全不相关的命名空间中的服务行为的 `DestinationRule`。
1. 当同一 host 有多个 `DestinationRule` 时，可以有一个清晰的查找顺序。

## 将大型 `VirtualService` 和 `DestinationRule` 拆分为多个资源{#split-virtual-services}

当不方便在单个 `VirtualService` 或 `DestinationRule` 资源中为特定 host 定义完整的路由规则或策略集时，
最好在多个资源中递增指定 host 的配置。如果将这些 `DestinationRule` 绑定到网关，
Pilot 会合并这些 `DestinationRule` 和 `VirtualService`。

考虑一下这种情况，一个 `VirtualService` 绑定到入口网关上，并将应用的 host 暴露出来，
该 host 基于路径代理了多个服务，如下所示：

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

这种配置的缺点是，任何底层微服务的其他配置（例如，路由规则）也需要包含在这个配置文件中，
而不是包含在与各个服务团队关联或可能由各个服务团队拥有的单独资源中。有关详细信息，
请参见[路由规则没有对 ingress gateway 请求生效](/zh/docs/ops/common-problems/network-issues/#route-rules-have-no-effect-on-ingress-gateway-requests)。

为避免此问题，最好将 `myapp.com` 的配置分解为多个 `VirtualService`，每个后端服务一个。例如：

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

当为已存在的 host 创建第二个及更多的 `VirtualService`时，`istio-pilot` 会将额外的路由规则合并到
host 现有配置中。但是，在使用此功能时，有一些注意事项。

1. 尽管会保留任何给定源 `VirtualService` 中规则的评估顺序，但跨资源的顺序是不确定的。
   换句话说，无法保证片段配置中规则的评估顺序，因此，只有在片段规则之间没有冲突的规则或者顺序依赖性时，
   它才具有可预测的行为。
1. 片段中应该只有一个 `catch-all` 规则（即与任何请求路径或 header 都匹配的规则）。所有这些
   `catch-all` 规则将在合并配置中移至列表的末尾，但是由于它们捕获了所有请求，因此，首先应用的那个规则，
   实际上会覆盖并禁用其它的规则。
1. 如果想将 `VirtualService` 绑定到网关，则只能以这种方式进行分段。Sidecar 不支持 host 合并。

也可以使用类似的合并语义和限制将 `DestinationRule` 分段。

1. 在这里，它应该只是同一 host 的多个 `DestinationRule` 中任何给定子集的一种定义。如果有多个同名，
   则使用第一个定义，并丢弃随后的所有重复项。不支持子集内容的合并。
1. 同一 host 只能有一个顶级的 `trafficPolicy`。在多个 `DestinationRule` 中定义了顶级 `trafficPolicy`
   时，将使用第一个策略。之后的所有顶级 `trafficPolicy` 配置都将被丢弃。
1. 与 `VirtualService` 合并不同，`DestinationRule` 合并在 Sidecar 和 gateway 中均有效。

## 避免重新配置服务路由时出现 503 错误{#avoid-5-0-3-errors-while-reconfiguring-service-routes}

在设置路由规则以将流量定向到服务的某个版本（子集）时，必须注意确保子集在路由中使用之前是可用的。
否则，在重新配置期间，对服务的调用可能返回 503 错误。

使用单个 `kubectl` 调用（例如，`kubectl apply -f myVirtualServiceAndDestinationRule.yaml`）
创建定义相应子集的 `VirtualServices` 和 `DestinationRules` 是不够的，
因为资源（是从配置服务器传播的，即 Kubernetes API 服务器）以最终一致的方式添加到 Pilot 实例的。
如果 `VirtualService` 在定义的子集 `DestinationRule` 到达之前使用了子集，则 Pilot 生成的 Envoy
配置将引用不存在的上游池。结果就是出现 HTTP 503 错误，直到对于 Pilot 来说所有配置对象都是可用的。

为保证服务在配置带有子集的路由时的停机时间为零，请按照下述“先接后断”的流程进行操作：

* 添加新子集时：

    1. 更新 `DestinationRules`，首先添加一个新的子集，然后更新会使用它的所有 `VirtualServices`，
       再使用 `kubectl` 或平台对应的工具应用规则。

    1. 等待几秒钟，使 `DestinationRule` 配置传播到 Envoy Sidecar。

    1. 更新 `VirtualService` 以引用新添加的子集。

* 移除子集时：

    1. 在从 `DestinationRule` 中删除子集之前，更新 `VirtualServices` 以删除对该子集的所有引用。

    1. 等待几秒钟，使 `VirtualService` 配置传播到 Envoy Sidecar。

    1. 更新 `DestinationRule` 以删除未使用的子集。
