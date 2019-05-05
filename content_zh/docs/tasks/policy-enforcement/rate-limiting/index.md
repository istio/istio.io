---
title: 启用速率限制
description: 这一任务展示了如何使用 Istio 动态的对服务通信进行速率限制。
weight: 10
keywords: [policies,quotas]
---

这一任务展示了如何使用 Istio 动态的对服务通信进行速率限制。

## 开始之前

1. 按照[安装指南](/zh/docs/setup/kubernetes/install/kubernetes/)在 Kubernetes 集群上设置 Istio。

    {{< warning >}}
    本任务要求集群中**必须**启用策略支持。遵循[启用策略检查](/zh/docs/tasks/policy-enforcement/enabling-policy/)的步骤，确保策略支持已经启用。
    {{< /warning >}}

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用。

    Bookinfo 例子中需要部署三个版本的 `reviews` 服务：

    * v1 版本不会调用 `ratings` 服务。
    * v2 版本调用 `ratings` 服务，并用 1 到 5 个黑色图标显示评级信息。
    * v3 版本调用 `ratings` 服务，并用 1 到 5 个红色图标显示评级信息。

    这里需要设置一个到某版本的缺省路由，否则当发送请求到 `reviews` 服务的时候，Istio 会随机路由到某个版本，有时候显示评级图标，有时不显示。

1. 将所有服务的默认版本设置为 v1。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

## 速率限制

此任务中会根据客户的 IP 地址，针对对目标为 `productpage` 的流量配置 Istio 的速率限制。这里使用 `X-Forwarded-For` 请求 Header 作为客户端 IP 地址。此外还会针对用户的登录情况进行有条件的速率限制。

