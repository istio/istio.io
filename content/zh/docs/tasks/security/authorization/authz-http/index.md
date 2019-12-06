---
title: HTTP 流量授权
description: 展示如何设置基于角色的 HTTP 流量访问控制。
weight: 10
keywords: [security,access-control,rbac,authorization]
aliases:
    - /zh/docs/tasks/security/role-based-access-control.html
    - /zh/docs/tasks/security/authz-http/
---

该任务向您展示了如何在 Istio 网格中为 HTTP 流量设置授权。可在[授权概念页面](/zh/docs/concepts/security/#authorization)了解更多内容。

## 开始之前 {#before-you-begin}

本任务的活动假设你已经：

* 阅读了[授权概念](/zh/docs/concepts/security/#authorization)。

* 遵照 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装完成 Istio 并启用了双向 TLS。

* 部署了 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用。

部署 Bookinfo 应用后通过 `http://$GATEWAY_URL/productpage` 访问 product 页面，可以看到如下内容：

* **Book Details** 在左下方，包括：图书类型，页数，出版社等。
* **Book Reviews** 在页面右下方。

当刷新页面时，应用会在 product 页面中以轮询的方式显示不同版本的评论：如红色星标，黑色星标，或者没有星标。

{{< tip >}}
如果没有在浏览器中看到预期的输出，请过几秒钟重试，因为缓存和其他传输开销会导致一些延迟。
{{< /tip >}}

## 为 HTTP 流量的工作负载配置访问控制 {#configure-access-control-for-workloads-using-http-traffic}

使用 Istio，您可以轻松地为网格中的{{< gloss "workload" >}}workloads{{< /gloss >}}设置访问控制。本任务向您展示如何使用 Istio 授权设置访问控制。首先，配置一个简单的 `deny-all` 策略，来拒绝工作负载的所有请求，然后逐渐地、增量地授予对工作负载更多的访问权。

1. 运行下面的命令在 `default` 命名空间里创建一个 `deny-all` 策略。该策略没有 `selector` 字段，它会把策略应用于 `default` 命名空间中的每个工作负载。`spec:` 字段为空值 `{}`，意思是不允许任何流量，有效地拒绝所有请求。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: deny-all
      namespace: default
    spec:
      {}
    EOF
    {{< /text >}}

    打开浏览器访问 Bookinfo 的 `productpage` (`http://$GATEWAY_URL/productpage`)页面。你将会看到 `"RBAC: access denied"`。该错误表明配置的 `deny-all` 策略按期望生效了，并且 Istio 没有任何规则允许对网格中的工作负载进行任何访问。

1. 运行下面的命令创建一个 `productpage-viewer` 策略以容许通过 `GET` 方法访问 `productpage` 工作负载。该策略没有在 `rules` 中设置 `from` 字段，这意味着所有的请求源都被容许访问，包括所有的用户和工作负载：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "productpage-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: productpage
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    在浏览器里访问 Bookinfo 的 `productpage` (`http://$GATEWAY_URL/productpage`)。你将看到 “Bookinfo Sample” 页面，但会发现页面中有如下的错误：

    * `Error fetching product details`
    * `Error fetching product reviews`

    这些错误是预期的，因为我们没有授权 `productpage` 工作负载去访问 `details` 和 `reviews` 工作负载。接下来，你需要配置一个策略来容许访问其他工作负载。

1. 运行下面的命令创建一个 `details-viewer` 策略以容许 `productpage` 工作负载以 `GET` 方式，通过使用 `cluster.local/ns/default/sa/bookinfo-productpage` ServiceAccount 去访问 `details` 工作负载：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "details-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: details
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. 运行下面的命令创建一个 `reviews-viewer` 策略以容许 `productpage` 工作负载以 `GET` 方式，通过使用 `cluster.local/ns/default/sa/bookinfo-productpage` ServiceAccount 去访问 `reviews` 工作负载：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "reviews-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: reviews
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    在浏览器访问 Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`)。现在你将看到 “Bookinfo Sample” 页面， “Book Details” 在左下方， “Book Reviews” 在右下方。但是在 “Book Reviews” 部分有 `Ratings service currently unavailable` 的错误。

    这是因为 `reviews` 工作负载没有权限访问 `ratings` 工作负载。为修复这个问题，你需要授权 `reviews` 工作负载可以访问 `ratings` 工作负载。下一步我们配置一个策略来容许 `reviews` 工作负载访问。

1. 运行下面的命令创建一个 `ratings-viewer` 策略以容许 `reviews` 工作负载以 `GET` 方式，通过使用 `cluster.local/ns/default/sa/bookinfo-reviews` ServiceAccount 去访问 `ratings` 工作负载：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "ratings-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: ratings
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-reviews"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    在浏览器访问 Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`)。你会在 “Book Reviews” 部分看到“黑色”和“红色”评分。

    **恭喜！** 您成功地应用了授权策略为使用 HTTP 流量的工作负载进行了访问控制。

## 清除 {#clean-up}

1. 从你的配置中删除所有的授权策略：

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/deny-all
    $ kubectl delete authorizationpolicy.security.istio.io/productpage-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/details-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/reviews-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/ratings-viewer
    {{< /text >}}
