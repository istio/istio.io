---
title: TCP 流量的授权
description: 展示如何设置 TCP 流量的访问控制。
weight: 20
keywords: [security,access-control,rbac,tcp,authorization]
aliases:
    - /zh/docs/tasks/security/authz-tcp/
---

该任务向您展示了在 Istio 网格中如何为 TCP 流量设置 Istio 授权。
您可以在[授权概念页面](/zh/docs/concepts/security/#authorization)中了解到关于 Istio 授权的更多信息。

## 开始之前{#before-you-begin}

本文任务假定您已经：

* 阅读了[授权概念](/zh/docs/concepts/security/#authorization)。

* 按照 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装了 Istio 并启用了双向 TLS。

* 部署了 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用。

部署完 Bookinfo 应用后，打开 `http://$GATEWAY_URL/productpage` 地址进入到 Bookinfo 图书页面。在该页面中，您可以看到如下模块：

* 在页面的左下方是图书详情 (**Book Detail**) 模块，内容包括：图书类型、页数、出版社等信息。
* 在页面的右下方是图书评价（**Book Reviews**) 模块。

每次刷新页面后，图书页面的书评模块会有不同的版本样式，在三种版本（红色星级、黑色星级、没有星级）之间轮换。

{{< tip >}}
如果您在按照说明操作时未在浏览器中看到预期的输出，请在几秒钟后重试，因为缓存和其他传播开销可能会导致有些延迟。
{{< /tip >}}

{{< warning >}}
此任务需要启用双向 TLS，因为以下示例使用策略中的主体和命名空间。
{{< /warning >}}

## 配置 TCP 工作负载的访问控制{#configure-access-control-for-a-TCP-workload}

默认情况下，[Bookinfo](/zh/docs/examples/bookinfo/) 示例应用只使用 HTTP 协议。
为了演示 TCP 流量的授权，您需要将应用更新到使用 TCP 的版本。
按照下面的步骤，部署 Bookinfo 应用示例，并且将 `ratings` 服务升级到 `v2` 版本，在该版本中会使用 TCP 调用后端 MongoDB 服务，然后将授权策略应用到 MongoDB 工作负载上。

1. 使用 `bookinfo-ratings-v2` 服务账户安装 `ratings` 工作负载的 `v2` 版本：

    {{< tabset category-name="sidecar" >}}

    {{< tab name="With automatic sidecar injection" category-value="auto" >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="With manual sidecar injection" category-value="manual" >}}

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 创建适当的 destination rules：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    因为 virtual service 规则中引用的 subset 项依赖 destination rules，所以在添加 virtual service 规则之前先等待几秒钟以让 destination rules 传播生效。

1. 在 destination rules 传播生效后，更新 `reviews` 工作负载以只使用 `v2` 版本的 `ratings` 工作负载：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    {{< /text >}}

1. 浏览 Bookinfo 的产品页面（`http://$GATEWAY_URL/productpage`）。

    在这一页面中，您会在 **Book Reviews** 模块中看到一条错误信息：**"Ratings service is currently unavailable."**。
    这是因为我们现在用的是 `v2` 版本的 `ratings` 工作负载，但是我们还没有部署 MongoDB。

1. 部署 MongoDB 工作负载：

    {{< tabset category-name="sidecar" >}}

    {{< tab name="With automatic sidecar injection" category-value="auto" >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="With manual sidecar injection" category-value="manual" >}}

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@)
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 浏览 Bookinfo 的产品页面（`http://$GATEWAY_URL/productpage`）。

1. 确认 **Book Reviews** 模块显示了书评。

    部署了 MongoDB 工作负载之后，在将授权配置为仅允许授权请求之前，我们需要为工作负载应用默认的 `deny-all` 策略，以确保默认情况下拒绝对 MongoDB 工作负载的所有请求。

1. 对 MongoDB 工作负载应用默认的 `deny-all` 策略：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: deny-all
    spec:
      selector:
        matchLabels:
          app: mongodb
    EOF
    {{< /text >}}

    打开 Bookinfo 的 `productpage` 页面（`http://$GATEWAY_URL/productpage`）。您会看到：

    * 页面左下角的 **Book Details** 中包含了书籍类型、页数以及出版商等信息。
    * 页面右下角的 **Book Reviews** 显示了错误信息：**"Ratings service is currently unavailable"**。

    在配置了默认拒绝所有请求之后，我们需要创建一个 `bookinfo-ratings-v2` 策略以允许来自 `cluster.local/ns/default/sa/bookinfo-ratings-v2` 服务账户在 `27017` 端口上对 MongoDB 工作负载的请求。
    我们授权给这个服务账户，是因为来自 `ratings-v2` 工作负载的请求都用的是 `cluster.local/ns/default/sa/bookinfo-ratings-v2` 服务账户发出的。

1. 为来自 `cluster.local/ns/default/sa/bookinfo-ratings-v2` 服务账户的 TCP 流量增强工作负载级别的访问控制：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: bookinfo-ratings-v2
    spec:
      selector:
        matchLabels:
          app: mongodb
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-ratings-v2"]
        to:
        - operation:
            ports: ["27017"]
    EOF
    {{< /text >}}

    打开 Bookinfo 的 `productpage` 页面（`http://$GATEWAY_URL/productpage`），您现在应该看到以下各节按预期工作：

    * 页面左下角的 **Book Details** 中包含了书籍类型、页数以及出版商等信息。
    * 页面右下角的 **Book Reviews** 显示了红色星级的书评。

    **恭喜！** 您已经成功部署了通过 TCP 流量进行通信的工作负载，并应用了网格级别和工作负载级别的授权策略来对请求实施访问控制。

## 清理{#cleanup}

1. 删除 Istio 授权策略配置：

    {{< text bash >}}
    $ kubectl delete authorizationpolicy.security.istio.io/deny-all
    $ kubectl delete authorizationpolicy.security.istio.io/bookinfo-ratings-v2
    {{< /text >}}

1. 删除 `v2` 版本的 ratings 工作负载和 MongoDB 的 deployment：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    $ kubectl delete -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    $ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
    {{< /text >}}
