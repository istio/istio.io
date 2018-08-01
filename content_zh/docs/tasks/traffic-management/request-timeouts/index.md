---
title: 设置请求超时
description: 本任务用于示范如何使用 Istio 在 Envoy 中设置请求超时。
weight: 28
aliases:
    - /docs/tasks/request-timeouts.html
keywords: [traffic-management,timeouts]
---

> 本文任务使用了新的 [v1alpha3 流量控制 API](/zh/blog/2018/v1alpha3-routing/)。旧版本 API 已经过时，会在下一个 Istio 版本中移除。如果需要使用旧版本 API，请阅读[旧版本文档](https://archive.istio.io/v0.7/docs/tasks/traffic-management/)

本任务用于示范如何使用 Istio 在 Envoy 中设置请求超时。

## 开始之前

* 跟随[安装指南](/zh/docs/setup)设置 Istio。

* 部署示例应用程序 [Bookinfo](/zh/docs/examples/bookinfo/) 。

* 使用下面的命令初始化应用的版本路由：

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

## 请求超时

可以在路由规则的 `httpReqTimeout` 字段中来给 http 请求设置请求超时。缺省情况下，超时被设置为 15 秒钟，本文任务中，会把 `reviews` 服务的超时设置为一秒钟。为了能观察设置的效果，还需要在对 `ratings` 服务的调用中加入两秒钟的延迟。

1. 到 `reviews:v2` 服务的路由定义：

    {{< text bash >}}
    $ cat <<EOF | istioctl replace -f -
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
            subset: v2
    EOF
    {{< /text >}}

1. 在对 `ratings` 服务的调用中加入两秒钟的延迟：

    {{< text bash >}}
    $ cat <<EOF | istioctl replace -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
    spec:
      hosts:
      - ratings
      http:
      - fault:
          delay:
            percent: 100
            fixedDelay: 2s
        route:
        - destination:
            host: ratings
            subset: v1
    EOF
    {{< /text >}}

1. 用浏览器打开网址 `http://$GATEWAY_URL/productpage`，浏览 Bookinfo 应用。

    这时应该能看到 Bookinfo 应用在正常运行（显示了评级的星形符号），但是每次刷新页面，都会出现两秒钟的延迟。

1. 接下来在目的为 `reviews:v2` 服务的请求加入一秒钟的请求超时：

    {{< text bash >}}
    $ cat <<EOF | istioctl replace -f -
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
            subset: v2
        timeout: 1s
    EOF
    {{< /text >}}

1. 刷新 Bookinfo 的 Web 页面。

    这时候应该看到一秒钟就会返回，而不是之前的两秒钟，但 `reviews` 的显示已经不见了。

## 发生了什么？

上面的任务中，使用 Istio 为调用 `reviews` 微服务的请求中加入了一秒钟的超时控制，覆盖了缺省的 15 秒钟设置。页面刷新时，`reviews` 服务后面会调用 `ratings` 服务，使用 Istio 在对 `ratings` 的调用中注入了两秒钟的延迟，这样就让 `reviews` 服务要花费超过一秒钟的时间来调用 `ratings` 服务，从而触发了我们加入的超时控制。

这样就会看到 Bookinfo 的页面（ 页面由 `reviews` 服务生成）上没有出现 `reviews` 服务的显示内容，取而代之的是错误信息：**Sorry, product reviews are currently unavailable for this book** ，出现这一信息的原因就是因为来自 `reviews` 服务的超时错误。

如果测试了[故障注入任务](/zh/docs/tasks/traffic-management/fault-injection/)，会发现 `productpage` 微服务在调用 `reviews` 微服务时，还有自己的应用级超时设置（三秒钟）。注意这里我们用路由规则设置了一秒钟的超时。如果把超时设置为超过三秒钟（例如四秒钟）会毫无效果，这是因为内部的服务中设置了更为严格的超时要求。更多细节可以参见[故障处理 FAQ](/zh/docs/concepts/traffic-management/#faq) 的相关内容。

还有一点关于 Istio 中超时控制方面的补充说明，除了像本文一样在路由规则中进行超时设置之外，还可以进行请求一级的设置，只需在应用的外发流量中加入 `x-envoy-upstream-rq-timeout-ms` Header 即可。在这个 Header 中的超时设置单位是毫秒而不是秒。

## 清理

* 移除应用的路由规则：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

* 如果不准备继续探索后续任务，根据 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)内容来关停示例应用。