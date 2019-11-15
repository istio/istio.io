---
title: 启用速率限制
description: 这部分内容将向您展示如何使用 Istio 去动态限制服务间的流量。
weight: 10
keywords: [policies,quotas]
aliases:
    - /zh/docs/tasks/rate-limiting.html
---

这部分内容将向您展示如何使用 Istio 去动态限制服务间的流量。

## 开始之前{#before-you-begin}

1. 依照[安装指引](/zh/docs/setup/install/kubernetes/)在 Kubernetes 中 安装 Istio。

    {{< warning >}}
    Policy enforcement **必须**开启。依照
    [启用 Policy Enforcement](/zh/docs/tasks/policy-enforcement/enabling-policy/) 确定 policy enforcement 已经开启。
    {{< /warning >}}

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用。

    Bookinfo 部署了 3 个版本的 `reviews` 服务：

    * 版本 v1 不会调用 `ratings` 服务。
    * 版本 v2 调用 `ratings` 服务，且为每个评价显示 1 到 5 颗黑色星星。
    * 版本 v3 调用 `ratings` 服务，且为每个评价显示 1 到 5 颗红色星星。

    您需要指定其中一个版本为默认路由。否则，当您向 `reviews` 服务发送请求时，Istio 会随机路由到其中一个服务上，表现为有时显示星星，有时不会。

1.  将所有服务的默认版本设置为 v1。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

## 速率限制{#rate-limits}

在这部分，Istio 将以客户端的 IP 地址限制 `productpage` 的流量。
您将会使用 `X-Forwarded-For` 请求头作为客户端 IP 地址。也将会针对已登录的用户应用有条件的速率限制。

