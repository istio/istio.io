---
title: 启用速率限制
description: 这一任务展示了如何使用 Istio 动态的对服务通信进行速率限制。
weight: 10
keywords: [policies,quotas]
aliases:
    - /docs/tasks/rate-limiting.html
---

这一任务展示了如何使用 Istio 动态的对服务通信进行速率限制。

## 开始之前

1. 按照[安装指南](/zh/docs/setup/kubernetes/quick-start/)在 Kubernetes 集群上设置 Istio。

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用。

    Bookinfo 例子中需要部署三个版本的 `reviews` 服务：

    * v1 版本不会调用 `ratings` 服务。
    * v2 版本调用 `ratings` 服务，并用 1 到 5 个黑色图标显示评级信息。
    * v3 版本调用 `ratings` 服务，并用 1 到 5 个红色图标显示评级信息。

    这里需要设置一个到某版本的缺省路由，否则当发送请求到 `reviews` 服务的时候，Istio 会随机路由到某个版本，有时候显示评级图标，有时不显示。

1. 把每个服务的缺省路由设置到 v1 版本，如果已经给示例应用创建了路由规则，那么下面的命令中应该使用 `replace` 而不是 `create`。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 为 `reviews` 服务编写基于应用版本的路由，将来自 "jason" 用户的请求发送到版本 "v2"，其他请求发送到版本 "v3"。

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

## 速率限制

Istio 允许用户对服务进行限流。

假设 `ratings` 是一个像 `Rotten Tomatoes®` 这样的付费的外部服务，但是他提供了 `1 qps` 的免费额度可以使用。下面我们尝试使用 Istio 来确保只使用这免费的 `1 qps`。

1. 用浏览器打开 Bookinfo 的 `productpage` 页面（`http://$GATEWAY_URL/productpage`）。

    如果用 "jason" 的身份登录，应该能看到黑色评级图标，这说明 `ratings` 服务正在被 `reviews:v2` 服务调用。

    如果用其他身份登录，就会看到红色的评级图标，这表明调用 `ratings` 服务的是 `reviews:v3` 服务。

1. 为实现速率限制，需要配置 `memquota`、`quota`、`rule`、`QuotaSpec` 以及 `QuotaSpecBinding` 五个对象：

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml@
    {{< /text >}}

1. 检查 `memquota` 的创建情况：

    {{< text bash yaml >}}
    $ kubectl -n istio-system get memquota handler -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: memquota
    metadata:
      name: handler
      namespace: istio-system
    spec:
      quotas:
      - name: requestcount.quota.istio-system
        maxAmount: 5000
        validDuration: 1s
        overrides:
        - dimensions:
            destination: ratings
            source: reviews
            sourceVersion: v3
          maxAmount: 1
          validDuration: 5s
        - dimensions:
            destination: ratings
          maxAmount: 5
          validDuration: 10s
    {{< /text >}}

    `memquota` 定义了三个不同的速率限制。在没有 `overrides` 生效的缺省情况下，每秒限制 5000 请求、另外还定义了两个 `overrides` 条目。如果 `destination` 的值为 `ratings`，来源为 `reviews` 并且 `sourceVersion` 是 `v3`，限制值为每 5 秒 1 次；如果 `destination` 是 `ratings`；第二条 `overrides` 条目的条件是 `destinatin` 等于 `ratings` 的时候限制为每 10 秒 5 个请求。Istio 会选择第一条符合条件的 `overrides`（读取顺序为从上到下）应用到请求上。

1. 确认 `quota` 的创建情况。

    {{< text bash yaml >}}
    $ kubectl -n istio-system get quotas requestcount -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: quota
    metadata:
      name: requestcount
      namespace: istio-system
    spec:
      dimensions:
        source: source.labels["app"] | source.service | "unknown"
        sourceVersion: source.labels["version"] | "unknown"
        destination: destination.labels["app"] | destination.service | "unknown"
        destinationVersion: destination.labels["version"] | "unknown"
    {{< /text >}}

    `quota` 模板为 `memquota` 定义了 4 个 `demensions` 条目，用于在符合条件的请求上设置 `overrides`。`destination` 会被设置为 `destination.labels["app"]` 中的第一个非空的值。可以在[表达式语言文档](/docs/reference/config/policy-and-telemetry/expression-language/)中获取更多表达式方面的内容。

