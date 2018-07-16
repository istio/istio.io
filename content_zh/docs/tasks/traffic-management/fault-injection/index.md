---
title: 故障注入
description: 此任务说明如何注入延迟并测试应用程序的弹性。
weight: 20
keywords: [traffic-management,fault-injection]
aliases:
    - /docs/tasks/fault-injection.html
---

> 注意：此任务使用新的 [v1alpha3 流量管理 API](/blog/2018/v1alpha3-routing/)。旧的 API 已被弃用，将在下一个 Istio 版本中删除。如果您需要使用旧版本，请按照[此处](https://archive.istio.io/v0.7/docs/tasks/traffic-management/)的文档操作。

此任务说明如何注入延迟并测试应用程序的弹性。

## 前提条件

* 按照[安装指南](/docs/setup/)中的说明设置 Istio 。

* 部署示例应用程序 [Bookinfo](/docs/examples/bookinfo/) 。

*   通过首先执行[请求路由](/docs/tasks/traffic-management/request-routing/)任务或运行以下命令来初始化应用程序版本路由：

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

## 使用 HTTP 延迟进行故障注入

为了测试我们的微服务应用程序 Bookinfo 的弹性，我们将在 reviews :v2 和 ratings 服务之间的一个用户 “jason” _注入一个 7 秒_ 的延迟。
由于 _reviews:v2_ 服务对其 ratings 服务的调用具有 10 秒的硬编码连接超时，因此我们期望端到端流程是正常的（没有任何错误）。

1.  创建故障注入规则以延迟来自用户 “jason”（我们的测试用户）的流量

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml@
    {{< /text >}}

    确认已创建规则：

    {{< text bash yaml >}}
    $ istioctl get virtualservice ratings -o yaml
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
            cookie:
              regex: ^(.*?;)?(user=jason)(;.*)?$
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

1.  观察应用程序行为

    以 “jason” 用户身份登录。如果应用程序的首页设置为正确处理延迟，我们预计它将在大约 7 秒内加载。
    要查看网页响应时间，请在IE，Chrome 或 Firefox 中打开 *Developer Tools* 菜单（通常，组合键 _Ctrl+Shift+I_ 或 _Alt+Cmd+I_ ），
    选项卡 Network，然后重新加载 `productpage` 网页 。

    您将看到网页加载大约 6 秒钟。评论部分将显示 *对不起，此书的产品评论目前不可用* 。

## 了解发生了什么

整个评论服务失败的原因是我们的 Bookinfo 应用程序有错误。
产品页面和评论服务之间的超时（评分为 3 次+ 1 次重试 = 总共 6 次）比评论和评级服务之间的超时时间（硬编码连接超时为 10 秒）。
这些类型的错误可能发生在典型的企业应用程序中，其中不同的团队独立地开发不同的微服务。
Istio 的故障注入规则可帮助您识别此类异常，而不会影响最终用户。

> 请注意，我们仅限制用户 “jason” 的失败影响。, 如果您以任何其他用户身份登录，则不会遇到任何延迟。

**修复错误：** 此时我们通常会通过增加产品页面超时或减少评级服务超时的评论来解决问题，
终止并重启固定的微服务，然后确认 `productpage` 返回其响应, 没有任何错误。

但是，我们已经在评论服务的第 3 版中运行此修复程序，
因此我们可以通过将所有流量迁移到 `reviews:v3` 来解决问题，
如[流量转移](/docs/tasks/traffic-management/traffic-shifting/)中所述任务。

（作为读者的练习 - 将延迟规则更改为使用 2.8 秒延迟，然后针对 v3 版本的评论运行它。）

## 使用 HTTP Abort 进行故障注入

作为弹性的另一个测试，我们将在 ratings 服务中，给用户 jason 的调用加上一个 HTTP 中断 。 我们希望页面能够立即加载，而不像延迟示例那样显示“产品评级不可用”消息。

1. 为用户 “jason” 创建故障注入规则发送 HTTP 中止

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml@
    {{< /text >}}

    确认已创建规则

    {{< text bash yaml >}}
    $ istioctl get virtualservice ratings -o yaml
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
            cookie:
              regex: ^(.*?;)?(user=jason)(;.*)?$
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

1.  观察应用程序行为

    以 “jason” 用户名登录, 如果规则成功传播到所有的 pod ，您应该能立即看到页面加载“产品评级不可用”消息。 从用户  “jason”  注销，您应该会在产品页面网页上看到评级星标的评论成功显示。

## 清理

*   删除应用程序路由规则：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

* 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/docs/examples/bookinfo/#cleanup)说明以关闭应用程序。
