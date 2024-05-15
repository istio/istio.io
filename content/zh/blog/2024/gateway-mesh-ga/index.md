---
title: "Gateway API 网格支持提升至稳定状态"
description: 下一代 Kubernetes 流量路由 API 现已普遍适用于服务网格用例。
publishdate: 2024-05-13
attribution: John Howard - solo.io; Translated by Wilson Wu (DaoCloud)
keywords: [istio, traffic, API]
target_release: 1.22
---

我们很高兴地宣布 [Gateway API](https://gateway-api.sigs.k8s.io/)
中的服务网格支持现已正式“稳定”！在此版本中（Gateway API v1.1 和 Istio v1.22 的一部分），
用户可以将下一代流量管理 API 同时应用于入口（“南北向”）和服务网格内（“东西向”）用例。

## 什么是 Gateway API？ {#what-is-the-gateway-api}

Gateway API 是属于 Kubernetes 的 API 集合，专注于流量路由和管理。
这些 API 受到 Kubernetes 的 `Ingress` 和 Istio 的 `VirtualService` 和 `Gateway` API 的启发，
并发挥许多相同的作用。

自 2020 年以来，这些 API 一直在 Istio 以及[广泛协作](https://gateway-api.sigs.k8s.io/implementations/)的组织中得到开发，
并且自那时以来已经取得了长足的进步。虽然这些 API 最初仅针对服务入口用例
（[去年](https://kubernetes.io/zh-cn/blog/2023/10/31/gateway-api-ga/)发布了 GA 版），
但我们一直设想允许相同的 API 也可用于集群**内**的流量。

在此版本中，这一愿景成为现实：Istio 用户可以对所有流量使用相同的路由 API！

## 入门 {#getting-started}

在整个 Istio 文档中，我们的所有示例都已更新，以展示如何使用 Gateway API，
因此请探索一些[任务](/zh/docs/tasks/traffic-management/)以获得更深入的理解。

使用 Gateway API 进行服务网格对于已经使用 Gateway API
进行入口的用户以及在服务网格中使用 `VirtualService` 的用户来说应该感到熟悉。

* 与用于入口的 Gateway API 相比，路由的目标由 `Gateway` 替代为`Service`。
* 与 `VirtualService` 相比，路由与一组 `hosts` 关联，以 `Service` 为目标。

这是一个简单的示例，演示了根据请求头将请求路由到两个不同版本的 `Service`：

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

将其分解后，我们得到几个部分：
* 首先，我们确定应该匹配哪些路由。通过将我们的路由附加到 `reviews` 服务，
  我们会将此路由配置应用于最初针对 `reviews` 的所有请求。
* 接下来，`matches` 配置选择该路由应处理的流量标准。
* 我们可以选择修改请求。在这里，我们添加一个标题。
* 最后，我们选择请求的目标。在此示例中，我们在应用程序的两个版本之间进行选择。

有关更多详细信息，请参阅 [Istio 的流量路由内部结构](/zh/docs/ops/configuration/traffic-management/traffic-routing/) 和
[Gateway API 的服务文档](https://gateway-api.sigs.k8s.io/mesh/service-facets/)。

## 我应该使用哪个 API？ {#which-api-should-i-use}

由于职责（和名称！）重叠，选择要使用的 API 可能会有点混乱。

以下是详细分析：

| API 名称     | 对象类型                                                                                                                           | 状态                            | 推荐                                                             |
|--------------|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------|----------------------------------------------------------------------------|
| Gateway API | [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/), [Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/), ... | Gateway API v1.0（2023）稳定 | 用于新部署，特别是 [Ambient 模式](/zh/docs/ambient/) |
| Istio API   | [Virtual Service](/zh/docs/reference/config/networking/virtual-service/), [Gateway](/zh/docs/reference/config/networking/gateway/)          | Istio 1.22（2024）中达到 `v1`       | 用于现存部署或需要高级功能的地方      |
| Ingress API  | [Ingress](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress)                                                            | 在 Kubernetes v1.19（2020）中稳定 | 仅用于旧部署                                          |

鉴于上述情况，您可能想知道为什么 Istio API 同时[被升级为 `v1`](/zh/blog/2024/v1-apis)？
这是对 API 的**稳定性**进行准确分类努力的一部分。
虽然我们将 Gateway API 视为流量路由 API 的未来（和现在！），
但我们现有的 API 将长期保留，并具有完全兼容性。这印证了 Kubernetes
使用 [`Ingress`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/) 的方法，
该方法被提升到 `v1`，同时将未来的工作导向 Gateway API。

## 社区 {#community}

这种稳定性毕业代表了整个项目无数个小时的工作和协作的顶峰。
看看 API 涉及的[组织列表](https://gateway-api.sigs.k8s.io/implementations/)并回想一下我们已经走了多远，
真是令人难以置信。

特别感谢我的[共同领导者](https://gateway-api.sigs.k8s.io/mesh/gamma/)：
Flynn、Keith Mattix 和 Mike Morris，以及无数其他相关人员。

有兴趣参与，或者只是提供反馈吗？查看 Istio 的[社区页面](/zh/get-involved/)或
Gateway API [贡献指南](https://gateway-api.sigs.k8s.io/contributing/)！
