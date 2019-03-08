---
title: TCP 服务的访问控制
description: 展示如何为 TCP 服务设置基于角色的访问控制。
weight: 40
keywords: [security,access-control,rbac,tcp,authorization]
---

本任务涵盖了在服务网格中为 TCP 服务设置 Istio RBAC 所需的可能活动。可以阅读[安全概念文档](/zh/docs/concepts/security/#授权)中的相关内容。

## 开始之前

本文任务假设：

* 阅读 [Istio 中的授权和鉴权](/zh/docs/concepts/security/#授权)。
* 按照[快速开始](/zh/docs/setup/kubernetes/install/kubernetes/)一文的指导，在 Kubernetes 中安装**启用了认证功能**的 Istio。
* 执行[安装步骤](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)时启用双向 TLS 认证

任务中所执行的命令还假设 Bookinfo 示例应用部署在 `default` 命名空间中。如果使用的是其它命名空间，在命令中需要加入 `-n` 参数。

## 安装和配置一个 TCP 服务

缺省情况下的 [Bookinfo](/zh/docs/examples/bookinfo/) 应用仅包含 HTTP 服务。为了展示 Istio 处理 TCP 服务访问控制的能力，就需要进行更新，提供一个用于测试的 TCP 服务。执行如下过程对该应用进行更新，替换 `ratings` 服务为 `v2` 版本，这个版本会使用 TCP 协议和 MongoDB 进行通信。

### 先决条件

部署 [Bookinfo](/zh/docs/examples/bookinfo/) 应用。

部署完成之后，在网址 `http://$GATEWAY_URL/productpage` 浏览产品页面，在这个页面中会看到：

* 页面左下角的 **Book Details** 中包含了书籍类型、页数以及出版商等信息。
* 页面右下角是 **Book Reviews** 内容。

刷新页面时会看到应用用轮询方式展示不同的评价信息，红星、黑星或者不显示。

### 安装使用特定 `ServiceAccount` 的服务

1. 安装 `ratings` 服务的 `v2` 版本，并使用 `bookinfo-ratings-v2` 的 `ServiceAccount`：

    Istio 在网格中用加密的方式来验证 `ServiceAccount`。为了给不同服务分配不同的权限，就需要给 `v2` 服务分配一个单独的 `bookinfo-ratings-v2` 服务账号；其它服务继续使用 `default`。

    * 创建新的 `ServiceAccount` 并在**启用自动注入**的网格中部署新版本的服务：

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/ratings-v2-add-serviceaccount.yaml@
        {{< /text >}}

    * 创建新的 `ServiceAccount` 并在**没有启用自动注入**的网格中部署新版本的服务：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/rbac/ratings-v2-add-serviceaccount.yaml@)
        {{< /text >}}

### 配置应用使用新版本的服务

Bookinfo 应用可以使用多个版本的服务。Istio 中可以为每个版本定义 `subset`；另外还要为每个 `subset` 定义负载均衡策略。要完成这些定义，就需要创建相应的目标规则：

1. 创建目标规则：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
    {{< /text >}}

    由于 `VirtualService` 中会引用目标规则中的 `subset`，所以在创建虚拟服务之前，应该稍等一段时间，以便 Istio 完成目标规则的传播过程。

1. 目标规则完成传播后，更新 `reviews` 服务，要求它使用 `ratings` 服务的 `v2` 版本：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
    {{< /text >}}

1. 浏览位于 `http://$GATEWAY_URL/productpage` 的产品页面：

    在这一页面中会看到 **Book Reviews** 中出现的错误信息：**"Ratings service is currently unavailable."**。出现这一信息的原因是 `ratings` 服务的 `v2` 版本所依赖的 MongoDB 服务尚未部署。

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

## 启用 Istio 的访问控制

运行如下命令，为 MongoDB 服务启用访问控制：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-mongodb.yaml@
{{< /text >}}

用浏览器打开 `http://$GATEWAY_URL/productpage`，会看到：

* 页面左下角的 **Book Details** 中包含了书籍类型、页数以及出版商等信息。
* 页面右下角的 **Book Reviews** 显示了错误信息：**"Ratings service is currently unavailable"**。

这是因为 Istio 授权是`默认拒绝`的，也就是说必须显式的进行合适的授权之后才能访问 MongoDB 服务。

{{< tip >}}
因为缓存和传播的关系，可能需要一些等待时间。
{{< /tip >}}

## 执行服务级的访问控制

接下来使用 Istio 授权机制来让 `ratings:v2` 服务能够访问 MongoDB 服务。

1. 运行下列命令，完成授权策略：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/rbac/mongodb-policy.yaml@
    {{< /text >}}

    这条命令会执行如下动作：

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

    * 创建一个 `ServiceRoleBinding` 对象，命名为 `bind-mongodb-viewer`，这个对象的用意是将 `mongodb-viewer` 角色分配给 `bookinfo-ratings-v2`。

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
    缓存和传播过程可能会造成一定延迟。
    {{< /tip >}}

1. 要确认 MongoDB 服务职能被 `bookinfo-ratings-v2` 服务账号访问：

    用下面的命令重新部署 `ratings:v2` 服务，并使用 `default` 服务账号运行该服务：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/ratings-v2-add-serviceaccount.yaml@
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
    {{< /text >}}

    用浏览器打开产品页面（`http://$GATEWAY_URL/productpage`）会看到：

    * 页面左下角的 **Book Details** 中包含了书籍类型、页数以及出版商等信息。
    * 页面右下角的 **Book Reviews** 显示了错误信息：**"Ratings service is currently unavailable"**。

    {{< tip >}}
    缓存和传播过程可能会造成一定延迟。
    {{< /tip >}}

## 清理

* 删除 Istio 访问控制策略配置：

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/mongodb-policy.yaml@
    {{< /text >}}

    还可以删除所有的 `ServiceRole` 和 `ServiceRoleBinding` 对象：

    {{< text bash >}}
    $ kubectl delete servicerole --all
    $ kubectl delete servicerolebinding --all
    {{< /text >}}

* 禁用 Istio 访问控制

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/platform/kube/rbac/rbac-config-on-mongodb.yaml@
    {{< /text >}}
