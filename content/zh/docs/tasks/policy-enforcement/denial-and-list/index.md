---
title: Denials 和白/黑名单
description: 描述如何使用简单的 denials 或白/黑名单来控制对服务的访问。
weight: 20
keywords: [policies,denial,whitelist,blacklist]
aliases:
    - /zh/docs/tasks/basic-access-control.html
    - /zh/docs/tasks/security/basic-access-control/index.html
    - /zh/docs/tasks/security/secure-access-control/index.html
---

此任务说明了如何使用简单 denials、基于属性的白/黑名单或基于 IP 的白/黑名单来控制对服务的访问。

## 开始之前{#before-you-begin}
    
* 请按照此[安装指南](/zh/docs/setup/)中的安装说明，在 Kubernetes 上对 Istio 进行安装。

    {{< warning >}}
    对于此任务，您 **必须** 在您的集群中启用强制策略。
    参考[启用强制策略](/zh/docs/tasks/policy-enforcement/enabling-policy/)文档中的步骤来确保强制策略是启用的。
    {{< /warning >}}

* 部署此 [Bookinfo](/zh/ocs/examples/bookinfo/) 样例应用。

* 初始化直接访问`评论`服务的应用程序的版本路由请求，对于测试用户"jason"的请求直接指定到 v2 版本，同时其他用户的请求指定到 v3 版本。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

    然后执行以下命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

    {{< tip >}}
    如果您使用的 namespace 不是 `default`，使用 `kubectl -n namespace ...` 来指明该 namespace。
    {{< /tip >}}

## 简单 _denials_{#simple-denials}

通过 Istio 您可以根据 Mixer 中可用的任意属性来控制对服务的访问。
这种简单形式的访问控制是基于使用 Mixer 选择器的条件拒绝请求。

考虑此 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用，其中`评级`服务可通过`评论`服务的多个版本进行访问。
我们想切断对 `v3` 版本`评论`服务的访问。

1.  将浏览器定位到 Bookinfo `产品页面` (`http://$GATEWAY_URL/productpage`)。

    如果您以"jason"用户身份登录，则对于每个评论您都应看到黑色的星级，
    它表示`评级`服务是通过 "v2" 版本`评论`服务访问到的。
    
    如果您以其他任何用户身份登录（或登出），则对于每个评论您都应看到红色的星级，
    它表示`评级`服务是通过 "v3" 版本`评论`服务访问到的。

1.  要想明确地拒绝对 `v3` 版本`评论`服务的访问。

    连同处理程序和实例，执行以下命令来配置拒绝规则。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更早版本，请替换使用以下配置：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-label-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

    注意 `denyreviewsv3` 规则中的以下部分：

    {{< text plain >}}
    match: destination.labels["app"] == "ratings" && source.labels["app"]=="reviews" && source.labels["version"] == "v3"
    {{< /text >}}

    它将带有 `v3` 标签的`评论`工作负载请求与`评级`工作负载进行匹配。
    
    该规则通过使用 `denier` 适配器来拒绝 `v3` 版本评论服务的请求。
    适配器始终拒绝带有预配置状态码和消息的请求。
    状态码和消息在 [denier](/zh/docs/reference/config/policy-and-telemetry/adapters/denier/) 适配器配置中指定。

1.  在您的浏览器里刷新 `产品页面`。
    
    如果您已登出或以非"json"用户登录，因为`v3 评论` 服务已经被拒绝访问`评级`服务，所以您不会再看到红色星级。
    相反，如果您以"json"用户（`v2 评论服务` 用户）登录，您能一直看到黑色星级。

## 基于属性的 _白名单_ 或 _黑名单_{#attribute-based-whitelists-or-blacklists}

Istio 支持基于属性的白名单和黑名单。
以下白名单配置等同于上一节的 `denier` 配置。
此规则能有效地拒绝 `v3` 版本`评论`服务的请求。

1.  移除上一节您新增的 denier 配置。

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

    如果您正在使用 Istio 1.1.2 或更早版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-label-crd.yaml@
    {{< /text >}}

1.  当您不做登录去访问 Bookinfo `产品页面` (`http://$GATEWAY_URL/productpage`) 时进行验证，您会看到红星。
    再执行以下步骤之后，除非您以"json"用户登录，否则您不会看到星级。

1.  将配置应用于适配器[`列表`](/zh/docs/reference/config/policy-and-telemetry/adapters/list/)以让 `v1， v2` 版本位于白名单中；

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-whitelist.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更早版本，请替换使用以下命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-whitelist-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1. 当您不做登录去访问 Bookinfo `生产页面` (`http://$GATEWAY_URL/productpage`) 时进行验证，您**不会**看到星级。
以"jason"用户登录后验证，您会看到黑色星级。

## 基于 IP 的 _白名单_ 或 _黑名单_

Istio 支持基于 IP 地址的 _白名单_ 和 _黑名单_ 。
您可以配置 Istio 接受或拒绝从一个 IP 地址或一个子网发出的请求。

1. 验证您可以访问位于 `http://$GATEWAY_URL/productpage` 的 Bookinfo `产品页面`。
   一旦应用以下规则，您将无法访问它。

1.  将配置应用于适配器[`列表`](/zh/docs/reference/config/policy-and-telemetry/adapters/list/)以让位于 ingress 网关的子网 `"10.57.0.0\16"` 位于白名单中：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-ip.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您使用 Istio 1.1.2 或更早版本，请替换使用以下命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/policy/mixer-rule-deny-ip-crd.yaml@
    {{< /text >}}

    {{< /warning >}}

1.  尝试访问位于 `http://$GATEWAY_URL/productpage` 的 Bookinfo `产品页面`进行验证，
    您会获得一个类似的错误：`PERMISSION_DENIED:staticversion.istio-system:<your mesh source ip> is not whitelisted`

## 清除{#cleanup}

* 对于简单 denials，移除 Mixer 配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-label.yaml@
    {{< /text >}}

* 对于基于属性的白黑名单，移除 Mixer 配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-whitelist.yaml@
    {{< /text >}}

    如果您使用 Istio 1.1.2 或更早版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-whitelist-crd.yaml@
    {{< /text >}}

* 对于基于 IP 的白黑名单，移除 Mixer 配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-ip.yaml@
    {{< /text >}}

    如果您使用 Istio 1.1.2 或更早版本：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/policy/mixer-rule-deny-ip-crd.yaml@
    {{< /text >}}

* 移除应用程序路由规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-reviews-jason-v2-v3.yaml@
    {{< /text >}}

* 如果您不打算探索任何后续任务，请参考[清除 Bookinfo](/zh/docs/examples/bookinfo/#cleanup) 说明指南来关闭应用程序。 