---
title: 启用速率限制
description: 这一任务展示了如何使用 Istio 动态的对服务通信进行速率限制。
weight: 10
keywords: [policies,quotas]
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

1. 将所有服务的默认版本设置为 v1。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

## 速率限制

在此任务中，您将 Istio 配置为根据 IP 地址将流量限制到访问 `productpage` 的用户。您将使用 `X-Forwarded-For` 请求 http header 作为客户端 IP 地址。您还将使用免除登录用户的条件速率限制。

为方便起见，您可以配置 [memquota](/zh/docs/reference/config/policy-and-telemetry/adapters/memquota/) 适配器启用速率限制。但是，在生产系统上，你需要 [`Redis`](http://redis.io/) ，然后配置 [`redisquota`](/zh/docs/reference/config/policy-and-telemetry/adapters/redisquota/) 适配器。 `memquota` 和 `redisquota` 适配器都支持 [quota template](/zh/docs/reference/config/policy-and-telemetry/templates/quota/)，因此，在两个适配器上启用速率限制的配置是相同的。

1. 速率限制配置分为两部分。
    * 客户端
        * `QuotaSpec` 定义客户端应该请求的配额名称和大小。
        * `QuotaSpecBinding` 有条件地将 `QuotaSpec` 与一个或多个服务相关联。
    * Mixer 端
        * `quota instance` 定义了 Mixer 如何确定配额的大小。
        * `memquota adapter` 定义了 memquota 适配器配置。
        * `quota rule` 定义何时将配额实例分派给 memquota 适配器。

    运行以下命令以使用 memquota 启用速率限制：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml@
    {{< /text >}}

    或者

    将以下 yaml 文件另存为 `redisquota.yaml` 。替换 [rate_limit_algorithm](/zh/docs/reference/config/policy-and-telemetry/adapters/redisquota/#quotaalgorithm)，
[`redis_server_url`](/zh/docs/reference/config/policy-and-telemetry/adapters/redisquota/#参数)包含配置值。

    {{< text yaml >}}
    apiVersion: "config.istio.io/v1alpha2"
    kind: redisquota
    metadata:
      name: handler
      namespace: istio-system
    spec:
      redisServiceUrl: <redis_server_url>
      connectionPoolSize: 10
      quotas:
      - name: requestcount.quota.istio-system
        maxAmount: 500
        validDuration: 1s
        bucketDuration: 500ms
        rateLimitAlgorithm: <rate_limit_algorithm>
        # The first matching override is applied.
        # A requestcount instance is checked against override dimensions.
        overrides:
        # The following override applies to 'reviews' regardless
        # of the source.
        - dimensions:
            destination: reviews
          maxAmount: 1
        # The following override applies to 'productpage' when
        # the source is a specific ip address.
        - dimensions:
            destination: productpage
            source: "10.28.11.20"
          maxAmount: 500
        # The following override applies to 'productpage' regardless
        # of the source.
        - dimensions:
            destination: productpage
          maxAmount: 2
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: quota
    metadata:
      name: requestcount
      namespace: istio-system
    spec:
      dimensions:
        source: request.headers["x-forwarded-for"] | "unknown"
        destination: destination.labels["app"] | destination.workload.name | "unknown"
        destinationVersion: destination.labels["version"] | "unknown"
    ---
    apiVersion: config.istio.io/v1alpha2
    kind: rule
    metadata:
      name: quota
      namespace: istio-system
    spec:
      # quota only applies if you are not logged in.
      # match: match(request.headers["cookie"], "user=*") == false
      actions:
      - handler: handler.redisquota
        instances:
        - requestcount.quota
    ---
    apiVersion: config.istio.io/v1alpha2
    kind: QuotaSpec
    metadata:
      name: request-count
      namespace: istio-system
    spec:
      rules:
      - quotas:
        - charge: 1
          quota: requestcount
    ---
    apiVersion: config.istio.io/v1alpha2
    kind: QuotaSpecBinding
    metadata:
      name: request-count
      namespace: istio-system
    spec:
      quotaSpecs:
      - name: request-count
        namespace: istio-system
      services:
      - name: productpage
        namespace: default
        #  - service: '*'  # Uncomment this to bind *all* services to request-count
    ---
    {{< /text >}}

    运行以下命令以使用 redisquota 启用速率限制：

    {{< text bash >}}
    $ kubectl apply -f redisquota.yaml
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
        maxAmount: 500
        validDuration: 1s
        overrides:
        - dimensions:
            destination: reviews
          maxAmount: 1
          validDuration: 5s
        - dimensions:
            destination: productpage
          maxAmount: 2
          validDuration: 5s
    {{< /text >}}

    `memquota` 处理程序定义了 3 种不同的速率限制方案。在没有 `overrides` 生效的缺省情况下，每秒限制请求为 `500` 次。还定义了两个 `overrides` 条目：

    * 如果 `destination` 值为 `reviews` ，限制值为每 5 秒 1 次。
    * 如果 `destination` 值为 `productpage` ，限制值为每 5 秒 2 次。

    处理请求时，Istio 会选择第一条符合条件的 `overrides`（读取顺序为从上到下）应用到请求上。

    或者

    确认已创建 `redisquota` handler ：

    {{< text bash yaml >}}
    $ kubectl -n istio-system get redisquota handler -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: redisquota
    metadata:
      name: handler
      namespace: istio-system
    spec:
      connectionPoolSize: 10
      quotas:
      - name: requestcount.quota.istio-system
        maxAmount: 500
        validDuration: 1s
        bucketDuration: 500ms
        rateLimitAlgorithm: ROLLING_WINDOW
        overrides:
        - dimensions:
            destination: reviews
          maxAmount: 1
        - dimensions:
            destination: productpage
            source: 10.28.11.20
          maxAmount: 500
        - dimensions:
            destination: productpage
          maxAmount: 2
    {{< /text >}}

    `redisquota` handler 定义了 4 种不同的速率限制方案。在没有 `overrides` 生效的缺省情况下，每秒限制请求为 `500`次。它使用 `ROLLING_WINDOW` 算法进行配额检查，因此为 `ROLLING_WINDOW` 算法定义了 500ms 的 `bucketDuration`。还定义了 `overrides` 条目：

    * 如果 `destination` 的值为 `reviews`是 那么最大请求配额为 `1`。
    * 如果 `destination` 的值为 `productpage` 并且来源是 `10.28.11.20` 那么最大请求配额为 `500`，
    * 如果 `destination` 的值为 `productpage` 那么最大请求配额为 `2`。

    处理请求时，Istio 会选择第一条符合条件的 `overrides`（读取顺序为从上到下）应用到请求上。

    确认 `quota instance` 的创建情况：

    {{< text bash yaml >}}
    $ kubectl -n istio-system get quotas requestcount -o yaml
    apiVersion: config.istio.io/v1alpha2
    kind: quota
    metadata:
      name: requestcount
      namespace: istio-system
    spec:
      dimensions:
        source: request.headers["x-forwarded-for"] | "unknown"
        destination: destination.labels["app"] | destination.service.host | "unknown"
        destinationVersion: destination.labels["version"] | "unknown"
    {{< /text >}}

    `quota` 模板定义了 `memquota` 或 `redisquota` 使用的三个维度，用于设置匹配某些属性的请求。 `destination` 将被设置为 `destination.labels["app"]`、`destination.service.host` 或 `"unknown"` 中的第一个非空值。有关表达式的更多信息，请参阅[表达式语言文档](/zh/docs/reference/config/policy-and-telemetry/expression-language/)中获取更多表达式方面的内容。

1. 确认 `quota rule` 的创建情况：

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
      - name: productpage
        namespace: default
      # - service: '*'
    {{< /text >}}

    `QuotaSpecBinding` 把前面的 `QuotaSpec` 绑定到需要应用限流的服务上。因为 `QuotaSpecBinding` 所属命名空间和这些服务是不一致的，所以这里必须定义每个服务的 `namespace`。

1. 在浏览器中刷新 `productpage` 页面。

    `request-count` 配额适用于 `productpage` ，每 5 秒允许 2 个请求。如果你不断刷新页面，你会看到 `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount`。

## 有条件的速率限制

在前面的例子中，`ratings` 服务受到的速率限制并没有考虑没有 `dimension` 属性的情况。还可以在配额规则中使用任意属性进行匹配，从而完成有条件的配额限制。

例如下面的配置：

{{< text yaml >}}
$ kubectl -n istio-system edit rules quota

apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: quota
  namespace: istio-system
spec:
  match: match(request.headers["cookie"], "user=*") == false
  actions:
  - handler: handler.memquota
    instances:
    - requestcount.quota
{{< /text >}}

只有当请求中没有 `user = <username>` cookie 时，才会调度 `memquota` 或 `redisquota` 适配器。
这可确保登录用户不受此配额的约束。

1. 验证速率限制不适用于登录用户。

    以 `jason` 身份登录并反复刷新 `productpage`。现在你应该能够毫无问题地做到这一点。

1. 验证速率限制在未登录时*适用*。

    注销 `jason` 并反复刷新 `productpage` 。

    您应该再次看到 `RESOURCE_EXHAUSTED:Quota is exhausted for: requestcount` 。

## 理解速率限制

在前面的例子中演示了 Mixer 根据条件对请求实施速率限制的过程。

每个有名称的 Quota 实例，例如前面的 `requestcount`，都代表了一套计数器。这一个集合就是所有 Quota dimensions 的笛卡尔积定义的。如果上一个 `expiration` 区间内的请求数量超过了 `maxAmount`，Mixer 就会返回 `RESOURCE_EXHAUSTED` 信息给 Proxy。Proxy 则返回 `HTTP 429` 给调用方。

`memquota` 适配器使用一个为亚秒级分辨率的滑动窗口来实现速率限制。

适配器配置中的 `maxAmount` 设置了关联到 Quota 实例中的所有计数器的缺省限制。如果所有 `overrides` 条目都无法匹配到一个请求，就只能使用 `maxAmount` 限制了。Memquota 会选择适合请求的第一条 `override`。`override` 条目无需定义所有 quota dimension， 例如例子中的 `0.2 qps` 条目在 4 条 quota dimensions 中只选用了三条。

如果要把上面的策略应用到某个命名空间而非整个 Istio 网格，可以把所有 `istio-system` 替换成为给定的命名空间。

## 清理

1. 如果使用 `memquota` ，删除 `memquota` 速率限制相关的配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml@
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

1. 如果不准备尝试后续任务，可参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理) 的介绍关停应用。
