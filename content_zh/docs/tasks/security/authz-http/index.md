---
title: HTTP 服务的访问控制
description: 展示为 HTTP 服务设置基于角色的访问控制方法。
weight: 10
keywords: [security,access-control,rbac,authorization]
---

Istio 采用基于角色的访问控制方式，本文内容涵盖了为 HTTP 设置访问控制的各个环节。在[认证概念](/zh/docs/concepts/security/)一文中提供了 Istio 安全方面的入门教程。

## 开始之前

本任务中涉及的活动，需要具备以下条件：

* 理解[访问控制](/zh/docs/concepts/security/#授权和鉴权)概念。

* 按照[快速开始](/zh/docs/setup/kubernetes/install/kubernetes/)的步骤，在 Kubernetes 上安装了 Istio 并**启用认证功能**，本教程依赖双向 TLS 功能，在[安装步骤](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)中介绍了启用双向 TLS 的方法。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用。

* 这一任务中，借助 Service Account 在网格中提供加密的访问控制能力。为了给不同的微服务赋予不同的访问权限，就需要创建一些 Service Account 用来运行 Bookinfo 中的微服务。

    运行命令完成两个目标：
    * 创建 Service Account `bookinfo-productpage`，并用这一身份重新部署 `productpage` 微服务。
    * 创建 Service Account `bookinfo-reviews`，并用它来重新部署 `reviews`（`reviews-v2` 和 `reviews-v3` 两个 Deployment）。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml@)
    {{< /text >}}

{{< tip >}}
如果你的 Bookinfo 使用的不是 `default` 命名空间，可以使用 `kubectl -n namespace ...` 来指定命名空间。
{{< /tip >}}

* 用浏览器打开 Bookinfo 的 `productpage`（`http://$GATEWAY_URL/productpage`）应该会看到：

    * 页面左下方的 “Book Details” 中包含了类型、页数、出版商等信息。
    * “Book Reviews” 应该显示在页面右下方。

    多次刷新该页面，可能会看到页面中显示了 “Book Reviews” 的不同版本，红星、黑星和无星三个版本会轮换展示。

## 启用 Istio 访问控制 {#enable-Istio-access-control}

运行下面的命令，在 `default` 命名空间中启用 Istio 访问控制：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml@
{{< /text >}}

用浏览器打开 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`）。应该会看到 `"RBAC: access denied"`，原因是 Istio 访问控制缺省采用拒绝策略，这就要求必须显式的声明访问控制策略才能成功的访问到服务。

{{< tip >}}
缓存或者其它传播开销可能会造成生效延迟。
{{< /tip >}}

## 命名空间级别的访问控制

使用 Istio 能够轻松的在命名空间一级设置访问控制，只要设置命名空间中所有（或部分）服务可以被其它命名空间的服务访问即可。

Bookinfo 案例中，`productpage`、`reviews`、`details` 和 `ratings` 服务都部署在 `default` 命名空间之内。而 `istio-ingressgateway` 这样的 Istio 组件是部署在 `istio-system` 命名空间内的。可以定义一个策略，`default` 命名空间内的服务如果它的 `app` 标签值属于 `productpage`、`reviews`、`details` 和 `ratings` 其中的一个，就可以被同一命名空间（`default`）内的服务访问。

运行下面的命令，来创建命名空间级的访问控制策略：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
{{< /text >}}

这条策略包括：

* 创建一个名为 `service-viewer` 的 `ServiceRole`，该角色允许对于 `default` 命名空间内，并且 `app` 标签值在 `productpage`、`reviews`、`details` 和 `ratings` 范围内的服务发起读取访问。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: service-viewer
      namespace: default
    spec:
      rules:
      - services: ["*"]
        methods: ["GET"]
        constraints:
        - key: "destination.labels[app]"
          values: ["productpage", "details", "reviews", "ratings"]
    {{< /text >}}

* 创建一个 `ServiceRoleBinding`，给所有 `istio-system` 和 `default` 命名空间内的服务分配一个 `service-viewer` 角色。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-service-viewer
      namespace: default
    spec:
      subjects:
      - properties:
          source.namespace: "istio-system"
      - properties:
          source.namespace: "default"
      roleRef:
        kind: ServiceRole
        name: "service-viewer"
    {{< /text >}}

应该会看到如下输出：

{{< text plain >}}
servicerole "service-viewer" created
servicerolebinding "bind-service-viewer" created
{{< /text >}}

如果用浏览器访问 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`），应该会看到 “Bookinfo Sample” 页面，左下角是 “Book Details”，右下角是 “Book Reviews”。

{{< tip >}}
缓存或者其它传播开销可能会造成生效延迟。
{{< /tip >}}

### 清理命名空间级别的访问控制

进入下一任务之前，首先删除下列配置：

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
{{< /text >}}

## 服务级访问控制

接下来展示的是如何使用 Istio 在服务一级进行访问控制。开始之前，首先确认两个前提条件：

