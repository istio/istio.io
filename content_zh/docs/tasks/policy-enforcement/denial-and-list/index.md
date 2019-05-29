---
title: Denier 适配器以及黑白名单
description: 展示使用简单的 Denier 适配器或黑白名单对服务进行访问控制的方法。
weight: 20
keywords: [policies,denial,whitelist,blacklist]
---

本文任务展示了使用简单的 Denier 适配器，基于属性的黑白名单或者基于 IP 的黑白名单对服务进行访问控制的方法

## 开始之前

* 按照[安装指南](/zh/docs/setup/kubernetes/)在 Kubernetes 集群上部署 Istio。

    {{< warning >}}
    必须在群集中为此任务启用策略实施。
    按照[启用策略](/docs/tasks/policy-enforcement/enabling-policy/)强制执行中的步骤操作，确保已启用策略实施。
    {{< /warning >}}

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用。

* 初始化版本路由，对目标为 `reviews` 服务的请求，来自用户 "jason" 的请求分配给 `v2` 版本，其他用户的请求分配到 `v3` 版本。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

    然后运行如下命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

    {{< tip >}}
    如果使用的命名空间不是 `default`，就需要用 `kubectl -n namespace ...` 来指定命名空间。
    {{< /tip >}}

## 简单的 Denier 适配器

在 Istio 环境里，可以使用 Mixer 中的任何属性来对服务进行访问控制。这是一种简易的访问控制，使用 Mixer 选择器来有条件的拒绝请求。

比如 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用中 `ratings` 服务会被多个版本的 `reviews` 服务访问。我们尝试切断来自 `reviews:v3` 的访问。

1. 用浏览器打开 Bookinfo 的 `productpage`（`http://$GATEWAY_URL/productpage`）。

    如果用 "jason" 的身份登录，就应该能看到每条 Review 都伴随着黑色的星形图标，这表明 `ratings` 服务是被 `reviews` 服务的 `v2` 版本调用的。

    但如果使用其他用户登录（或者未登录），就会看到伴随 Review 的是红色的星星图标，这种情况下 `ratings` 服务是被 `reviews` 服务的 `v3` 版本调用的。

1. 显式拒绝 `reviews:v3` 服务的调用。

    运行下列命令设置一条拒绝规则，其中包含了一个 `handler` 以及一个 `instance`。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更早版本，请使用以下配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-label-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

    请注意 `denyreviewsv3` 规则中的以下内容：

    {{< text plain >}}
    match: destination.labels["app"] == "ratings" && source.labels["app"]=="reviews" && source.labels["version"] == "v3"
    {{< /text >}}

    这段表达式匹配的条件是，来自服务 `reviews`，`version` 标签值为 `v3` 的，目标为 `ratings` 服务的请求。

    这条规则使用 `denier` 适配器拒绝来自 `reviews:v3` 服务的请求。这个适配器会使用预定的状态码和消息拒绝请求。状态码和消息的定义可以参考 [Denier](/zh/docs/reference/config/policy-and-telemetry/adapters/denier/) 适配器的配置文档。

1. 在浏览器中刷新 `productpage` 页面。

    如果已经登出或者使用不是 "jason" 的用户身份登录，就无法看到评级图标了，这是因为 `reviews:v3` 服务对 `ratings` 服务的访问已经被拒绝了。反之，如果使用 "jason" 用户登录，因为这一用户使用的是 `reviews:v2` 的服务，不符合拒绝条件，所以还是能够看到黑色的星形图标。

## 基于属性的 _whitelists_ 或者 _blacklists_

Istio 支持基于属性的黑名单和白名单。下面的白名单配置和前面的 `Denier` 配置是等价的——拒绝来自 `reviews:v3` 的请求。

1.  删除前文配置的 Denier 规则。

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

    如果您使用的是 Istio 1.1.2 或更早版本，请使用以下配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-label-crd.yaml@
    {{< /text >}}

1.  校验，在没有登录的情况下访问 Bookinfo 的 `productpage`（`http://$GATEWAY_URL/productpage`），应该是看不到星形图标的；如果使用 "jason" 用户登录，则应该看到黑星图标。

1.  应用白名单版本 `v1，v2` 的 [`list`](/docs/reference/config/policy-and-telemetry/adapters/list/)适配器的配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-whitelist.yaml@
    {{< /text >}}

    {{< warning >}}
    If you use Istio 1.1.2 or prior, please use the following configuration instead:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-whitelist-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1. 校验，在没有登录的情况下访问 Bookinfo 的 `productpage`（`http://$GATEWAY_URL/productpage`），应该是看不到星形图标的；如果使用 "jason" 用户登录，则应该看到黑星图标。

## 基于 IP 的 _whitelists_ or _blacklists_

Istio 支持基于 IP 的黑名单和白名单。你可以给 Istio 设置接受或拒绝来自特定 IP 或子网的请求。

1. 确认您可以访问到 Bookinfo 的 `productpage`  `http://$GATEWAY_URL/productpage` 。应用以下规则后，您将无法访问它。

1.  给 [list](/docs/reference/config/policy-and-telemetry/adapters/list/) 适配器创建配置，
    其中包含子网 `"10.57.0.0\16"`。
    将以下 YAML 代码段另存为 `whitelistip-handler.yaml`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-ip.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更早版本，请使用以下配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-ip-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  试着访问 Bookinfo 的 `productpage`
   `http://$GATEWAY_URL/productpage` 并验证您是否收到类似于的错误： `PERMISSION_DENIED:staticversion.istio-system:<your mesh source ip> is
   not whitelisted`

## 清理

* 删除基于属性的白名单和黑名单的 Mixer 配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-whitelist.yaml@
    {{< /text >}}

    如果您使用 Istio 1.1.2 或更早版本，请使用以下配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-whitelist-crd.yaml@
    {{< /text >}}

* 删除基于 IP 的白名单和黑名单的 Mixer 配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-ip.yaml@
    {{< /text >}}

    如果您使用 Istio 1.1.2 或更早版本，请使用以下配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-ip-crd.yaml@
    {{< /text >}}

* 移除应用路由规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

* 移除应用目标规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/destination-rule-all.yaml@
    {{< /text >}}

    如果启用了双向 TLS，则需要运行如下命令：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

* 如果没有计划尝试后续任务，参考 [Bookinfo 清理](/zh/docs/examples/bookinfo/#清理)部分的介绍，关停示例应用。
