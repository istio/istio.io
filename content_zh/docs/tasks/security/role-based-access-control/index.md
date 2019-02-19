---
title: 基于角色的访问控制
description: 展示如何在服务网格中进行基于角色的访问控制。
weight: 40
keywords: [安全,访问控制,rbac,鉴权]
---

在服务网格中为服务进行授权控制（基于角色的访问控制）时，会涉及到本例中包含的一系列操作。在[授权](/zh/docs/concepts/security/#授权和鉴权)一节中讲述了更多这方面的内容，并且还有一个基本的 Istio 安全方面的教程。

## 准备任务

本文活动开始之前，我们有如下假设：

* 具有对[授权](/zh/docs/concepts/security/#授权和鉴权)概念的了解。

* 在 Istio 中遵循[快速入门](/zh/docs/setup/kubernetes/quick-start/)的步骤 **启用了认证功能**，这个教程对双向 TLS 有依赖，因此要在[安装步骤](/zh/docs/setup/kubernetes/quick-start/#安装步骤)中启用双向 TLS 认证。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用。

* 这个任务里，我们会在 Service account 的基础上启用访问控制，在网格中进行加密的认证。为了给不同的微服务以不同的访问授权，就需要建立一系列不同的 Service account，用这些账号来分别运行 Bookinfo 中的微服务。

    运行命令，完成以下目的：

    * 创建 Service account：`bookinfo-productpage`，并用这一身份部署 `productpage`。
    * 创建 Service account：`bookinfo-reviews`，并用这一身份部署 `reviews`（注意其中包含 `reviews-v2` 和 `reviews-v3` 两个版本）。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-add-serviceaccount.yaml@)
    {{< /text >}}

{{< tip >}}
如果使用的命名空间不是 `default`，就应改用 `kubectl -n namespace ...` 来指定命名空间。
{{< /tip >}}

* Istio 1.0 中的 RBAC 有较大更新。请确认在继续之前，已经清理了所有现存 RBAC 规则。

    * 运行下面的命令，禁用旧的 RBAC 功能，在 1.0 中就无需这一步骤了：

    {{< text bash >}}
    $ kubectl delete authorization requestcontext -n istio-system
    $ kubectl delete rbac handler -n istio-system
    $ kubectl delete rule rbaccheck -n istio-system
    {{< /text >}}

    * 用这个命令移除所有现存 RBAC 策略：

    {{< tip >}}
    保存现有策略是可以的，不过需要对策略的 `constraints` 以及 `properties` 字段进行修改，参考[约束和属性](/zh/docs/reference/config/authorization/constraints-and-properties/)中的内容，了解这两个字段所支持的值。
    {{< /tip >}}

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

* 用浏览器打开 Bookinfo 的 `productpage` 页面，会看到：

    * 页面左下角是 “Book Details”，其中包含了类型、页数、出版商等信息。
    * 页面右下角是 “Book Reviews” 部分。

    如果刷新几次，会发现 `productpage` 在切换使用不同的 `reviews` 版本（红星、黑星、无）。

## 授权许可模式

本节介绍如何在以下两种情况下使用授权许可模式：

    * 在未经授权的环境中，测试是否可以安全地启用授权。
    * 在已启用授权的环境中，测试添加新授权策略是否安全。

### 测试启用全局授权是否安全

此任务说明如何使用授权许可模式来测试是否可以安全地启用全局授权。

在开始之前，请确保您已完成[准备任务](#准备任务)。

1.  将全局授权配置设置为许可模式。

    运行以下命令：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: RbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["default"]
      enforcement_mode: PERMISSIVE
    EOF
    {{< /text >}}

    将浏览器指向 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`），您应该看到一切正常，与[准备任务](#准备任务)相同。

1.  将 YAML 文件应用于许可模式度量标准集合。

    运行以下命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    logentry.config.istio.io/rbacsamplelog created
    stdio.config.istio.io/rbacsamplehandler created
    rule.config.istio.io/rabcsamplestdio created
    {{< /text >}}

1.  将流量发送到示例应用程序。

    对于 Bookinfo 示例，请在 Web 浏览器中访问 `http://$GATEWAY_URL/productpage` 或发出以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    将您的浏览器指向 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`），您应该看到一切正常。

1.  验证已创建日志流并检查 `permissiveResponseCode`。

    在 Kubernetes 环境中，搜索日志以查找 `istio-telemetry` pods，如下所示：

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T21:53:42.059444Z","instance":"rbacsamplelog.logentry.istio-system","destination":"ratings","latency":"9.158879ms","permissiveResponseCode":"403","permissiveResponsePolicyID":"","responseCode":200,"responseSize":48,"source":"reviews","user":"cluster.local/ns/default/sa/bookinfo-reviews"}
    {"level":"warn","time":"2018-08-30T21:53:41.037824Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"1.091670916s","permissiveResponseCode":"403","permissiveResponsePolicyID":"","responseCode":200,"responseSize":379,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T21:53:41.019851Z","instance":"rbacsamplelog.logentry.istio-system","destination":"productpage","latency":"1.112521495s","permissiveResponseCode":"403","permissiveResponsePolicyID":"","responseCode":200,"responseSize":5723,"source":"istio-ingressgateway","user":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"}
    {{< /text >}}

    在上面的遥测日志中，用户现在看到的 `responseCode` 是 200。
    用户在将全局授权配置从 `PERMISSIVE` 模式切换到 `ENFORCED` 模式后将看到 `permissiveResponseCode` 是 403，
    这表示全局授权配置在滚动到生产后将按预期工作。

1.  在生产中推出新的授权策略之前，请以许可模式应用它。
    `注意`，当全局授权配置处于许可模式时，默认情况下所有策略都将处于许可模式。

    运行以下命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    {{< /text >}}

1.  再次向示例应用程序发送流量。

    对于 Bookinfo 示例，请在 Web 浏览器中访问 `http://$GATEWAY_URL/productpage` 或发出以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

    将您的浏览器指向 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`），您应该看到一切正常。

1.  验证已创建日志流并检查 `permissiveResponseCode`。

    在 Kubernetes 环境中，搜索日志以查找 `istio-telemetry` pods，如下所示：

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T21:55:53.590430Z","instance":"rbacsamplelog.logentry.istio-system","destination":"ratings","latency":"4.415633ms","permissiveResponseCode":"403","permissiveResponsePolicyID":"","responseCode":200,"responseSize":48,"source":"reviews","user":"cluster.local/ns/default/sa/bookinfo-reviews"}
    {"level":"warn","time":"2018-08-30T21:55:53.565914Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"32.97524ms","permissiveResponseCode":"403","permissiveResponsePolicyID":"","responseCode":200,"responseSize":379,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T21:55:53.544441Z","instance":"rbacsamplelog.logentry.istio-system","destination":"productpage","latency":"57.800056ms","permissiveResponseCode":"200","permissiveResponsePolicyID":"productpage-viewer","responseCode":200,"responseSize":5723,"source":"istio-ingressgateway","user":"cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"}
    {{< /text >}}

    在上面的遥测日志中，用户现在看到的 `responseCode` 是 200。
    对于 `productpage` 页面服务，`permissiveResponseCode` 为 200，对于 `ratings` 和 `reviews` 服务为 403，
    这是用户在将策略模式从 `PERMISSIVE` 模式切换到 `ENFORCED` 模式后将看到的内容;
    结果与[步骤1](#第一步-允许到-productpage-服务的访问)一致。

1.  删除与许可模式相关的 yaml 文件：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-permissive.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  现在我们已经验证了授权在打开时按预期工作，在[启用 Istio 授权](#启用-istio-授权)下面打开授权是安全的。

### 在滚动到生产之前，测试新的授权策略按预期工作

此任务说明如何使用授权许可模式来测试新授权策略在已启用授权的环境中按预期工作。

在开始之前，请确保您已完成[步骤1](#第一步-允许到-productpage-服务的访问)。

1.  在应用新策略之前，通过将其模式设置为permissive来测试它：

    运行以下命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy-permissive.yaml@
    {{< /text >}}

    该策略与[允许访问详细信息和评论服务](#第二步-允许对-details-和-reviews-服务的访问)中定义的策略相同，
    除了在 ServiceRoleBinding 中设置了 `PERMISSIVE` 模式。

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
      mode: PERMISSIVE
    {{< /text >}}

    将您的浏览器指向 Bookinfo `productpage`（`http://$GATEWAY_URL/productpage`），
    您仍然会在页面上看到错误 `Error fetching product details` 和 `Error fetching product reviews`。由于策略处于 `PERMISSIVE` 模式，因此预期会出现这些错误。

1.  将 YAML 文件应用于许可模式度量标准集合。

    运行以下命令：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  将流量发送到示例应用程序。

    对于 Bookinfo 示例，请在 Web 浏览器中访问 `http://$GATEWAY_URL/productpage` 或发出以下命令：

    {{< text bash >}}
    $ curl http://$GATEWAY_URL/productpage
    {{< /text >}}

1.  验证日志并再次检查 `permissiveResponseCode`。

    在 Kubernetes 环境中，搜索日志以查找 `istio-telemetry` pods，如下所示：

    {{< text bash json >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep \"instance\":\"rbacsamplelog.logentry.istio-system\"
    {"level":"warn","time":"2018-08-30T22:59:42.707093Z","instance":"rbacsamplelog.logentry.istio-system","destination":"details","latency":"423.381µs","permissiveResponseCode":"200","permissiveResponsePolicyID":"details-reviews-viewer","responseCode":403,"responseSize":19,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {"level":"warn","time":"2018-08-30T22:59:42.763423Z","instance":"rbacsamplelog.logentry.istio-system","destination":"reviews","latency":"237.333µs","permissiveResponseCode":"200","permissiveResponsePolicyID":"details-reviews-viewer","responseCode":403,"responseSize":19,"source":"productpage","user":"cluster.local/ns/default/sa/bookinfo-productpage"}
    {{< /text >}}

    在上面的遥测日志中，用户现在看到的 `ratings` 和 `reviews` 服务的 `responseCode` 为 403。
    对于 `ratings` 和 `reviews` 服务，`permissiveResponseCode` 为 200，
    这是用户在将策略模式从 `PERMISSIVE` 模式切换到 `ENFORCED` 模式后将看到的内容;
    它表示新的授权策略在滚动到生产后将按预期工作。

1.  删除与许可模式相关的 yaml 文件：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy-permissive.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-permissive-telemetry.yaml@
    {{< /text >}}

1.  现在我们已经验证了新策略将按预期工作，在[步骤 2](#第二步-允许对-details-和-reviews-服务的访问) 应用策略之后是安全的。

## 启用 Istio 授权

运行下面的命令，为 `default` 命名空间启用 Istio 授权：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml@
{{< /text >}}

用浏览器再次打开 `productpage` (`http://$GATEWAY_URL/productpage`)，这次会看到 `RBAC: access denied`。Istio 的鉴权行为是“缺省拒绝”的，也就是说必须要显式的进行授权，才能对服务进行访问。

{{< tip >}}
缓存和传播可能会造成一定的延迟。
{{< /tip >}}

## 命名空间级的访问控制

Istio 的授权能力可以轻松的设置命名空间级的访问控制，只要指定命名空间内的所有（或者部分）服务可以被另一命名空间的服务访问即可。

Bookinfo 示例中，`productpage`、`reviews`、`details` 以及 `ratings` 服务被部署在 `default` 命名空间中，而 `istio-ingressgateway` 等 Istio 组件是部署在 `istio-system` 命名空间中的。我们可以定义一个策略，`default` 命名空间中所有服务，如果其 `app` 标签取值在 `productpage`、`reviews`、`details` 以及 `ratings` 范围之内，就可以被本命名空间内以及 `istio-system` 命名空间内的服务进行访问。

运行这一命令，创建一个命名空间级别的访问控制策略：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
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

{{< tip >}}
缓存和传播可能会造成一定的延迟。
{{< /tip >}}

### 清除命名空间级的访问控制

在进行后续任务之前，首先移除下面的配置：

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/rbac/namespace-policy.yaml@
{{< /text >}}

## 服务级的访问控制

这个任务展示了使用 Istio 授权功能配置服务级访问控制的方法。开始之前，请进行下面的确认：

* 已经[启用 Istio 授权](#启用-istio-授权)
* 已经[清除命名空间级的访问控制](清除命名空间级的访问控制：

浏览器打开 Bookinfo 的 `productpage` (`http://$GATEWAY_URL/productpage`)。会看到：`RBAC: access denied`。我们会在 Bookinfo 中逐步为服务加入访问许可。

### 第一步，允许到 `productpage` 服务的访问

这里我们要创建一条策略，允许外部请求通过 Ingress 浏览 `productpage`。

执行命令：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
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

{{< tip >}}
缓存和传播可能会造成一定的延迟。
{{< /tip >}}

### 第二步，允许对 `details` 和 `reviews` 服务的访问

创建一条策略，让 `productpage` 服务能够读取 `details` 和 `reviews` 服务。注意在[准备任务](#准备任务)中，我们给 `productpage` 服务创建了一个命名为 `bookinfo-productpage` 的 Service account，它就是 `productpage` 服务的认证 ID。

运行下面的命令：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml@
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
      - user: "cluster.local/ns/default/sa/bookinfo-productpage"
      roleRef:
        kind: ServiceRole
        name: "details-reviews-viewer"
    {{< /text >}}

浏览 Bookinfo 页面 `productpage` (`http://$GATEWAY_URL/productpage`)。现在看到的 “Bookinfo Sample” 中包含了左下角的 “Book Details” 以及右下角的 “Book Reviews”。然而 “Book Reviews” 中有一条错误信息： `Ratings service currently unavailable`，这是因为 `reviews` 服务无权访问 `ratings` 服务，要更正这一问题，就应该给 `ratings` 服务授权，使其能够访问 `reviews` 服务。下面的步骤就会完成这一需要。

{{< tip >}}
缓存和传播可能会造成一定的延迟。
{{< /tip >}}

### 第三步，允许对 `ratings` 服务的访问

接下来新建一条策略，允许 `reviews` 服务对 `ratings` 发起读取访问。注意，我们在[准备任务](#准备任务)步骤里为 `reviews` 服务创建了 Service account `bookinfo-reviews`，这个账号就是 `reviews` 服务的认证凭据。

下面的命令会创建一条允许 `reviews` 服务读取 `ratings` 服务的策略。

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/ratings-policy.yaml@
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
      - user: "cluster.local/ns/default/sa/bookinfo-reviews"
      roleRef:
        kind: ServiceRole
        name: "ratings-viewer"
    {{< /text >}}

用浏览器浏览 Bookinfo 应用的 `productpage` (`http://$GATEWAY_URL/productpage`)，应该就会看到 “Book Reviews” 区域中显示红色或者黑色的评级信息。

{{< tip >}}
缓存和传播可能会造成一定的延迟。
{{< /tip >}}

## 清理

* 清理 Istio 授权策略的相关配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/ratings-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/details-reviews-policy.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/productpage-policy.yaml@
    {{< /text >}}

    或者也可以运行命令删除所有的 `ServiceRole` 以及 `ServiceRoleBinding` 资源：

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

* 禁用 Istio 的授权功能：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-ON.yaml@
    {{< /text >}}
