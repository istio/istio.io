---
title: Denier 适配器以及黑白名单
description: 展示使用简单的 Denier 适配器或黑白名单对服务进行访问控制的方法。
weight: 20
keywords: [策略, denial, 白名单, 黑名单]
---

本文任务展示了使用简单的 Denier 适配器或黑白名单对服务进行访问控制的方法

## 开始之前

* 按照[安装指南](/zh/docs/setup/kubernetes/)在 Kubernetes 集群上部署 Istio。
* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用。
* Bookinfo 示例中的每个微服务都包含了多个版本，所以首先要创建目标规则，为每个版本创建一个对应的服务子集。

    如果没有启用双向 TLS，运行如下命令：

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/destination-rule-all.yaml@
    {{< /text >}}

    如果启用了双向 TLS，运行：

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    可以用下面的命令显示目标规则：

    {{< text bash >}}
    $ istioctl get destinationrules -o yaml
    {{< /text >}}

    虚拟服务中引用的子集是依赖于目标规则的，因此需要等待几秒钟，让目标规则传播出去，然后再添加虚拟服务来引用这些子集。

* 初始化版本路由，对目标为 `reviews` 服务的请求，来自用户 "jason" 的请求分配给 `v2` 版本，其他请求分配到 `v3` 版本。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

    然后运行如下命令：

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

    > 如果在之前的例子中遗留下了同名规则，则应使用 `istioctl replace` 而非 `istioctl create`。如果使用的命名空间不是 `default`，就需要用 `istioctl -n namespace ...` 来指定命名空间。

## 简单的 Denier 适配器

在 Istio 环境里，可以使用 Mixer 中的任何属性来对服务进行访问控制。这是一种简易的访问控制，使用 Mixer 选择器来有条件的拒绝请求。

比如 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用中 `ratings` 服务会被多个版本的 `reviews` 服务访问。我们尝试切断来自 `reviews:v3` 的访问。

1. 用浏览器打开 Bookinfo 的 `productpage`（`http://$GATEWAY_URL/productpage`）。

    如果用 "jason" 的身份登录，就应该能看到每条 Review 都伴随着黑色的星形图标，这表明 `ratings` 服务是被 `reviews` 服务的 `v2` 版本调用的。

    但如果使用其他用户登录（或者未登录），就会看到伴随 Review 的是红色的星星图标，这种情况下 `ratings` 服务是被 `reviews` 服务的 `v3` 版本调用的。

1. 显式拒绝 `reviews:v3` 服务的调用。

    运行下列命令设置一条拒绝规则，其中包含了一个 `handler` 以及一个 `instance`。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    Created config denier/default/denyreviewsv3handler at revision 2882105
    Created config checknothing/default/denyreviewsv3request at revision 2882106
    Created config rule/default/denyreviewsv3 at revision 2882107
    {{< /text >}}

    着重关注 `denyreviewsv3` 规则中的这段内容：

    {{< text plain >}}
    match: destination.labels["app"] == "ratings" && source.labels["app"]=="reviews" && source.labels["version"] == "v3"
    {{< /text >}}

    这段表达式匹配的条件是，来自服务 `reviews`，`version` 标签值为 `v3` 的，目标为 `ratings` 服务的请求。

    这条规则使用 `denier` 适配器拒绝来自 `reviews:v3` 服务的请求。这个适配器会使用预定的状态码和消息拒绝请求。状态码和消息的定义可以参考 [Denier](/zh/docs/reference/config/policy-and-telemetry/adapters/denier/) 适配器的配置文档。

1. 在浏览器中刷新 `productpage` 页面。

    如果已经登出或者使用不是 "jason" 的用户身份登录，就无法看到评级图标了，这是因为 `reviews:v3` 服务对 `ratings` 服务的访问已经被拒绝了。反之，如果使用 "jason" 用户登录，因为这一用户使用的是 `reviews:v2` 的服务，不符合拒绝条件，所以还是能够看到黑色的星形图标。

## _whitelists_ 或者 _blacklists_

Istio 也支持基于属性的黑名单和白名单。下面的白名单配置和前面的 `Denier` 配置是等价的——拒绝来自 `reviews:v3` 的请求。

1. 删除前文配置的 Denier 规则。

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

1. 在登出状态下浏览 Bookinfo 的 `productpage`（`http://$GATEWAY_URL/productpage`），应该看到红星图标。在完成后续步骤之后，只有在使用 "jason" 的身份进行登录之后才能看到星形图标。

1. 给 [`list`](/zh/docs/reference/config/policy-and-telemetry/adapters/list/) 适配器创建配置，其中包含 `v1, v2` 两个版本。保存下面的 YAML 代码为 `whitelist-handler.yaml`：

    {{< text yaml >}}
    apiVersion: config.istio.io/v1alpha2
    kind: listchecker
    metadata:
      name: whitelist
    spec:
      # providerUrl: 通常会在外部管理列表内容，然后使用这一参数进行异步的抓取
      overrides: ["v1", "v2"]  # 用 overrides 字段提供静态内容
      blacklist: false
    {{< /text >}}

    然后运行命令：

    {{< text bash >}}
    $ istioctl create -f whitelist-handler.yaml
    {{< /text >}}

1. 创建一个 [`listentry`](/zh/docs/reference/config/policy-and-telemetry/templates/listentry/) 适配器的模板，用于解析版本标签，将下面的 YAML 代码段保存为 `appversion-instance.yaml`：

    {{< text yaml >}}
    apiVersion: config.istio.io/v1alpha2
    kind: listentry
    metadata:
      name: appversion
    spec:
      value: source.labels["version"]
    {{< /text >}}

    接下来运行命令：

    {{< text bash >}}
    $ istioctl create -f appversion-instance.yaml
    {{< /text >}}

1. 为 `ratings` 服务启用 `whitelist` 检查功能，将下面的 YAML 代码段保存为 `checkversion-rule.yaml`：

    {{< text yaml >}}
    apiVersion: config.istio.io/v1alpha2
    kind: rule
    metadata:
      name: checkversion
    spec:
      match: destination.labels["app"] == "ratings"
      actions:
      - handler: whitelist.listchecker
        instances:
        - appversion.listentry
    {{< /text >}}

    然后运行命令：

    {{< text bash >}}
    $ istioctl create -f checkversion-rule.yaml
    {{< /text >}}

1. 校验，在没有登录的情况下访问 Bookinfo 的 `productpage`（`http://$GATEWAY_URL/productpage`），应该是看不到星形图标的；如果使用 "jason" 用户登录，则应该看到黑星图标。

## 清理

* 移除 Mixer 配置：

    {{< text bash >}}
    $ istioctl delete -f checkversion-rule.yaml
    $ istioctl delete -f appversion-instance.yaml
    $ istioctl delete -f whitelist-handler.yaml
    {{< /text >}}

* 移除应用路由规则：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

* 移除应用目标规则：

    如果没启用双向 TLS，需要运行如下命令：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/destination-rule-all.yaml@
    {{< /text >}}

    如果启用了双向 TLS，则需要运行如下命令：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

* 如果没有计划尝试后续任务，参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)部分的介绍，关停示例应用。
