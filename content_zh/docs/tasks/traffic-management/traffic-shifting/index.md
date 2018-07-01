---
title: 流量转移
description: 向您展示如何将流量从旧版本迁移到新版本的服务。
weight: 25
keywords: [traffic-management,traffic-shifting]
aliases:
    - /docs/tasks/traffic-management/version-migration.html
---

> 该任务使用新的 [v1alpha3 流量管理 API](/blog/2018/v1alpha3-routing/)。旧版本的API已被弃用，并将在下一个Istio版本中删除。 如果您需要使用旧版本，请点击[此处](https://archive.istio.io/v0.7/docs/tasks/traffic-management/)的文档。

本任务将演示如何将应用流量逐渐从旧版本的服务迁移到新版本。借助 Istio，可以使用一系列权重小于100的规则将流量逐渐地从旧版本服务迁移到新版本服务，例如10，20，30，... 100％。
为了简单起见，此任务将仅使用两个步骤中将流量从 `reviews:v1` 迁移到 `reviews:v3` ：50％，100％。

## 开始之前

* 按照[安装指南](/docs/setup/)中的说明安装Istio。
* 部署 [Bookinfo](/docs/examples/bookinfo/) 示例应用程序。

## 基于权重的版本路由

1.  将所有微服务的默认版本设置为v1。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/routing/route-rule-all-v1.yaml@
    {{< /text >}}

1.  在浏览器中打开http://$GATEWAY_URL/productpage,  确认 `reviews` 服务目前的活动版本是v1。
    您应该看到Bookinfo应用程序产品页面。 请注意， productpage显示时没有评分星级，因为 `reviews:v1` 不访问评分服务。

1.  首先，使用下面的命令把50%的流量从 `reviews:v1` 转移到 `reviews:v3`:

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/routing/route-rule-reviews-50-v3.yaml@
    {{< /text >}}

    确认规则已被替换:

    {{< text yaml >}}
        $ istioctl get virtualservice reviews -o yaml
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
          - route:
            - destination:
                host: reviews
                subset: v3
              weight: 50
    {{< /text >}}

1.  刷新浏览器中的 `productpage` 页面，大约有50%的几率会看到页面中出带红色星级的评价内容。

    > 在目前的Envoy sidecar实现中，可能需要刷新 `productpage` 很多次才能看到流量分发的效果。在看到页面出现变化前，有可能需要刷新15次或者更多。
    > 如果修改规则，将90%的流量路由到v3，可以看到更明显的效果。

1.   当v3版本的 `reviews` 微服务被认为已经稳定后，我们可以将100%的流量路由到 `reviews:v3`：

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/routing/route-rule-reviews-v3.yaml@
    {{< /text >}}

    您现在可以以任何用户身份登录到 `productpage` 页面，始终都可以看到带红色星级评分的书评。

## 了解发生了什么

在这项任务中，我们使用Istio的加权路由功能将流量从旧版本的 `reviews` 服务迁移到新版本。请注意，这和使用容器编排平台的部署功能来进行版本迁移完全不同。
容器编排平台使用了实例扩容来对流量进行管理，而借助Istio，两个版本的 `reviews` 服务可以独立地进行扩容和缩容，并不会影响这两个版本服务之间的流量分发。
有关使用自动缩放的版本路由的更多信息，请查看[使用 Istio 的 Canary Deployments](/blog/2017/0.1-canary/) 。

## 清理

* 删除应用程序路由规则。

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/routing/route-rule-all-v1.yaml@
    {{< /text >}}

* 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/docs/examples/bookinfo/#cleanup) 的说明关闭应用程序。

## 进阶阅读

* 详细了解[请求路由](/docs/concepts/traffic-management/request-routing/)。
