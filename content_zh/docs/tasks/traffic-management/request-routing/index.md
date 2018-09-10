---
title: 配置请求路由
description: 此任务向您展示如何根据权重和 HTTP header配置动态请求路由。
weight: 10
keywords: [流量管理,路由]
---

> 该任务使用新的 [v1alpha3 流量管理 API](/zh/blog/2018/v1alpha3-routing/)。旧版本的API已被弃用，并将在下一个 Istio 版本中删除。 如果您需要使用旧版本，请点击[此处](https://archive.istio.io/v0.7/docs/tasks/traffic-management/)的文档。

此任务向您展示如何根据权重和 HTTP header配置动态请求路由。

## 开始之前

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。
* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序。

## 基于内容的路由

由于 Bookinfo 示例部署了三个版本的 reviews 微服务，因此我们需要设置默认路由。 否则，如果您当多次访问应用程序，您会注意到有时输出包含星级评分，有时又没有。
这是因为没有为应用明确指定缺省路由时，Istio 会将请求随机路由到该服务的所有可用版本上。

> 此任务假定您尚未设置任何路由。 如果您已经为示例应用程序创建了存在冲突的路由规则，则需要在下面的命令中使用 `replace` 代替 `create`。
请注意：本文档假设还没有设置任何路由规则。如果

1.  将所有微服务的默认版本设置为 v1。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/destination-rule-all.yaml@
    {{< /text >}}

    如果您启用了 `mTLS` ，请运行以下代码

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

    > 在kubernetes中部署 Istio 时，您可以在上面及其它所有命令行中用 `kubectl` 代替 `istioctl`。 但请注意，目前 `kubectl` 不提供输入验证。

    您可以通过下面的命令来显示已创建的路由规则:

    {{< text bash yaml >}}
    $ istioctl get virtualservices -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: details
      ...
    spec:
      hosts:
      - details
        http:
      - route:
        - destination:
            host: details
            subset: v1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: productpage
      ...
    spec:
      gateways:
      - bookinfo-gateway
      - mesh
        hosts:
      - productpage
        http:
      - route:
        - destination:
            host: productpage
            subset: v1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
      ...
    spec:
      hosts:
      - ratings
        http:
      - route:
        - destination:
            host: ratings
            subset: v1
    ---
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
    ---
    {{< /text >}}

    > 可以使用 `istioctl get destinationrules -o yaml`来显示路由规则对应的 `subset` 定义。

    由于路由规则是通过异步方式分发到代理的，因此在尝试访问应用程序之前，您应该等待几秒钟，以便规则传播到所有 pod 上。

1.  在浏览器中打开 Bookinfo 应用程序的 URL (`http://$GATEWAY_URL/productpage`)。
    回想一下，在部署 Bookinfo 示例时，应已参照[该说明](/zh/docs/examples/bookinfo/#确定-ingress-的-ip-和端口)设置好 `GATEWAY_URL` 。

    您应该可以看到 Bookinfo 应用程序的 `productpage` 页面。
    请注意， `productpage` 页面显示的内容中没有评分星级，这是因为 `reviews:v1` 服务不会访问 ratings 服务。

1.  将来自特定用户的请求路由到 `reviews:v2`。

    通过将来自 `productpage` 的流量路由到 `reviews:v2` 实例，为测试用户 "jason” 启用 ratings 服务。

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

    确认规则已创建：

    {{< text bash yaml >}}
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
      - match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: reviews
            subset: v2
      - route:
        - destination:
            host: reviews
            subset: v1
    {{< /text >}}

1.  在 `productpage` 网页上以用户 "jason” 身份登录。

    您现在应该在每次评论旁边看到评分（1-5颗星）。 请注意，如果您以任何其他用户身份登录，您将会继续看到 `reviews:v1` 版本服务，即不包含星级评价的页面。

## 理解原理

在此任务中，您首先使用 Istio 将 100% 的请求流量都路由到了 Bookinfo 服务的 v1 版本。 然后再设置了一条路由规则，该路由规则在 `productpage` 服务中添加基于请求的 "end-user" 自定义 header 选择性地将特定的流量路由到了 reviews 服务的 v2 版本。

请注意，为了利用 Istio 的 L7 路由功能，Kubernetes 中的服务（如本任务中使用的 Bookinfo 服务）必须遵守某些特定限制。
参考 [sidecar 注入文档](/zh/docs/setup/kubernetes/spec-requirements)了解详情。

在[流量转移](/zh/docs/tasks/traffic-management/traffic-shifting)任务中，您将按照在此处学习的相同基本模式来配置路由规则，以逐步将流量从服务的一个版本发送到另一个版本。

## 清除

1. 删除应用程序 virtual service。

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理) 的说明关闭应用程序。