方便起见，配置 [memory quota](/zh/docs/reference/config/policy-and-telemetry/adapters/memquota/)(`memquota`) 适配器用以启用速率限制。
如果在生产系统使用的是 [Redis](http://redis.io/)，那么启用 [Redis quota](/zh/docs/reference/config/policy-and-telemetry/adapters/redisquota/)
(`redisquota`) 适配器。`memquota` 与 `redisquota` 适配器都支持 [quota template](/zh/docs/reference/config/policy-and-telemetry/templates/quota/)，
所以他们的配置是一样的。

1. 速率限制的配置分为两部分。
    * 客户端
        * `QuotaSpec` 定义 quota 名称与客户端请求的数量。
        * `QuotaSpecBinding` 条件化的关联 `QuotaSpec` 到一个或多个服务。
    * Mixer 端
        * `quota instance` 定义 quota 的维度。
        * `memquota handler` 定义 `memquota` 适配器的配置。
        * `quota rule` 定义 quota 实例何时分发到 `memquota` 适配器。

    执行如下命令使用 `memquota` 开启速率限制：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更低版本，使用如下命令代替：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

    `memquota` 处理器定义了 4 个不同的速率限制规则。默认如果没有匹配到优先规则，是 `500` 个请求量每秒 (`1s`)。
    我们也定义了两个优先规则：

    * 第一种是 `1` 个请求量 (`maxAmount` 字段) 每 `5s` (`validDuration` 字段)，如果`目标服务`是 `reviews`。
    * 第二种是 `500` 个请求量每 `1s`，如果`目标服务`是 `productpage` 且来源于 `10.28.11.20`。
    * 第三种是 `2` 个请求量每 `5s`，如果`目标服务`是 `productpage`。

    当一个请求被处理时，第一个被匹配到的优先规则会被触发(从上到下)。

    或者

    执行如下命令使用 `redisquota` 开启流量限制：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-redis-quota-rolling-window.yaml@
    {{< /text >}}

    _注意:_ 替换您的配置中 [rate_limit_algorithm](/zh/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params-QuotaAlgorithm)，
    [redis_server_url](/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params) 的值.

    `redisquota` 处理器定义了 4 个不同的速率限制规则。默认如果没有匹配到优先规则，是 `500` 个请求量每秒 (`1s`)。
    使用了 `ROLLING_WINDOW` 算法作为 quota 检查且为之定义了 500ms 的 `bucketDuration`。我们也定义了三个优先规则：

    * 第一种是 `1` 个请求量 (`maxAmount` 字段)，如果`目标服务`是 `reviews`。
    * 第二种是 `500`，如果`目标服务`是 `productpage` 且来源于 `10.28.11.20`。
    * 第三种是 `2`，如果`目标服务`是 `productpage`。

    当一个请求被处理时，第一个被匹配到的优先规则会被触发(从上到下)。

1. 确认 `quota 实例`已被创建：

    {{< text bash >}}
    $ kubectl -n istio-system get instance requestcountquota -o yaml
    {{< /text >}}

    `quota` 模板通过 `memquota` 或 `redisquota` 定义了三个维度以匹配特定的属性的方式设置优先规则。
    `目标服务`会被设置为 `destination.labels["app"]`，`destination.service.host`，或 `"unknown"` 中的第一个非空值。
     表达式的更多信息，见 [Expression Language](/zh/docs/reference/config/policy-and-telemetry/expression-language/)。

1. 确认 `quota rule` 已被创建：

    {{< text bash >}}
    $ kubectl -n istio-system get rule quota -o yaml
    {{< /text >}}

    `rule` 告诉 Mixer 去调用 `memquota` 或 `redisquota` 处理器（上面创建的）且传递 `requestcountquota` 构造的对象（也是上面创建的）。
    这里将 `quota` 模板与 `memquota` 或 `redisquota` 处理器的维度一一对应。

1. 确认 `QuotaSpec` 已被创建：

    {{< text bash >}}
    $ kubectl -n istio-system get QuotaSpec request-count -o yaml
    {{< /text >}}

    `QuotaSpec` 用值 `1` 定义了您上面创建的 `requestcountquota`。

1. 确认 `QuotaSpecBinding` 已被创建：

    {{< text bash >}}
    $ kubectl -n istio-system get QuotaSpecBinding request-count -o yaml
    {{< /text >}}

    `QuotaSpecBinding` 绑定了您上面创建的 `QuotaSpec` 与您想要生效的服务。`productpage` 显式的绑定了 `request-count`，
    注意您必须定义与 `QuotaSpecBinding` 不同的命名空间。
    如果最后一行注释被打开， `service: '*'` 将绑定所有服务到 `QuotaSpec` 使得首个 entry 是冗余的。

1. 在浏览器上刷新 product 页面。

    `request-count` quota 应用于 `productpage` 且只允许 2 个请求量每 5 秒。如果您持续刷新页面将会看到
    `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`。

## 条件化的速率限制{#conditional-rate-limits}

在上面的例子我们为每个客户端 IP 地址的 `productpage` 限制了 `2 rps`。
考虑这样一个场景，如果您想要对已登录的用户放开速率限制。在 `bookinfo` 的例子中，我们用 cookie `session=<sessionid>` 去指代一个已登录用户。
在现实场景中您可能会用 `jwt` token 去实现这个目的。

您可以添加基于 `cookie` 的匹配条件更新 `quota rule`。

{{< text bash >}}
$ kubectl -n istio-system edit rules quota
{{< /text >}}

{{< text yaml >}}
...
spec:
  match: match(request.headers["cookie"], "session=*") == false
  actions:
...
{{< /text >}}

{{< warning >}}
不要启用 [chrome preload](https://support.google.com/chrome/answer/114836?hl=en&co=GENIE.Platform=Desktop)，
它会预加载 cookies 从而导致此任务失败。
{{< /warning >}}

`memquota` 或 `redisquota` 适配器现在只有请求中存在 `session=<sessionid>` cookie 才会被分发。
这可以确保已登录的用户不会受限于这个 quota。

1.  确认速率限制没有生效于已登录的用户。

    以 `jason` 身份登录且反复刷新 `productpage` 页面。现在这样做不会出现任何问题。

1.  确认速率限制 *生效* 于未登录的用户。

    退出登录且反复刷新 `productpage` 页面。
    您将会再次看到 `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`。

## 理解原理{#understanding-rate-limits}

在先前的例子中你已经看到了 Mixer 是怎么通过匹配特定的条件对请求应用速率限制的。

每个具名的 quota 实例比如 `requestcount` 会提供一组计数器。
这组计数器用所有 quota 维度的笛卡尔积来定义。如果最后一个`有效期`内的请求数超出 `maxAmount`,
Mixer 返回一个 `RESOURCE_EXHAUSTED` 消息给 Envoy 代理，然后 Envoy 返回状态码 `HTTP 429` 给调用者。

`memquota` 适配器使用一个亚秒级的滑动窗口来执行速率限制。

`redisquota` 适配器可以配置使用[`ROLLING_WINDOW` 或 `FIXED_WINDOW`](/zh/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params-QuotaAlgorithm)
算法之一来执行速率限制。

适配器配置内的 `maxAmount` 为所有关联到 quota 实例的计数器设置了默认限制。这个默认限制应用在其他优先规则没有被匹配到的时候。
`memquota/redisquota` 适配器会选择第一个与请求相匹配的优先规则。一个优先规则不能指明所有的 quota 维度。
在这个例子里，0.2 qps 的规则被选择到通过只匹配了四分之三的 quota 维度。

如果您想要策略在给定的命名空间上执行而非整个 Istio 网格，可以把前面所有出现的 `istio-system` 替换为您想要的命名空间。

## 清理{#cleanup}

1. 如果使用 `memquota`，移除 `memquota` 速率限制配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml@
    {{< /text >}}

    如果您使用 Istio 1.1.2 或更低：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit-crd.yaml@
    {{< /text >}}

    或

    如果使用 `redisquota`，移除 `redisquota` 速率限制配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-redis-quota-rolling-window.yaml@
    {{< /text >}}

1. 移除应用路由规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果您不准备探索更多的任务，参考 [Bookinfo cleanup](/zh/docs/examples/bookinfo/#cleanup) 关闭整个应用。