* 已经[启用 Istio 访问控制](#enable-Istio-access-control)。
* 已经[清理命名空间级别的访问控制](#清理命名空间级别的访问控制)。

用浏览器访问 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`），会看到 `"RBAC: access denied"`。我们将会逐步在 Bookinfo 中加入访问权限。

### 第一步：开放到 `productpage` 服务的访问

在这一步骤中，我们会创建一条策略，允许外部请求通过 Ingress 访问 `productpage` 服务。

运行下列命令：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
{{< /text >}}

这条策略完成了如下工作：

* 创建一个名为 `productpage-viewer` 的 `ServiceRole`，允许对 `productpage` 服务进行读取访问。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: productpage-viewer
      namespace: default
    spec:
      rules:
      - services: ["productpage.default.svc.cluster.local"]
        methods: ["GET"]
    {{< /text >}}

* 创建一个 `ServiceRoleBinding`，命名为 `bind-productpager-viewer`，将 `productpage-viewer` 角色授予所有用户和服务。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-productpage-viewer
      namespace: default
    spec:
      subjects:
      - user: "*"
      roleRef:
        kind: ServiceRole
        name: "productpage-viewer"
    {{< /text >}}

用浏览器访问 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`），现在应该就能看到 “Bookinfo Sample” 页面了，但是页面上会显示 `Error fetching product details` and `Error fetching product reviews` 的错误信息。这些错误信息是正常的，原因是 `productpage` 还无权访问 `details` 和 `reviews` 服务。下面我们会尝试解决这一问题。

{{< tip >}}
缓存或者其它传播开销可能会造成生效延迟。
{{< /tip >}}

### 第二步：开放到 details 和 reviews 服务的访问

创建一条策略，允许 `productpage` 访问 details 和 reviews 服务。注意在[开始之前](#开始之前)步骤中已经创建了 `bookinfo-productpage`，这个 Service Account 被用于运行 `productpage` 服务，换句话说 `bookinfo-productpage` 就是 `productpage` 服务的身份标识。

运行如下命令：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml@
{{< /text >}}

这一策略中包含了如下操作。

* 新建名为 `details-reviews-viewer` 的 `ServiceRole`，该角色允许对 `details` 和 `reviews` 服务的访问。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: details-reviews-viewer
      namespace: default
    spec:
      rules:
      - services: ["details.default.svc.cluster.local", "reviews.default.svc.cluster.local"]
        methods: ["GET"]
    {{< /text >}}

* 创建 `ServiceRoleBinding` 对象，命名为 `bind-details-reviews`，将 `details-reviews-viewer` 角色授予 `cluster.local/ns/default/sa/bookinfo-productpage`（也就是 `productpage` 服务）。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-details-reviews
      namespace: default
    spec:
      subjects:
      - user: "cluster.local/ns/default/sa/bookinfo-productpage"
      roleRef:
        kind: ServiceRole
        name: "details-reviews-viewer"
    {{< /text >}}

浏览器打开 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`），现在应该就能看到 “Bookinfo Sample” 页面中，在左下方显示了 “Book Details”，在右下方显示了 “Book Reviews”。然而 “Book Reviews” 部分显示了一个错误信息：`Ratings service currently unavailable`，错误的原因是 `reviews` 服务无权访问 `ratings` 服务。要解决这一问题，就需要授权给 `reviews` 服务，允许它访问 `ratings` 服务。

{{< tip >}}
缓存或者其它传播开销可能会造成生效延迟。
{{< /tip >}}

### 第三步：开放访问 `ratings` 服务

这里来创建一条策略，允许 `reviews` 服务访问 `ratings` 服务。注意在[开始之前](#开始之前)，我们已经为 `reviews` 服务创建了一个叫做 `bookinfo-reviews` 的 Service Account，它就是 `reviews` 服务的身份标识。

运行下面的命令，创建允许 `reviews` 服务访问 `ratings` 服务的策略：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/ratings-policy.yaml@
{{< /text >}}

这条策略包含以下动作：

* 创建一个名为 `ratings-viewer` 的 `ServiceRole`，并允许其访问 `ratings` 服务。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: ratings-viewer
      namespace: default
    spec:
      rules:
      - services: ["ratings.default.svc.cluster.local"]
        methods: ["GET"]
    {{< /text >}}

* 创建一个 `ServiceRoleBinding` 对象，命名为 `bind-ratings`，把 `ratings-viewer` 角色授予给 `cluster.local/ns/default/sa/bookinfo-reviews`（也就是 `reviews` 服务）。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-ratings
      namespace: default
    spec:
      subjects:
      - user: "cluster.local/ns/default/sa/bookinfo-reviews"
      roleRef:
        kind: ServiceRole
        name: "ratings-viewer"
    {{< /text >}}

用浏览器访问 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`）。现在应该能在  “Book Reviews” 中看到黑色或红色的星级图标。

{{< tip >}}
缓存或者其它传播开销可能会造成生效延迟。
{{< /tip >}}

## 清理

* 移除 Istio 访问控制策略：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/ratings-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    {{< /text >}}

    也可以选择使用下面的命令删除所有 `ServiceRole` 和 `ServiceRoleBinding`：

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

* 禁用 Istio 访问控制：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml@
    {{< /text >}}