1. 确认 `rule` 的创建情况：

    {{< text bash yaml >}}
    $ kubectl -n istio-system get rules quota -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: rule
    metadata:
      name: quota
      namespace: istio-system
    spec:
      actions:
      - handler: handler.memquota
        instances:
        - requestcount.quota
    {{< /text >}}

    `rule` 通知 Mixer，使用 Instance `requestcount.quota` 构建对象并传递给上面创建的 `handler.memquota`。这一过程使用 `quota` 模板将 `dimensions` 数据映射给 `memquota` 进行处理。

1. 确认 `QuotaSpec` 的创建情况：

    {{< text bash yaml >}}
    $ kubectl -n istio-system get QuotaSpec request-count -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: QuotaSpec
    metadata:
      name: request-count
      namespace: istio-system
    spec:
      rules:
      - quotas:
        - charge: "1"
          quota: requestcount
    {{< /text >}}

    `QuotaSpec` 为上面创建的 `quota` 实例（`requstcount`）设置了 `charge` 值为 1。

1. 确认 `QuotaSpecBinding` 的创建情况：

    {{< text bash yaml >}}
    $ kubectl -n istio-system get QuotaSpecBinding request-count -o yaml
    kind: QuotaSpecBinding
    metadata:
      name: request-count
      namespace: istio-system
    spec:
      quotaSpecs:
      - name: request-count
        namespace: istio-system
      services:
      - name: ratings
        namespace: default
      - name: reviews
        namespace: default
      - name: details
        namespace: default
      - name: productpage
        namespace: default
    {{< /text >}}

    `QuotaSpecBinding` 把前面的 `QuotaSpec` 绑定到需要应用限流的服务上。因为 `QuotaSpecBinding` 所属命名空间和这些服务是不一致的，所以这里必须定义每个服务的 `namespace`。

1. 在浏览器中刷新 `productpage` 页面。

    如果处于登出状态，`reviews-v3` 服务的限制是每 5 秒 1 次请求。持续刷新页面，会发现每 5 秒钟评级图标只会显示大概 1 次。

    如果使用 "jason" 登录，`reviews-v2` 服务的速率限制是每 10 秒钟 5 次请求。如果持续刷新页面，会发现 10 秒钟之内，评级图标大概只会显示 5 次。

    所有其他的服务则会适用于 5000 qps 的缺省速率限制。

## 有条件的速率限制

在前面的例子中，`ratings` 服务受到的速率限制并没有考虑没有 `dimension` 属性的情况。还可以在配额规则中使用任意属性进行匹配，从而完成有条件的配额限制。

例如下面的配置：

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: quota
  namespace: istio-system
spec:
  match: source.namespace != destination.namespace
  actions:
  - handler: handler.memquota
    instances:
    - requestcount.quota
{{< /text >}}

如果一个请求的源服务和目的服务处于不同的命名空间，这个配额限制就会生效。

## 理解速率限制

在前面的例子中演示了 Mixer 根据条件对请求实施速率限制的过程。

每个有名称的 Quota 实例，例如前面的 `requestcount`，都代表了一套计数器。这一个集合就是所有 Quota dimensions 的笛卡尔积定义的。如果上一个 `expiration` 区间内的请求数量超过了 `maxAmount`，Mixer 就会返回 `RESOURCE_EXHAUSTED` 信息给 Proxy。Proxy 则返回 `HTTP 429` 给调用方。

`memquota` 适配器使用一个为亚秒级分辨率的滑动窗口来实现速率限制。

适配器配置中的 `maxAmount` 设置了关联到 Quota 实例中的所有计数器的缺省限制。如果所有 `overrides` 条目都无法匹配到一个请求，就只能使用 `maxAmount` 限制了。Memquota 会选择适合请求的第一条 `override`。`override` 条目无需定义所有 quota dimension， 例如例子中的 `0.2 qps` 条目在 4 条 quota dimensions 中只选用了三条。

如果要把上面的策略应用到某个命名空间而非整个 Istio 网格，可以把所有 istio-system 替换成为给定的命名空间。

## 清理

1. 删除速率限制配置：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/policy/mixer-rule-ratings-ratelimit.yaml@
    {{< /text >}}

1. 删除应用路由规则：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. 如果不准备尝试后续任务，可参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理) 的介绍关停应用。