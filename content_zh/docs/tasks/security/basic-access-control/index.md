---
title: 基本访问控制
description: 展示如何使用 Kubernetes 标签来控制到一个服务的访问。
weight: 20
keywords: [security,access-control]
aliases:
    - /docs/tasks/basic-access-control.html
---

本文任务用于展示如何使用 Kubernetes 标签来控制到一个服务的访问。

## 开始之前

* 根据[安装指南](/docs/setup/kubernetes/)的介绍在 Kubernetes 上部署 Istio。
* 部署 [Bookinfo](/docs/examples/bookinfo/) 示例应用。
* 对应用中 `reviews` 服务的路由进行初始化，用户 "jason" 的请求会路由到 `v2`，而其他用户的请求会路由到 `v3`。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

    接下来运行下列命令：

    {{< text bash >}}
    $ istioctl replace -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

    > 如果在前面的任务重设置了重名的规则，这里应该使用 `istioctl replace` 代替 `istioctl create`。
    > 如果用的不是 `default` 命名空间，就需要使用 `istioctl -n namespace ...` 来根据实际情况指定命名空间。

## 使用 _denials_ 进行访问控制

在 Istio 中可以使用 Mixer 中所有可用属性对服务进行访问控制。访问控制的一种简单方式就是使用 Mixer 选择器进行有条件的拒绝请求。

[Bookinfo](/docs/examples/bookinfo/) 应用中，`ratings` 服务会被多个版本的 `reviews` 服务所访问。下面我们尝试切断来自 `reviews:v3` 的请求。

1. 使用浏览器打开 Bookinfo 的 `productpage` (http://$GATEWAY_URL/productpage) 页面。

    如果使用 "jason" 的身份登录，你会看到每个 Review 都带有黑色的星形符号，这说明 `ratings` 服务正被 `v2` 版本的 `reviews` 服务调用。

    如果使用其他任何用户登录（或者干脆登出，匿名访问），那么就会看到红色的星级符号，这就说明 `ratings` 服务正在被 `reviews` 服务的 `v3` 版本调用。

1. 显示的拒绝 `reviews` 服务 `v3` 版本的访问。

    运行下面的命令，使用 Handler 和 Instance 配置拒绝规则。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    Created config denier/default/denyreviewsv3handler at revision 2882105
    Created config checknothing/default/denyreviewsv3request at revision 2882106
    Created config rule/default/denyreviewsv3 at revision 2882107
    {{< /text >}}

    注意下面的 `denyreviewsv3` 规则：

    {{< text plain >}}
    match: destination.labels["app"] == "ratings" && source.labels["app"]=="reviews" && source.labels["version"] == "v3"
    {{< /text >}}

    这一规则所匹配的是带有 `v3` 标签的服务 `reviews` 所发起的向 `ratings` 服务的访问。

    规则中使用了 `denier` 适配器，它会把来自 `reviews` 版本 `v3` 的请求拒绝掉。

    这个适配器会使用预先配置的状态码和返回消息来拒绝请求。状态码和消息在 [Denier 适配器](/docs/reference/config/policy-and-telemetry/adapters/denier/)中进行配置。

1. 在浏览器中刷新 `productpage`.

    如果你的当前用户不是 "jason"，或者尚未登录，就无法看到评价星级，这是因为 `reviews:v3` 服务对 `ratings` 服务的访问已经被拒绝。作为对比，如果使用 "jason" 身份登录（会使用 `reviews:v2`），就能继续看到黑色的星级图标了。

## 使用 _whitelists_ 进行访问控制

Istio 还支持基于属性的白名单以及黑名单。下面的白名单配置等价于前面的 `denier` 配置。这个规则的作用就是拒绝来自 `reviews:v3` 的请求。

1. 移除上一节中加入的 denier 配置。

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

1. 在没有登录的情况下，访问 Bookinfo 的 `productpage`(http://$GATEWAY_URL/productpage) 页面，看是否能看到红色的星级图标。

    在完成后面的步骤之后，除非使用 "jason" 的身份登录，否则应该无法再看到评级图标。

1. 为 [`list`](/docs/reference/config/policy-and-telemetry/adapters/list/) 适配器创建配置，其中包含 `v1, v2` 两个版本。将下列 YAML 代码保存为 `whitelist-handler.yaml`：

    {{< text yaml >}}
    apiVersion: config.istio.io/v1alpha2
    kind: listchecker
    metadata:
      name: whitelist
    spec:
      # providerUrl: 黑白名单通常都会在外部进行维护，并使用 providerUrl 异步获取。
      overrides: ["v1", "v2"]  # `overrides` 提供了一个静态列表
      blacklist: false
    {{< /text >}}

    接下来运行如下命令：

    {{< text bash >}}
    $ istioctl create -f whitelist-handler.yaml
    {{< /text >}}

1. 创建一个 [`listentry`](/docs/reference/config/policy-and-telemetry/templates/listentry/) 模板的实例。

    保存下面的 YAML，文件命名为 `appversion-instance.yaml`:

    {{< text yaml >}}
    apiVersion: config.istio.io/v1alpha2
    kind: listentry
    metadata:
      name: appversion
    spec:
      value: source.labels["version"]
    {{< /text >}}

    然后运行如下命令：

    {{< text bash >}}
    $ istioctl create -f appversion-instance.yaml
    {{< /text >}}

1. 为 ratings 服务启用 `whitelist` 检查。

    保存下面的 YAML，文件命名为 `checkversion-rule.yaml`:

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

    然后运行如下命令：

    {{< text bash >}}
    $ istioctl create -f checkversion-rule.yaml
    {{< /text >}}

1. 在没有登录的情况下访问 Bookinfo 的 `productpage` 页面 (http://$GATEWAY_URL/productpage)，应该看不到评级图标。用 "jason" 登录之后，又会看到黑色的星级图标。

## 清理

* 移除 Mixer 配置：

    {{< text bash >}}
    $ istioctl delete -f checkversion-rule.yaml
    $ istioctl delete -f appversion-instance.yaml
    $ istioctl delete -f whitelist-handler.yaml
    {{< /text >}}

* 移除应用的路由规则：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

* 如果不准备尝试后续任务，参考 [Bookinfo 的清理](/docs/examples/bookinfo/#cleanup) 关闭应用。
