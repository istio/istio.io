---
title: 故障注入
description: 此任务说明如何注入延迟并测试应用程序的弹性。
weight: 20
keywords: [流量管理,故障注入]
---

此任务说明如何注入延迟并测试应用程序的弹性。

## 前提条件

* 按照[安装指南](/zh/docs/setup/)中的说明设置 Istio 。

* 部署示例应用程序 [Bookinfo](/zh/docs/examples/bookinfo/) 。

* 在[流量管理](/zh/docs/concepts/traffic-management) 概念文档中查看有关故障注入的讨论。

* 通过首先执行[请求路由](/zh/docs/tasks/traffic-management/request-routing/)任务或运行以下命令来初始化应用程序版本路由：

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

## 使用 HTTP 延迟进行故障注入

为了测试我们的微服务应用程序 Bookinfo 的弹性，我们将在 reviews :v2 和 ratings 服务之间的一个用户 "jason” _注入一个 7 秒_ 的延迟。
由于 _reviews:v2_ 服务对其 ratings 服务的调用具有 10 秒的硬编码连接超时，因此我们期望端到端流程是正常的（没有任何错误）。

1. 创建故障注入规则以延迟来自用户 "jason”（我们的测试用户）的流量

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml@
    {{< /text >}}

1. 确认已创建规则：

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

    你期望 Bookinfo 主页在大约 7 秒钟加载完成并且没有错误。但是，出现了一个问题，评论部分显示了错误消息：

    {{< text plain >}}
    获取产品评论错误!
    抱歉, 本书目前没有可用的评论。
    {{< /text >}}

## 了解发生了什么

整个评论服务失败的原因是我们的 Bookinfo 应用程序有错误。
产品页面和评论服务之间的超时（评分为 3 次+ 1 次重试 = 总共 6 次）比评论和评级服务之间的超时时间（硬编码连接超时为 10 秒）。
这些类型的错误可能发生在典型的企业应用程序中，其中不同的团队独立地开发不同的微服务。
Istio 的故障注入规则可帮助您识别此类异常，而不会影响最终用户。

> 请注意，我们仅限制用户 "jason” 的失败影响。, 如果您以任何其他用户身份登录，则不会遇到任何延迟。

## 错误修复

你通常会解决这样的问题：

1. 此时我们通常会通过增加产品页面超时或减少评级服务超时的评论来解决问题，
1. 终止并重启固定的微服务
1. 确认 `productpage` 返回其响应, 没有任何错误。

但是，我们已经在评论服务的第 3 版中运行此修复程序，
因此我们可以通过将所有流量迁移到 `reviews:v3` 来解决问题，
如[流量转移](/zh/docs/tasks/traffic-management/traffic-shifting/)中所述任务。

## 练习

（作为读者的练习 - 将延迟规则更改为使用 2.8 秒延迟，然后针对 v3 版本的评论运行它。）

## 使用 HTTP Abort 进行故障注入

作为弹性的另一个测试，我们将在 ratings 服务中，给用户 jason 的调用加上一个 HTTP 中断。

我们希望页面能够立即加载，而不像延迟示例那样显示"产品评级不可用”消息。

1. 为用户 "jason” 创建故障注入规则发送 HTTP 中止

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml@
    {{< /text >}}

1. 确认已创建规则

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

    如果规则成功传播到所有的 pod ，您应该能立即看到页面加载"产品评级不可用”消息。

1. 注销用户 "jason”，您应该会在产品页面网页上看到评级星标的评论成功显示。

## 清理

1. 删除应用程序路由规则：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果您不打算探索任何后续任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)说明以关闭应用程序。
