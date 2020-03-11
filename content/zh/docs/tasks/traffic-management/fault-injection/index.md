---
title: 故障注入
description: 此任务说明如何注入故障并测试应用程序的弹性。
weight: 20
keywords: [traffic-management,fault-injection]
aliases:
    - /zh/docs/tasks/fault-injection.html
---

此任务说明如何注入故障并测试应用程序的弹性。

## 开始之前{#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明设置 Istio 。

* 部署示例应用程序 [Bookinfo](/zh/docs/examples/bookinfo/)，并应用
  [默认目标规则](/zh/docs/examples/bookinfo/#apply-default-destination-rules)。

* 在[流量管理](/zh/docs/concepts/traffic-management)概念文档中查看有关故障注入的讨论。

* 通过执行[配置请求路由](/zh/docs/tasks/traffic-management/request-routing/)任务或运行以下命令来初始化应用程序版本路由：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

* 经过上面的配置，下面是请求的流程：
    *  `productpage` → `reviews:v2` → `ratings` (针对 `jason` 用户)
    *  `productpage` → `reviews:v1` (其他用户)

## 注入 HTTP 延迟故障{#injecting-an-http-delay-fault}

为了测试微服务应用程序 Bookinfo 的弹性，我们将为用户 `jason` 在 `reviews:v2` 和 `ratings` 服务之间注入一个 7 秒的延迟。
这个测试将会发现一个故意引入 Bookinfo 应用程序中的 bug。

注意 `reviews:v2` 服务对 `ratings` 服务的调用具有 10 秒的硬编码连接超时。
因此，尽管引入了 7 秒的延迟，我们仍然期望端到端的流程是没有任何错误的。

1. 创建故障注入规则以延迟来自测试用户 `jason` 的流量：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml@
    {{< /text >}}

1. 确认规则已经创建：

    {{< text bash yaml >}}
    $ kubectl get virtualservice ratings -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
      ...
    spec:
      hosts:
      - ratings
      http:
      - fault:
          delay:
            fixedDelay: 7s
            percentage:
              value: 100
        match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

    新的规则可能需要几秒钟才能传播到所有的 pod 。

## 测试延迟配置{#testing-the-delay-configuration}

1. 通过浏览器打开 [Bookinfo](/zh/docs/examples/bookinfo) 应用。

1. 使用用户 `jason` 登陆到 `/productpage` 页面。

    你期望 Bookinfo 主页在大约 7 秒钟加载完成并且没有错误。
    但是，出现了一个问题：Reviews 部分显示了错误消息：

    {{< text plain >}}
    Error fetching product reviews!
    Sorry, product reviews are currently unavailable for this book.
    {{< /text >}}

1. 查看页面的响应时间：

    1. 打开浏览器的 *开发工具* 菜单
    1. 打开 *网络* 标签
    1. 重新加载 `productpage` 页面。你会看到页面加载实际上用了大约 6s。

## 理解原理{#understanding-what-happened}

你发现了一个 bug。微服务中有硬编码超时，导致 `reviews` 服务失败。

按照预期，我们引入的 7 秒延迟不会影响到 `reviews` 服务，因为 `reviews` 和 `ratings` 服务间的超时被硬编码为 10 秒。
但是，在 `productpage` 和 `reviews` 服务之间也有一个 3 秒的硬编码的超时，再加 1 次重试，一共 6 秒。
结果，`productpage` 对 `reviews` 的调用在 6 秒后提前超时并抛出错误了。

这种类型的错误可能发生在典型的由不同的团队独立开发不同的微服务的企业应用程序中。
Istio 的故障注入规则可以帮助您识别此类异常，而不会影响最终用户。

{{< tip >}}
请注意，此次故障注入限制为仅影响用户 `jason`。如果您以任何其他用户身份登录，则不会遇到任何延迟。
{{< /tip >}}

## 错误修复{#fixing-the-bug}

这种问题通常会这么解决：

1. 增加 `productpage` 与 `reviews` 服务之间的超时或降低 `reviews` 与 `ratings` 的超时
1. 终止并重启修复后的微服务
1. 确认 `/productpage` 页面正常响应且没有任何错误

但是，`reviews` 服务的 v3 版本已经修复了这个问题。
`reviews:v3` 服务已将 `reviews` 与 `ratings` 的超时时间从 10 秒降低为 2.5 秒，因此它可以兼容（小于）下游的 `productpage` 的请求。

如果您按照[流量转移](/zh/docs/tasks/traffic-management/traffic-shifting/)任务所述将所有流量转移到 `reviews:v3`，
您可以尝试修改延迟规则为任何低于 2.5 秒的数值，例如 2 秒，然后确认端到端的流程没有任何错误。

## 注入 HTTP abort 故障{#injecting-an-http-abort-fault}

测试微服务弹性的另一种方法是引入 HTTP abort 故障。
这个任务将给 `ratings` 微服务为测试用户 `jason` 引入一个 HTTP abort。

在这种情况下，我们希望页面能够立即加载，同时显示 `Ratings service is currently unavailable` 这样的消息。

1. 为用户 `jason` 创建一个发送 HTTP abort 的故障注入规则：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml@
    {{< /text >}}

1. 确认规则已经创建：

    {{< text bash yaml >}}
    $ kubectl get virtualservice ratings -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ratings
      ...
    spec:
      hosts:
      - ratings
      http:
      - fault:
          abort:
            httpStatus: 500
            percentage:
              value: 100
        match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

## 测试中止配置{#testing-the-abort-configuration}

1. 用浏览器打开 [Bookinfo](/zh/docs/examples/bookinfo) 应用。

1. 使用用户 `jason` 登陆到 `/productpage` 页面。

    如果规则成功传播到所有的 pod，您应该能立即看到页面加载并看到 `Ratings service is currently unavailable` 消息。

1. 如果您注销用户 `jason` 或在匿名窗口（或其他浏览器）中打开 Bookinfo 应用程序，
   您将看到 `/productpage` 为除 `jason` 以外的其他用户调用了 `reviews:v1`（完全不调用 `ratings`）。
   因此，您不会看到任何错误消息。

## 清理{#cleanup}

1. 删除应用程序路由规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)说明以关闭应用程序。
