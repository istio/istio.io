---
title: "Gateway API 网格支持提升至稳定状态"
description: 下一代 Kubernetes 流量路由 API 现已普遍适用于服务网格用例。
publishdate: 2024-05-13
attribution: John Howard - solo.io; Translated by Wilson Wu (DaoCloud)
keywords: [istio, traffic, API]
target_release: 1.22
---

We are thrilled to announce that Service Mesh support in the [Gateway API](https://gateway-api.sigs.k8s.io/) is now officially "Stable"! With this release (part of Gateway API v1.1 and Istio v1.22), users can make use of the next-generation traffic management APIs for both ingress ("north-south") and service mesh use cases ("east-west").
我们很高兴地宣布 [Gateway API](https://gateway-api.sigs.k8s.io/) 中的 Service Mesh 支持现已正式“稳定”！ 在此版本中（Gateway API v1.1 和 Istio v1.22 的一部分），用户可以将下一代流量管理 API 用于入口（“南北”）和服务网格用例（“东西向”） ”）。

## What is the Gateway API?
## 什么是 Gateway API？

The Gateway API is a collection of APIs that are part of Kubernetes, focusing on traffic routing and management. The APIs are inspired by, and serve many of the same roles as, Kubernetes' `Ingress` and Istio's `VirtualService` and `Gateway` APIs.
Gateway API 是 Kubernetes 一部分的 API 集合，专注于流量路由和管理。 这些 API 受到 Kubernetes 的“Ingress”和 Istio 的“VirtualService”和“Gateway” API 的启发，并发挥许多相同的作用。

These APIs have been under development both in Istio, as well as with [broad collaboration](https://gateway-api.sigs.k8s.io/implementations/), since 2020, and have come a long way since then. While the API initially targeted only serving ingress use cases (which went GA [last year](https://kubernetes.io/blog/2023/10/31/gateway-api-ga/)), we had always envisioned allowing the same APIs to be used for traffic *within* a cluster as well.
自 2020 年以来，这些 API 一直在 Istio 中以及[广泛合作](https://gateway-api.sigs.k8s.io/implementations/) 中进行开发，并且自那时以来已经取得了长足的进步。 虽然 API 最初仅针对服务入口用例（去年发布了 GA（https://kubernetes.io/blog/2023/10/31/gateway-api-ga/）），但我们一直设想允许 相同的 API 也可用于集群*内*的流量。

With this release, that vision is made a reality: Istio users can use the same routing API for all of their traffic!
在此版本中，这一愿景成为现实：Istio 用户可以对所有流量使用相同的路由 API！

## Getting started
## 入门

Throughout the Istio documentation, all of our examples have been updated to show how to use the Gateway API, so explore some of the [tasks](/docs/tasks/traffic-management/) to gain a deeper understanding.
在整个 Istio 文档中，我们的所有示例都已更新，以展示如何使用 Gateway API，因此请探索一些 [任务](/docs/tasks/traffic-management/) 以获得更深入的理解。

Using Gateway API for service mesh should feel familiar both to users already using Gateway API for ingress, and users using `VirtualService` for service mesh today.
使用 Gateway API 进行服务网格对于已经使用 Gateway API 进行入口的用户以及现在使用“VirtualService”进行服务网格的用户来说应该感到熟悉。

* Compared to Gateway API for ingress, routes target a `Service` instead of a `Gateway`.
* Compared to `VirtualService`, where routes associate with a set of `hosts`, routes target a `Service`.
* 与用于入口的网关 API 相比，路由的目标是“服务”而不是“网关”。
* 与“VirtualService”相比，路由与一组“hosts”关联，而路由则以“Service”为目标。

Here is a simple example, which demonstrates routing requests to two different versions of a `Service` based on the request header:
这是一个简单的示例，演示了根据请求标头将请求路由到两个不同版本的“Service”：

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
      - name: my-favorite-service-mesh
        value: istio
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
      add:
        - name: hello
          value: world
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
{{< /text >}}

Breaking this down, we have a few parts:
* First, we identify what routes we should match. By attaching our route to the `reviews` Service, we will apply this routing configuration to all requests that were originally targeting `reviews`.
* Next, `matches` configures criteria for selecting which traffic this route should handle.
* Optionally, we can modify the request. Here, we add a header.
* Finally, we select a destination for the request. In this example, we are picking between two versions of our application.
将其分解，我们有几个部分：
* 首先，我们确定应该匹配哪些路线。 通过将我们的路由附加到“reviews”服务，我们将将此路由配置应用于最初针对“reviews”的所有请求。
* 接下来，“matches”配置选择该路由应处理的流量的标准。
* 我们可以选择修改请求。 在这里，我们添加一个标题。
* 最后，我们选择请求的目的地。 在此示例中，我们在应用程序的两个版本之间进行选择。

For more details, see [Istio's traffic routing internals](/docs/ops/configuration/traffic-management/traffic-routing/) and [Gateway API's Service documentation](https://gateway-api.sigs.k8s.io/mesh/service-facets/).
有关更多详细信息，请参阅 [Istio 的流量路由内部结构](/docs/ops/configuration/traffic-management/traffic-routing/) 和 [Gateway API 的服务文档](https://gateway-api.sigs.k8s.io/ 网格/服务方面/）。

## Which API should I use?
## 我应该使用哪个 API？

With overlapping responsibilities (and names!), picking which APIs to use can be a bit confusing.
由于职责（和名称！）重叠，选择要使用的 API 可能会有点混乱。

Here is the breakdown:
这是细分：

| API 名称     | 对象类型                                                                                                                           | 状态                            | 推荐                                                             |
|--------------|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|----------------------------------------------------------------------------|
| Gateway API | [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/), [Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/), ... | Gateway API v1.0（2023）稳定 | Use for new deployments, in particular with [ambient mode](/docs/ambient/) 用于新部署，特别是[环境模式](/docs/ambient/) |
| Istio API   | [Virtual Service](/docs/reference/config/networking/virtual-service/), [Gateway](/docs/reference/config/networking/gateway/)          | `v1` in Istio 1.22 (2024) Istio 1.22 (2024) 中的“v1”        | Use for existing deployments, or where advanced features are needed  用于现有部署或需要高级功能的地方      |
| Ingress API  | [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress)                                                            | Stable in Kubernetes v1.19 (2020) 在 Kubernetes v1.19 (2020) 中稳定 | Use only for legacy deployments  仅用于旧部署                                          |

You may wonder, given the above, why the Istio APIs were [promoted to `v1`](/blog/2024/v1-apis) concurrently? This was part of an effort to accurate categorize the *stability* of the APIs. While we view Gateway API as the future (and present!) of traffic routing APIs, our existing APIs are here to stay for the long run, with full compatibility. This mirrors Kubernetes' approach with [`Ingress`](https://kubernetes.io/docs/concepts/services-networking/ingress), which was promoted to `v1` while directing future work towards the Gateway API.
鉴于上述情况，您可能想知道为什么 Istio API 同时[升级为“v1”](/blog/2024/v1-apis)？ 这是对 API 的“稳定性”进行准确分类的努力的一部分。 虽然我们将网关 API 视为流量路由 API 的未来（和现在！），但我们现有的 API 将长期保留，并具有完全兼容性。 这反映了 Kubernetes 使用 [`Ingress`](https://kubernetes.io/docs/concepts/services-networking/ingress) 的方法，该方法被提升到 `v1`，同时将未来的工作导向网关 API。

## Community
## 社区

This stability graduation represents the culmination of countless hours of work and collaboration across the project. It is incredible to look at the [list of organizations](https://gateway-api.sigs.k8s.io/implementations/) involved in the API and consider back at how far we have come.
这种稳定性毕业代表了整个项目无数个小时的工作和协作的顶峰。 看看 API 涉及的[组织列表](https://gateway-api.sigs.k8s.io/implementations/) 并回想一下我们已经走了多远，真是令人难以置信。

A special thanks goes out to my [co-leads on the effort](https://gateway-api.sigs.k8s.io/mesh/gamma/): Flynn, Keith Mattix, and Mike Morris, as well as the countless others involved.
特别感谢我的[共同领导者](https://gateway-api.sigs.k8s.io/mesh/gamma/)：Flynn、Keith Mattix 和 Mike Morris，以及无数的人 其他相关人员。

Interested in getting involved, or even just providing feedback? Check out Istio's [community page](/get-involved/) or the Gateway API [contributing guide](https://gateway-api.sigs.k8s.io/contributing/)!
有兴趣参与，甚至只是提供反馈吗？ 查看 Istio 的 [社区页面](/get-involved/) 或 Gateway API [贡献指南](https://gateway-api.sigs.k8s.io/contributing/)！
