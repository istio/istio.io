---
title: 基于角色的访问控制
description: 展示如何在 Istio 服务网格中进行基于角色的访问控制
weight: 40
keywords: [security,access-control,rbac,authorization]
---

在服务网格中为服务进行授权控制（基于角色的访问控制）时，会涉及到本例中包含的一系列操作。在[授权](/docs/concepts/security/#authorization)一节中讲述了更多这方面的内容，并且还有一个基本的 Istio 安全方面的教程。

## 开始之前

本文活动开始之前，我们有如下假设：

* 具有对[授权](/docs/concepts/security/#authorization)概念的了解。

* 在 Istio 中遵循[快速入门](/docs/setup/kubernetes/quick-start/)的步骤 **启用了认证功能**，这个教程对双向 TLS 有依赖，因此要在[安装步骤](/docs/setup/kubernetes/quick-start/#installation-steps)中启用双向 TLS 认证。

* 部署 [Bookinfo](/docs/examples/bookinfo/) 示例应用。

* 这个任务里，我们会在 Service account 的基础上启用访问控制，在网格中进行加密的认证。为了给不同的微服务以不同的访问授权，就需要建立一系列不同的 Service account，用这些账号来分别运行 Bookinfo 中的微服务。

    运行命令，完成以下目的：

    * 创建 Service account：`bookinfo-productpage`，并用这一身份部署 `productpage`。
    * 创建 Service account：`bookinfo-reviews`，并用这一身份部署 `reviews`（注意其中包含 `reviews-v2` 和 `reviews-v3` 两个版本）。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml@)
    {{< /text >}}

> 如果使用的命名空间不是 `default`，就应改用 `istioctl -n namespace ...` 来指定命名空间。

* Istio 1.0 中的 RBAC 有较大更新。请确认在继续之前，已经清理了所有现存 RBAC 规则。

    * 运行下面的命令，禁用旧的 RBAC 功能，在 1.0 中就无需这一步骤了：

    {{< text bash >}}
    $ kubectl delete authorization requestcontext -n istio-system
    $ kubectl delete rbac handler -n istio-system
    $ kubectl delete rule rbaccheck -n istio-system
    {{< /text >}}

    * 用这个命令移除所有现存 RBAC 策略：

      > 保存现有策略是可以的，不过需要对策略的 `constraints` 以及 `properties` 字段进行修改，参考[约束和属性](/docs/reference/config/authorization/constraints-and-properties/)中的内容，了解这两个字段所支持的值。

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

* 用浏览器打开 Bookinfo 的 `productpage` 页面，会看到：

    * 页面左下角是 “Book Details”，其中包含了类型、页数、出版商等信息。
    * 页面右下角是 “Book Reviews” 部分。

    如果刷新几次，会发现 `productpage` 在切换使用不同的 `reviews` 版本（红星、黑星、无）。

## 启用 Istio 授权

运行下面的命令，为 `default` 命名空间启用 Istio 授权：

{{< text bash >}}
$ istioctl create -f @samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml@
{{< /text >}}

> 如果前面已经创建了冲突的规则，应该使用 `istioctl replace` 替代 `istioctl create`。

用浏览器再次打开 `productpage` (`http://$GATEWAY_URL/productpage`)，这次会看到 `RBAC: access denied`。Istio 的鉴权行为是“缺省拒绝”的，也就是说必须要显式的进行授权，才能对服务进行访问。

> 缓存和传播可能会造成一定的延迟。

## 命名空间级的访问控制

Istio 的授权能力可以轻松的设置命名空间级的访问控制，只要指定命名空间内的所有（或者部分）服务可以被另一命名空间的服务访问即可。

Bookinfo 示例中，`productpage`、`reviews`、`details` 以及 `ratings` 服务被部署在 `default` 命名空间中，而 `istio-ingressgateway` 等 Istio 组件是部署在 `istio-system` 命名空间中的。我们可以定义一个策略，`default` 命名空间中所有服务，如果其 `app` 标签取值在 `productpage`、`reviews`、`details` 以及 `ratings` 范围之内，就可以被本命名空间内以及 `istio-system` 命名空间内的服务进行访问。

运行这一命令，创建一个命名空间级别的访问控制策略：

{{< text bash >}}
$ istioctl create -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
{{< /text >}}

这一策略完成如下任务：

* 创建名为 `service-viewer` 的 `ServiceRole`，允许访问 `default` 命名空间中所有 `app` 标签值在 `productpage`、`reviews`、`details` 以及 `ratings` 范围之内的服务。注意其中的 `constraint` 字段，确定了服务的 `app` 标签取值必须在指定范围以内：

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

* 创建 `ServiceRoleBinding` 对象，用来把 `service-viewer` 角色指派给所有 `istio-system` 和 `default` 命名空间的服务：

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

命令执行结果大致如下：

{{< text plain >}}
servicerole "service-viewer" created
servicerolebinding "bind-service-viewer" created
{{< /text >}}

如果这时用浏览器浏览 Bookinfo 的 `productpage` 页面 (`http://$GATEWAY_URL/productpage`)，会再次看到完整的页面，包含了左下角的 “Book Details” 以及右下角的 “Book Reviews”。

> 缓存和传播可能会造成一定的延迟。

### 清除命名空间级的访问控制

在进行后续任务之前，首先移除下面的配置：

{{< text bash >}}
$ istioctl delete -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
{{< /text >}}

## 服务级的访问控制

这个任务展示了使用 Istio 授权功能配置服务级访问控制的方法。开始之前，请进行下面的确认：

* 已经[启用 Istio 授权](#启用-Istio-授权)
* 已经[清除命名空间级的访问控制](清除命名空间级的访问控制：

浏览器打开 Bookinfo 的 `productpage` (`http://$GATEWAY_URL/productpage`)。会看到：`RBAC: access denied`。我们会在 Bookinfo 中逐步为服务加入访问许可。

### 第一步，允许到 “productpage” 服务的访问

这里我们要创建一条策略，允许外部请求通过 Ingress 浏览 `productpage`。

执行命令：

{{< text bash >}}
$ istioctl create -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
{{< /text >}}

这条策略完成以下工作：

* 创建 `ServiceRole`，命名为 `productpage-viewer`，允许到 `productpage` 服务的读取访问：

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

* 创建 `ServiceRole`，并命名为 `productpage-viewer`，将 `productpage-viewer` 角色赋予给所有用户和服务：

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-productpager-viewer
      namespace: default
    spec:
      subjects:
      - user: "*"
      roleRef:
        kind: ServiceRole
        name: "productpage-viewer"
    {{< /text >}}

再次浏览 Bookinfo 的 `productpage` (`http://$GATEWAY_URL/productpage`)。应该能看到 “Bookinfo Sample” 页面了。但是还会显示 `Error fetching product details` 和 `Error fetching product reviews` 的错误信息。这是因为我们还没有给 `productpage` 访问 `details` 和 `reviews` 服务的授权。我们接下来就修复这个问题。

> 缓存和传播可能会造成一定的延迟。

### 第二步，允许对 `details` 和 `reviews` 服务的访问。

创建一条策略，让 `productpage` 服务能够读取 `details` 和 `reviews` 服务。注意在[开始之前](#开始之前)中，我们给 `productpage` 服务创建了一个命名为 `bookinfo-productpage` 的 Service account，它就是 `productpage` 服务的认证 ID。

运行下面的命令：

{{< text bash >}}
$ istioctl create -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml@
{{< /text >}}

这一策略完成以下任务：

* 创建一个 `ServiceRole`，命名为 `details-reviews-viewer`，允许对 `details` 和 `reviews` 服务进行只读访问。

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

* 创建一个 `ServiceRoleBinding` 并命名为 `bind-details-review`，用来把 `details-reviews-viewer` 角色授予给 `cluster.local/ns/default/sa/bookinfo-productpage`（也就是 `productpage` 服务的 Service account）。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-details-reviews
      namespace: default
    spec:
      subjects:
      - user: "spiffe://cluster.local/ns/default/sa/bookinfo-productpage"
      roleRef:
        kind: ServiceRole
        name: "details-reviews-viewer"
    {{< /text >}}

浏览 Bookinfo 页面 `productpage` (`http://$GATEWAY_URL/productpage`)。现在看到的 “Bookinfo Sample” 中包含了左下角的 “Book Details” 以及右下角的 “Book Reviews”。然而 “Book Reviews” 中有一条错误信息： `Ratings service currently unavailable`，这是因为 `reviews` 服务无权访问 `ratings` 服务，要更正这一问题，就应该给 `ratings` 服务授权，使其能够访问 `reviews` 服务。下面的步骤就会完成这一需要。

> 缓存和传播可能会造成一定的延迟。

### 第三步，允许对 `ratings` 服务的访问

接下来新建一条策略，允许 `reviews` 服务对 `ratings` 发起读取访问。注意，我们在[开始之前](#开始之前)步骤里为 `reviews` 服务创建了 Service account `bookinfo-reviews`，这个账号就是 `reviews` 服务的认证凭据。

下面的命令会创建一条允许 `reviews` 服务读取 `ratings` 服务的策略。

{{< text bash >}}
$ istioctl create -f @samples/bookinfo/platform/kube/rbac/ratings-policy.yaml@
{{< /text >}}

这条策略完成以下工作：

* 创建 `ServiceRole` 命名为 `ratings-viewer`，这一角色允许对 `ratings` 服务的访问。

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

* 创建 `ServiceRoleBinding`，命名为 `bind-ratings`，将 `ratings-viewer` 角色指派给 `cluster.local/ns/default/sa/bookinfo-reviews`，给这个 Service account 授权，也就就代表了给 `reviews` 服务授权。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-ratings
      namespace: default
    spec:
      subjects:
      - user: "spiffe://cluster.local/ns/default/sa/bookinfo-reviews"
      roleRef:
        kind: ServiceRole
        name: "ratings-viewer"
    {{< /text >}}

用浏览器浏览 Bookinfo 应用的 `productpage` (`http://$GATEWAY_URL/productpage`)，应该就会看到 “Book Reviews” 区域中显示红色或者黑色的评级信息。

> 缓存和传播可能会造成一定的延迟。

## 清理

* 清理 Istio 授权策略的相关配置：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/platform/kube/rbac/ratings-policy.yaml@
    $ istioctl delete -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml@
    $ istioctl delete -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    {{< /text >}}

    或者也可以运行命令删除所有的 `ServiceRole` 以及 `ServiceRoleBinding` 资源：

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

* 禁用 Istio 的授权功能：

    {{< text bash >}}
    $ istioctl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml@
    {{< /text >}}
