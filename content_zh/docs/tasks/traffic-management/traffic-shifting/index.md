---
title: 流量转移
description: 向您展示如何将流量从旧版本迁移到新版本的服务。
weight: 25
keywords: [traffic-management,traffic-shifting]
---

本任务将演示如何逐步将流量从一个版本的微服务迁移到另一个版本。例如，您可以将流量从旧版本迁移到新版本。

一个常见的用例是将流量从一个版本的微服务逐渐迁移到另一个版本。在 Istio 中，您可以通过配置一系列规则来实现此目标，这些规则将一定百分比的流量路由到一个或另一个服务。在此任务中，您将 50％ 的流量发送到 `reviews:v1`，另外 50％ 的流量发送到 `reviews:v3`。然后将 100％ 的流量发送到 `reviews:v3` 来完成迁移。

## 开始之前

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序。

* 查看 [流量管理](/zh/docs/concepts/traffic-management) 概念文档。

## 应用基于权重的路由

{{< warning >}}
如果尚未应用目标规则，请按照[应用默认目标规则](/zh/docs/examples/bookinfo/#应用缺省目标规则)中的说明进行操作。
{{< /warning >}}

1.  首先，运行此命令将所有流量路由到 `v1` 版本的各个微服务。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1.  在浏览器中打开 Bookinfo 站点。 URL 为 `http://$GATEWAY_URL/productpage`，其中 `$GATEWAY_URL` 是 ingress 的外部 IP 地址，
其描述参见 [Bookinfo](/zh/docs/examples/bookinfo/#确定-ingress-的-ip-和端口)。

     请注意，不管刷新多少次，页面的评论部分都不会显示评级星号。这是因为 Istio 被配置为将 reviews 服务的的所有流量都路由到了 `reviews:v1` 版本，
     而该版本的服务不会访问带星级的 ratings 服务。

1.  使用下面的命令把 50% 的流量从 `reviews:v1` 转移到 `reviews:v3`：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml@
    {{< /text >}}

    等待几秒钟以让新的规则传播到代理中生效。

1.  确认规则已被替换:

    {{< text bash yaml >}}
    $ kubectl get virtualservice reviews -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: reviews
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

1.  刷新浏览器中的 `/productpage` 页面，大约有 50% 的几率会看到页面中出带红色星级的评价内容。这是因为 `v3` 版本的 `reviews` 访问了带星级评级的 `ratings` 服务，但 `v1` 版本却没有。

  {{< tip >}}
  在目前的 Envoy sidecar 实现中，可能需要刷新 `/productpage` 很多次--可能 15 次或更多--才能看到流量分发的效果。您可以通过修改规则将 90% 的流量路由到 v3，这样能看到更多带红色星级的评价。
  {{< /tip >}}

1. 如果您认为 `reviews:v3` 微服务已经稳定，你可以通过应用此 virtual service 将 100% 的流量路由到 `reviews:v3`：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
    {{< /text >}}

    现在，当您刷新 `/productpage` 时，您将始终看到带有红色星级评分的书评。

## 了解发生了什么

在这项任务中，我们使用 Istio 的加权路由功能将流量从旧版本的 `reviews` 服务迁移到新版本。请注意，这和使用容器编排平台的部署功能来进行版本迁移完全不同，后者使用了实例扩容来对流量进行管理。

使用 Istio，两个版本的 `reviews` 服务可以独立地进行扩容和缩容，并不会影响这两个版本服务之间的流量分发。

如果想了解支持自动伸缩的版本路由的更多信息，请查看[使用 Istio 的 Canary Deployments](/blog/2017/0.1-canary/) 。

## 清理

1. 删除应用程序路由规则。

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理) 的说明关闭应用程序。
