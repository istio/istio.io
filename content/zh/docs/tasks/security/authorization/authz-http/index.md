---
title: HTTP 流量授权
description: 展示如何设置基于角色的 HTTP 流量访问控制。
weight: 10
keywords: [security,access-control,rbac,authorization]
aliases:
    - /zh/docs/tasks/security/role-based-access-control.html
    - /zh/docs/tasks/security/authz-http/
---

该任务向您展示了如何在 Istio 网格中为 HTTP 流量设置 Istio 授权。在[授权概念页面](/zh/docs/concepts/security/#authorization)了解更多内容。

## 开始之前

本任务的活动假设你：

* 阅读了[授权概念](/zh/docs/concepts/security/#authorization)。

* 遵照 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装完成 Istio 并启用了双向 TLS。

* 部署了 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用。

部署 Bookinfo 应用后通过`http://$GATEWAY_URL/productpage`访问 product 页面，可以看到如下内容：

* **Book Details** 在左下方，包括：图书类型，页数，出版社等。
* **Book Reviews** 在页面右下方。

当刷新页面时，应用会在 product 页面中以轮询的方式显示不同版本的评论：如红色星标，黑色星标，或者没有星标。

{{< tip >}}
如果没有在浏览器中看到预期的输出，请过几秒钟重试，因为缓存和其他传输开销会导致一些延迟。
{{< /tip >}}

## 为 HTTP 流量的工作负载配置访问控制

使用 Istio，您可以轻松地为网格中的{{< gloss "workload" >}}workloads{{< /gloss >}}设置访问控制。本任务向您展示如何使用 Istio 授权设置访问控制。首先，配置一个简单的`deny-all`策略，来拒绝工作负载的所有请求，然后逐渐地、增量地授予对工作负载的更多访问权。

1. 运行下面的命令在 `default` 命名空间里创建一个 `deny-all` 策略。该策略没有 `selector` 字段，它会把策略应用于 `default` 命名空间中的每个工作负载。策略的 `spec:` 字段为空值 `{}`，意思是不允许任何流量，有效地拒绝所有请求。

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

1. Run the following command to create a `productpage-viewer` policy to allow access
   with `GET` method to the `productpage` workload. The policy does not set the `from`
   field in the `rules` which means all sources are allowed, effectively allowing
   all users and workloads:

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

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).
    Now you should see the "Bookinfo Sample" page.
    However, you can see the following errors on the page:

    * `Error fetching product details`
    * `Error fetching product reviews` on the page.

    These errors are expected because we have not granted the `productpage`
    workload access to the `details` and `reviews` workloads. Next, you need to
    configure a policy to grant access to those workloads.

1. Run the following command to create the `details-viewer` policy to allow the `productpage`
   workload, which issues requests using the `cluster.local/ns/default/sa/bookinfo-productpage`
   service account, to access the `details` workload through `GET` methods:

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

1. Run the following command to create a policy `reviews-viewer` to allow the `productpage` workload,
   which issues requests using the `cluster.local/ns/default/sa/bookinfo-productpage` service account,
   to access the `reviews` workload through `GET` methods:

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

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`). Now, you should see the "Bookinfo Sample"
    page with "Book Details" on the lower left part, and "Book Reviews" on the lower right part. However, in the "Book Reviews" section,
    there is an error `Ratings service currently unavailable`.

    This is because the `reviews` workload doesn't have permission to access the `ratings` workload.
    To fix this issue, you need to grant the `reviews` workload access to the `ratings` workload.
    Next, we configure a policy to grant the `reviews` workload that access.

1. Run the following command to create the `ratings-viewer` policy to allow the `reviews` workload,
   which issues requests using the `cluster.local/ns/default/sa/bookinfo-reviews` service account,
   to access the `ratings` workload through `GET` methods:

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

    Point your browser at the Bookinfo `productpage` (`http://$GATEWAY_URL/productpage`).
    You should see the "black" and "red" ratings in the "Book Reviews" section.

    **Congratulations!** You successfully applied authorization policy to enforce access
    control for workloads using HTTP traffic.

## 清除

1. 从你的配置中删除所有的授权策略：

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/deny-all
    $ kubectl delete authorizationpolicy.security.istio.io/productpage-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/details-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/reviews-viewer
    $ kubectl delete authorizationpolicy.security.istio.io/ratings-viewer
    {{< /text >}}
