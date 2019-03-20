---
title: 故障注入
description: 此任务说明如何注入延迟并测试应用程序的弹性。
weight: 20
keywords: [traffic-management,fault-injection]
---

此任务说明如何注入延迟并测试应用程序的弹性。

## 前提条件

* 按照[安装指南](/zh/docs/setup/)中的说明设置 Istio 。

* 部署示例应用程序 [Bookinfo](/zh/docs/examples/bookinfo/)，并应用[缺省目标规则](/zh/docs/examples/bookinfo#应用缺省目标规则)。

* 在[流量管理](/zh/docs/concepts/traffic-management) 概念文档中查看有关故障注入的讨论。

* 通过首先执行[请求路由](/zh/docs/tasks/traffic-management/request-routing/)任务或运行以下命令来初始化应用程序版本路由：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

* 通过上面的配置，下面是请求的流程：
    *  `productpage` → `reviews:v2` → `ratings` (`jason` 用户)
    *  `productpage` → `reviews:v1` (其他用户)

## 使用 HTTP 延迟进行故障注入

为了测试微服务应用程序 Bookinfo 的弹性，我们将为用户 `jason` 在 `reviews:v2` 和 `ratings` 服务之间注入一个 7 秒的延迟。
这个测试将会发现故意引入 Bookinfo 应用程序中的错误。

由于 `reviews:v2` 服务对其 ratings 服务的调用具有 10 秒的硬编码连接超时，比我们设置的 7s 延迟要大，因此我们期望端到端流程是正常的（没有任何错误）。

1. 创建故障注入规则以延迟来自用户 `jason`（我们的测试用户）的流量

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml@
    {{< /text >}}

1. 确认已创建规则：

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
            percent: 100
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

    规则可能需要几秒钟才能传播到所有的 pod 。

## 延时配置测试

1. 通过浏览器打开 [Bookinfo](/zh/docs/examples/bookinfo) 应用。

1. 使用用户 `jason` 登陆到 `/productpage` 界面。

    你期望 Bookinfo 主页在大约 7 秒钟加载完成并且没有错误。但是，出现了一个问题，Reviews 部分显示了错误消息：

    {{< text plain >}}
    Error fetching product reviews!
    Sorry, product reviews are currently unavailable for this book.
    {{< /text >}}

1. 查看页面的返回时间：
    1. 打开浏览器的 *开发工具* 菜单
    1. 打开 *网络* 标签
    1. 重新加载 `productpage` 页面，你会看到页面实际上用了大约 6s。

## 理解原理

你发现了一个 bug。在微服务中有硬编码超时，导致 `reviews` 服务失败。

在 `productpage` 和 `reviews` 服务之间超时时间是 6s - 编码 3s + 1 次重试总共 6s ，`reviews` 和 `ratings` 服务之间的硬编码连接超时为 10s 。由于我们引入的延时，`/productpage` 提前超时并引发错误。

这些类型的错误可能发生在典型的企业应用程序中，其中不同的团队独立地开发不同的微服务。Istio 的故障注入规则可帮助您识别此类异常，而不会影响最终用户。

{{< tip >}}
请注意，我们仅限制用户 `jason` 的失败影响。如果您以任何其他用户身份登录，则不会遇到任何延迟。
{{< /tip >}}

## 错误修复

你通常会解决这样的问题：

1. 要么增加 `/productpage` 的超时或者减少 `reviews` 到 `ratings` 服务的超时
1. 终止并重启微服务
1. 确认 `productpage` 正常响应并且没有任何错误。

但是，我们已经在 `reviews` 服务的 v3 版中运行此修复程序，因此我们可以通过将所有流量迁移到 `reviews:v3` 来解决问题，
如[流量转移](/zh/docs/tasks/traffic-management/traffic-shifting/)中所述任务。

## 练习

将延迟规则更改为使用 2.8 秒延迟，然后针对 v3 版本的 `reviews` 运行它。

## 使用 HTTP abort 进行故障注入

测试微服务弹性的另一种方法是引入 HTTP abort 故障。在这个任务中，在 `ratings` 微服务中引入 HTTP abort ，测试用户为 `jason` 。

在这个案例中，我们希望页面能够立即加载，同时显示 `Ratings service is currently unavailable` 这样的消息。

1. 为用户 `jason` 创建故障注入规则发送 HTTP abort

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml@
    {{< /text >}}

1. 确认已创建规则

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
            percent: 100
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

## 测试中止配置

1. 通过浏览器打开 [Bookinfo](/zh/docs/examples/bookinfo) 应用。

1. 使用用户 `jason` 登陆到 `/productpage` 界面。

    如果规则成功传播到所有的 pod，您应该能立即看到页面加载并看到 `Ratings service is currently unavailable` 消息。

1. 如果您注销用户 `jason` 或在匿名窗口（或其他浏览器）中打开 Bookinfo 应用程序，
   您将看到 `/productpage` 为除 `jason` 以外用户调用了 `reviews:v1`（它根本不调用 `ratings`）。
   因此，您不会看到任何错误消息。

## 清理

1. 删除应用程序路由规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)说明以关闭应用程序。
