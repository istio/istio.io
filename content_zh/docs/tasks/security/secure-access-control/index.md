---
title: 安全访问控制
description: 如何使用 Service Account 进行安全的访问控制。
weight: 30
keywords: [security,access-control]
---

Istio 认证功能可以借用 Service account 来对服务的访问进行安全的访问控制。本文任务将演示这一特性。

启用 Istio 的双向 TLS 认证之后，服务器会根据客户端的证书对其进行认证，并且会从证书中提取他的 Service account。Service account 会保存在 `source.user` 属性之中。

可以参考 [Istio 身份认证](/docs/concepts/security/#identity) 一节，了解 Service account 在 Istio 中的表达格式。

## 开始之前

* 根据[快速开始](/docs/setup/kubernetes/quick-start/)所说步骤，在启用了认证的 Kubernetes 集群上设置 Istio。

    注意应该在[安装过程的第五步](/docs/setup/kubernetes/quick-start/#installation-steps)启用认证过程。

* 部署 [Bookinfo](/docs/examples/bookinfo/) 示例应用程序。

* 运行如下命令，创建 Service account `bookinfo-productpage`，并且使用新建的 Service account 重新部署 `productpage` 服务。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml@)
    serviceaccount "bookinfo-productpage" created
    deployment.extensions "productpage-v1" configured
    serviceaccount "bookinfo-reviews" created
    deployment.extensions "reviews-v2" configured
    deployment.extensions "reviews-v3" configured
    {{< /text >}}

> 如果你在使用 `default` 以外的命名空间，就需要使用 `$ istioctl -n namespace ...` 来指定命名空间了。

## 用 _denials_ 进行访问控制

在 [Bookinfo](/docs/examples/bookinfo/) 示例应用中，`productpage` 服务会访问 `reviews` 以及 `details` 两个服务。我们想要 `details` 服务拒绝来自 `productpage` 服务的请求。

1. 用浏览器打开 Bookinfo 的 `productpage`(`http://$GATEWAY_URL/productpage`) 页面。

    应该会看到页面左下角的 "Book Details" 内容，其中包含了类型、页数、出版商等相关内容。`productpage` 服务需要从 `details` 服务中获取这些信息。

1. 显式的拒绝从 `prodcutpage` 到 `details` 的请求。

    运行下列命令，创建一个 Handler 以及 Instance，设置拒绝规则。

    {{< text bash >}}
    $ istioctl create -f @samples/bookinfo/policy/mixer-rule-deny-serviceaccount.yaml@
    Created config denier/default/denyproductpagehandler at revision 2877836
    Created config checknothing/default/denyproductpagerequest at revision 2877837
    Created config rule/default/denyproductpage at revision 2877838
    {{< /text >}}

    注意下面的 `denyproductpage` 规则：

    {{< text plain >}}
    match: destination.labels["app"] == "details" && source.user == "cluster.local/ns/default/sa/bookinfo-productpage"
    {{< /text >}}

    上面的一段表达式会匹配来自 `details` 服务并且 Service account 是 `cluster.local/ns/default/sa/bookinfo-productpage` 的请求。

    > 如果使用的不是 `default` 命名空间，那么就需要将 `source.user` 中的 `default` 替换为实际使用的命名空间名称。

    这个适配器会使用预先配置的状态码和返回消息来拒绝请求。状态码和消息在 [Denier 适配器](/docs/reference/config/policy-and-telemetry/adapters/denier/)中进行配置。

1. 在浏览器中刷新 `productpage`。

    会在左下角看到如下信息：

    "_Error fetching product details! Sorry, product details are currently unavailable for this book._"

    这说明从 `productpage` 到 `details` 的访问被拒绝了。

## 清理

* 删除 Mixer 配置：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/policy/mixer-rule-deny-serviceaccount.yaml@
    {{< /text >}}

* 如果不准备尝试后续任务，参考 [Bookinfo 的清理](/docs/examples/bookinfo/#cleanup) 关闭应用。
