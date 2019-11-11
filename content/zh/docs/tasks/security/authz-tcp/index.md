---
title: TCP 服务的权限控制
description: 展示如何为 TCP 服务设置基于角色的权限控制。
weight: 10
keywords: [security,access-control,rbac,tcp,authorization]
---

本任务涵盖了在服务网格中为 TCP 服务设置 Istio RBAC 所需的操作。可以阅读[权限控制概念文档](/zh/docs/concepts/security/#authorization).中的相关内容。

## 开始之前{#before-you-begin}

本文任务假设，你已经：

* Read the [Istio 中的授权和鉴权](/zh/docs/concepts/security/#authorization).

* 按照 [快速开始](/zh/docs/setup/install/kubernetes/) 的指导，在 Kubernetes 中安装完成 Istio。

* 部署完成 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 应用示例。

部署完成 Bookinfo 应用后，打开 `http://$GATEWAY_URL/productpage` 连接进入到 Bookinfo 图书页面。在该页面中，可以看到一下几个模块：

* 在页面的左下方是图书详情 (**Book Detail**) 模块，内容包括：图书类型、页数、出版社等信息。
* 在页面的右下方是图书评价（**Book Reviews**) 模块。

每次刷新页面后，图书页面的书评模块会有不同的版本样式，在三种版本（红色星级、黑色星级、没有星级）之间轮换。

## 部署并配置 TCP 服务{#installing-and-configuring-a-tcp-service}

默认情况下，[Bookinfo](/zh/docs/examples/bookinfo/) 应用示例只调用 HTTP 服务。为了演示 Istio 如何配置 TCP 服务的权限控制，我们首先需要将应用更新到 TCP 调用的版本。按照下面的步骤，部署 Bookinfo 应用示例，并且将 `ratings` 服务升级到 `v2` 版本，在该版本中会使用 TCP 调用后端 MongoDB 服务。

1. 部署 `v2` 版本的 `ratings` 服务，服务的 `ServiceAccount` 命名为 `bookinfo-ratings-v2`，有以下两种方式：

    * 如果集群已开启 sidecar 自动注入，使用以下命令创建 `ServiceAccount` 并且配置新版的 `ratings` 服务:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        {{< /text >}}

    * 集群未开启 sidecar 自动注入场景下，需要执行以下命令手动完成 sidecar 注入，并创建新版本 `ratings` 服务和`ServiceAccount`:

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@)
        {{< /text >}}

1. 创建 `DestinationRule` 配置:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    因为 `VirtualService` 的配置中 `subset` 项依赖 `DestinationRule` 配置，所以在 `DestinationRule` 完全生效前需要等待几秒钟再添加 `VirtualService` 。

1. 在 `DestinationRule` 完全生效后，更新 `reviews` 服务只使用 `v2` 版本的 `ratings` 服务:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    {{< /text >}}

1. 浏览位于 `http://$GATEWAY_URL/productpage` 的产品页面：

    在这一页面中会看到 **Book Reviews** 中出现的错误信息：**"Ratings service is currently unavailable."**。因为 `ratings` 服务的 `v2` 版本所依赖的 MongoDB 服务尚未部署。

1. 部署 MongoDB 服务：

    * 在**启用自动注入**的网格中部署 MongoDB 服务：

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
        {{< /text >}}

    * 在**没有启用自动注入**的网格中部署 MongoDB 服务：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@)
        {{< /text >}}

1. 再次浏览位于 `http://$GATEWAY_URL/productpage` 的产品页面。

1. 检查页面中的 **Book Reviews** 内容。

## 启用 Istio 的权限控制 {#enabling-Istio-authorization}

执行以下命令，为 MongoDB 服务启用权限控制：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-mongodb.yaml@
{{< /text >}}

打开 Bookinfo `productpage` 页面 (`http://$GATEWAY_URL/productpage`)， 可以看到：

* 页面左下角的 **Book Details** 中包含了书籍类型、页数以及出版商等信息。
* 页面右下角的 **Book Reviews** 显示了错误信息：**"Ratings service is currently unavailable"**。

因为 Istio 授权是`默认拒绝`的，所以需要配置合适的权限之后才能访问 MongoDB 服务。

{{< tip >}}
因为缓存和传播的关系，可能会有一些延迟。
{{< /tip >}}

## 增强 TCP 服务的访问控制 {#enforcing-access-control-on-tcp-service}

接下来配置服务级别访问控制，使用 Istio 授权机制允许 `ragings` v2 服务访问 MongoDB 服务。

执行以下命令，完成授权策略：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/mongodb-policy.yaml@
{{< /text >}}

配置完成后，策略会有以下效果：

* 创建一个命名为 `mongodb-viewer` 的角色，这个角色有权访问 MongoDB 服务的 `27017` 端口。

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: mongodb-viewer
      namespace: default
    spec:
      rules:
      - services: ["mongodb.default.svc.cluster.local"]
        constraints:
        - key: "destination.port"
          values: ["27017"]
    {{< /text >}}

* 创建一个命名为 `bind-mongodb-viewer` 角色绑定 `ServiceRoleBinding`，将 `mongodb-viewer` 角色分配给 `bookinfo-ratings-v2`.

    {{< text yaml >}}
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-mongodb-viewer
      namespace: default
    spec:
      subjects:
      - user: "cluster.local/ns/default/sa/bookinfo-ratings-v2"
      roleRef:
        kind: ServiceRole
        name: "mongodb-viewer"
    {{< /text >}}

用浏览器打开产品页面（`http://$GATEWAY_URL/productpage`）会看到：

* 页面左下角的 **Book Details** 中包含了书籍类型、页数以及出版商等信息。
* 页面右下角的 **Book Reviews** 显示了红色星星。

{{< tip >}}
由于缓存和传播开销可能会造成一定延迟。
{{< /tip >}}

## 清理 {#cleanup}

*   删除 Istio 权限策略配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/mongodb-policy.yaml@
    {{< /text >}}

    还可以删除所有的 `ServiceRole` 和 `ServiceRoleBinding` 对象：

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

*   禁用 Istio 权限控制：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-mongodb.yaml@
    {{< /text >}}
