---
title: 流量转移
description: 展示如何将流量从旧版本迁移到新版本的服务。
weight: 30
keywords: [traffic-management,traffic-shifting]
aliases:
    - /zh/docs/tasks/traffic-management/version-migration.html
owner: istio/wg-networking-maintainers
test: yes
---

本任务将向您展示如何将流量从微服务的一个版本逐步迁移到另一个版本。
例如，您可以将流量从旧版本迁移到新版本。

一个常见的用例是将流量从微服务的一个版本的逐渐迁移到另一个版本。在 Istio 中，
您可以通过配置一系列规则来实现此目标。这些规则将一定比例的流量路由到一个或另一个服务。

在本任务中，您将会把 50％ 的流量发送到 `reviews:v1`，另外，50％ 的流量发送到
`reviews:v3`。接着，再把 100％ 的流量发送到 `reviews:v3` 来完成迁移。

{{< boilerplate gateway-api-gamma-support >}}

## 开始之前 {#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序。

* 查看[流量管理](/zh/docs/concepts/traffic-management)概念文档。

## 应用基于权重的路由 {#apply-weight-based-routing}

{{< warning >}}
如果尚未定义服务版本, 请按照[定义服务版本](/zh/docs/examples/bookinfo/#define-the-service-versions)中的说明进行操作。
{{< /warning >}}

1.  首先，运行此命令将所有流量路由到各个微服务的 `v1` 版本。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_all_v1 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_all_v1 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  在浏览器中打开 Bookinfo 站点。网址为 `http://$GATEWAY_URL/productpage`，
    其中 `$GATEWAY_URL` 是 Ingress 的外部 IP 地址，其描述参见
    [Bookinfo](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port)
    文档。

    请注意，不管刷新多少次，页面的评论部分都不会显示评价星级的内容。
    这是因为 Istio 被配置为将星级评价的服务的所有流量都路由到了
    `reviews:v1` 版本，而该版本的服务不访问带评价星级的服务。

3)  使用下面的命令把 50% 的流量从 `reviews:v1` 转移到 `reviews:v3`：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_50_v3 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_50_v3 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-50-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) 等待几秒钟，等待新的规则传播到代理中生效，确认规则已被替换：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash outputis=yaml snip_id=verify_config_50_v3 >}}
$ kubectl get virtualservice reviews -o yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
...
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v3
      weight: 50
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash outputis=yaml snip_id=gtw_verify_config_50_v3 >}}
$ kubectl get httproute reviews -o yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: reviews-v1
      port: 9080
      weight: 50
    - group: ""
      kind: Service
      name: reviews-v3
      port: 9080
      weight: 50
    matches:
    - path:
        type: PathPrefix
        value: /
status:
  parents:
  - conditions:
    - lastTransitionTime: "2022-11-10T18:13:43Z"
      message: Route was valid
      observedGeneration: 14
      reason: Accepted
      status: "True"
      type: Accepted
...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  刷新浏览器中的 `/productpage` 页面，大约有 50% 的几率会看到页面中带**红色**星级的评价内容。
    这是因为 `reviews` 的 `v3` 版本可以访问带星级评价，但 `v1` 版本不能。

    {{< tip >}}
    在目前的 Envoy Sidecar 实现中，您可能需要多次刷新 `/productpage` 页面，可能
    15 次或更多次，才能看到正确的流量分发的效果。您可以通过修改规则将 90% 的流量路由到
    `v3` 版本，这样能看到更多带红色星级的评价。
    {{< /tip >}}

6)  如果您认为 `reviews:v3` 微服务已经稳定，您可以通过应用 Virtual Service
    规则将 100% 的流量路由 `reviews:v3`：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_100_v3 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_100_v3 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7) 现在，当您刷新 `/productpage` 时，您将始终看到带有**红色**星级评分的书评。

## 理解原理 {#understanding-what-happened}

在这项任务中，我们使用 Istio 的权重路由功能将 `reviews` 服务的流量迁移到新版本。
请注意，这和使用容器编排平台的部署功能来进行版本迁移完全不同，后者使用了实例扩容来对流量进行管理。

使用 Istio，两个版本的 `reviews` 服务可以独立地进行扩容和缩容，
而不会影响这两个服务版本之间的流量分发。

如果想了解支持自动伸缩的版本路由的更多信息，请查看[使用 Istio 进行金丝雀部署](/zh/blog/2017/0.1-canary/)。

## 清理 {#cleanup}

1. 删除应用程序路由规则。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=cleanup >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_cleanup >}}
$ kubectl delete httproute reviews
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)中的说明来关闭应用程序。