为方便起见，可以使用 [`memquota`](/zh/docs/reference/config/policy-and-telemetry/adapters/memquota/) 适配器完成速率限制。但是在生产系统上就需要提供 [`Redis`](http://redis.io/) 服务，然后配置 [`redisquota`](/docs/reference/config/policy-and-telemetry/adapters/redisquota/) 适配器。 `memquota` 和 `redisquota` 适配器都支持 [quota template](/docs/reference/config/policy-and-telemetry/templates/quota/)，因此，在两个适配器上启用速率限制的配置是相同的。

1. 速率限制配置分为两部分。
    * 客户端
        * `QuotaSpec` 定义客户端应该请求的配额名称和大小。
        * `QuotaSpecBinding` 有条件地将 `QuotaSpec` 与一个或多个服务相关联。
    * Mixer 端
        * `quota instance` 定义了 Mixer 如何选定配额。
        * `memquota adapter` 包含了 `memquota` 适配器的具体配置。
        * `quota rule` 定义何时将配额实例分派给 `memquota` 适配器。

    运行以下命令以使用 `memquota` 启用速率限制：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml@
    {{< /text >}}

    {{< warning >}}
    如果使用的是 1.1.2 或更早的版本，请使用下列配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

    `memquota` Handler 定义了 3 个不同的速率限制模式。缺省情况下，每秒限制 500 请求。可以用 `override` 对缺省限制进行覆盖：

    * 如果 `destination` 的值是 `reviews`，则限制每 5 秒（`validDuration`）1 （`maxAmount` 字段）个请求。
    * 如果 `destination` 是 `productpage`，每 5 秒 2 个请求。

    当处理请求时，会按照自顶向下的顺序，选择第一个符合条件的 `override` 进行速率限制。

    或者

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-redis-quota-rolling-window.yaml@
    {{< /text >}}

    **注意**：根据实际情况替换 [rate_limit_algorithm](/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params-QuotaAlgorithm) 和
    [redis_server_url](/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params) 的值。

    `redisquota` Handler 定义了 4 个不同的速率限制模式。缺省限制为每秒 `500` 个请求，使用 `ROLLING_WINDOW` 算法进行配额检查，该算法的 `bucketDuration` 定义为 500 毫秒。还定义了三个 `override`：

    * 如果 `destination` 的值是 `reviews`，`maxAmount` 设置为 `1`。
    * 如果 `destination` 的值是为 `productpage`，并且来源 IP 为 `10.28.11.20`，上限设置为 `500`。
    * 如果 `destination` 的值是为 `productpage`，则上限设置为 `2`。

    当处理请求时，会按照自顶向下的顺序，选择第一个符合条件的 `override` 进行速率限制。

1. 确认已经创建 `quota instance`：

    {{< text bash >}}
    $ kubectl -n istio-system get instance requestcountquota -o yaml
    {{< /text >}}

    `quota` 模板定义了三个 `dimension`，在 `memquota` 或者 `redisquota` 中可以根据这些定义，对符合属性要求的请求进行覆盖。`destination` 会在 `destination.labels["app"]`、`destination.service.host` 或 `"unknown"` 中选择第一个非空值。这个表达式的具体内容可以阅读[表达式语言参考](/zh/docs/reference/config/policy-and-telemetry/expression-language/)。

1. 确认 `quota rule` 已经创建：

    {{< text bash >}}
    $ kubectl -n istio-system get rule quota -o yaml
    {{< /text >}}

    `rule` 告诉 Mixer，调用 `memquota` 或者 `redisquota` Handler，并使用上面创建的 `requestcountquota` Instance 生成对象传递给 Handler。这个步骤会使用 `quota` 模板对`dimension` 进行映射。

1. 确认 `QuotaSpec` 已经创建：

    {{< text bash >}}
    $ kubectl -n istio-system get QuotaSpec request-count -o yaml
    {{< /text >}}

    `QuotaSpec` 中声明，上面定义的 `requestcountquota` 的消耗倍数为 `1`。

1. 确认 `QuotaSpecBinding` 已经创建：

    {{< text bash >}}
    $ kubectl -n istio-system get QuotaSpecBinding request-count -o yaml
    {{< /text >}}

    `QuotaSpecBinding` 把前面的 `QuotaSpec` 绑定到需要应用限流的服务上。`productpage` 被显式的绑定到了 `request-count` 上。因为 `QuotaSpecBinding` 所属命名空间和这些服务是不一致的，所以这里必须定义每个服务的 `namespace`。如果去掉最后一行的注释标志，`service: '*'` 会把所有的服务绑定到 `QuotaSpec` 上，第一行就无效了。

1. 在浏览器中刷新 `productpage` 页面。

    `request-count` 配额适用于 `productpage` ，每 5 秒允许 2 个请求。如果你不断刷新页面，你会看到 `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`。

## 有条件的速率限制

在上面的例子里，我们有效的把 `productpage` 的速率限制为每客户端 IP `2 rps`。如果我们想要放弃对已登录用户的速率限制。在 `bookinfo` 的例子中，我们使用 `session=<sessionid>` Cookie 来标识已登录用户。在真实场景中，可能会使用 `JWT` token 来完成这一目的。

可以为 `quota rule` 添加一个基于 `cookie` 的匹配条件：

{{< text syntax="bash" outputis="yaml" >}}
$ kubectl -n istio-system edit rules quota
...
  match: match(request.headers["cookie"], "session=*") == false
...
{{< /text >}}

`memquota` 或者 `redisquota` 适配器仅在  `session=<sessionid>` Cookie 不存在的情况下才会调用。这样一来，已登录用户就不受限制了。

1. 已登录用户不受速率限制。

    用 `jason` 的身份登录，重复刷新 `productpage`。应该不会出现任何问题。

1. 未登录用户**受到**速率限制。

    从 `jason` 的身份登出，重复刷新 `productpage`，会看到 `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`。

## 理解速率限制

在前面的例子中演示了 Mixer 根据条件对请求实施速率限制的过程。

每个有名称的 Quota 实例，例如前面的 `requestcount`，都代表了一套计数器。这一个集合就是所有 Quota dimensions 的笛卡尔积定义的。如果上一个 `expiration` 区间内的请求数量超过了 `maxAmount`，Mixer 就会返回 `RESOURCE_EXHAUSTED` 信息给 Proxy。Proxy 则返回 `HTTP 429` 给调用方。

`memquota` 适配器使用一个为亚秒级分辨率的滑动窗口来实现速率限制。

`redisquota` 适配器能够通过配置来选择使用 [`ROLLING_WINDOW` 或者 `FIXED_WINDOW`](/docs/reference/config/policy-and-telemetry/adapters/redisquota/#Params-QuotaAlgorithm) 算法来进行速率限制。

适配器配置中的 `maxAmount` 设置了关联到 Quota 实例中的所有计数器的缺省限制。如果所有 `override` 条目都无法匹配到一个请求，就只能使用 `maxAmount` 限制了。`memquota/redisquota` 会选择适合请求的第一条 `override`。`override` 条目无需定义所有 quota dimension，例如例子中的 `0.2 qps` 条目在 4 条 quota dimensions 中只选用了三条。

如果要把上面的策略应用到某个命名空间而非整个 Istio 网格，可以把所有 `istio-system` 替换成为给定的命名空间。

## 清理

1. 如果使用 `memquota` ，删除 `memquota` 速率限制相关的配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml@
    {{< /text >}}

    如果使用的是 Istio 1.1.2 或更早的版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit-crd.yaml@
    {{< /text >}}

    或者

    如果使用 `redisquota` ，删除 `redisquota` 速率限制相关的配置：

    {{< text bash >}}
    $ kubectl delete -f redisquota.yaml
    {{< /text >}}

1. 删除应用路由规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果不准备尝试后续任务，可参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)的介绍关停应用。
