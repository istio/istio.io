---
title: 配置请求路由
description: 此任务将展示如何将请求动态路由到微服务的多个版本。
weight: 10
aliases:
    - /zh/docs/tasks/request-routing.html
keywords: [traffic-management,routing]
---

此任务将展示如何将请求动态路由到微服务的多个版本。

## 开始之前{#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序。

* 查看[流量管理](/zh/docs/concepts/traffic-management)的概念文档。在尝试此任务之前，您应该熟悉一些重要的术语，例如 *destination rule* 、*virtual service* 和 *subset* 。

## 关于这个任务{#about-this-task}

Istio [Bookinfo](/zh/docs/examples/bookinfo/) 示例包含四个独立的微服务，每个微服务都有多个版本。
其中一个微服务 `reviews` 的三个不同版本已经部署并同时运行。
为了说明这导致的问题，在浏览器中访问 Bookinfo 应用程序的 `/productpage` 并刷新几次。
您会注意到，有时书评的输出包含星级评分，有时则不包含。
这是因为没有明确的默认服务版本路由，Istio 将以循环方式请求路由到所有可用版本。

此任务的最初目标是应用将所有流量路由到微服务的 `v1` （版本 1）的规则。稍后，您将应用规则根据 HTTP 请求 header 的值路由流量。

## 应用 virtual service{#apply-a-virtual-service}

要仅路由到一个版本，请应用为微服务设置默认版本的 virtual service。在这种情况下，virtual service 将所有流量路由到每个微服务的 `v1` 版本。

{{< warning >}}
如果您还没有应用 destination rule，请先[应用默认目标规则](/zh/docs/examples/bookinfo/#apply-default-destination-rules)。
{{< /warning >}}

1. 运行以下命令以应用 virtual services:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

    由于配置传播是最终一致的，因此请等待几秒钟以使 virtual services 生效。

1. 使用以下命令显示已定义的路由：

    {{< text bash yaml >}}
    $ kubectl get virtualservices -o yaml
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

1. 您还可以使用以下命令显示相应的 `subset` 定义:

    {{< text bash >}}
    $ kubectl get destinationrules -o yaml
    {{< /text >}}

您已将 Istio 配置为路由到 Bookinfo 微服务的 `v1` 版本，最重要的是 `reviews` 服务的版本 1。

## 测试新的路由配置{#test-the-new-routing-configuration}

您可以通过再次刷新 Bookinfo 应用程序的 `/productpage` 轻松测试新配置。

1. 在浏览器中打开 Bookinfo 站点。 网址为 `http://$GATEWAY_URL/productpage`，其中 `$GATEWAY_URL` 是外部的入口 IP 地址，如 [Bookinfo](/zh/docs/examples/bookinfo/#determine-the-ingress-ip-and-port) 文档中所述。

    请注意，无论您刷新多少次，页面的评论部分都不会显示评级星标。这是因为您将 Istio 配置为
    将评论服务的所有流量路由到版本 `reviews:v1`，而此版本的服务不访问星级评分服务。

您已成功完成此任务的第一部分：将流量路由到服务的某一个版本。

## 基于用户身份的路由{#route-based-on-user-identity}

接下来，您将更改路由配置，以便将来自特定用户的所有流量路由到特定服务版本。在这，来自名为 Jason 的用户的所有流量将被路由到服务 `reviews:v2`。

请注意，Istio 对用户身份没有任何特殊的内置机制。事实上， `productpage` 服务在所有到 `reviews` 服务的 HTTP 请求中都增加了一个自定义的 `end-user` 请求头，从而达到了本例子的效果。

请记住，`reviews:v2` 是包含星级评分功能的版本。

1. 运行以下命令以启用基于用户的路由：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

1. 确认规则已创建：

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

1. 在 Bookinfo 应用程序的 `/productpage` 上，以用户 `jason` 身份登录。

    刷新浏览器。你看到了什么？星级评分显示在每个评论旁边。

1. 以其他用户身份登录（选择您想要的任何名称）。

    刷新浏览器。现在星星消失了。这是因为除了 Jason 之外，所有用户的流量都被路由到 `reviews:v1`。

您已成功配置 Istio 以根据用户身份路由流量。

## 理解原理{#understanding-what-happened}

在此任务中，您首先使用 Istio 将 100% 的请求流量都路由到了 Bookinfo 服务的 v1 版本。
然后设置了一条路由规则，它根据 `productpage` 服务发起的请求中的 `end-user` 自定义请求头内容，选择性地将特定的流量路由到了 `reviews` 服务的 `v2` 版本。

请注意，Kubernetes 中的服务，如本任务中使用的 Bookinfo 服务，必须遵守某些特定限制，才能利用到 Istio 的 L7 路由特性优势。
参考 [Pods 和 Services 需求](/zh/docs/setup/additional-setup/requirements)了解详情。

在[流量转移](/zh/docs/tasks/traffic-management/traffic-shifting)任务中，您将按照在此处学习到的相同的基本模式来配置路由规则，以逐步将流量从服务的一个版本迁移到另一个版本。

## 清除{#cleanup}

1. 删除应用程序的 virtual service：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup) 的说明关闭应用程序。
