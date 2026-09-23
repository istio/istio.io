---
title: 在所有微服务上启用 Istio
overview: 在您的整个应用上启用 Istio。
weight: 70

owner: istio/wg-docs-maintainers
test: no
---

在上一节，您在单个名为 `productpage` 的微服务上启用了 Istio。
您还可以逐渐在更多微服务中启用 Istio，为更多微服务增加 Istio 功能。
本教程的教学目的是让您能够在其余所有微服务上一步到位地启用 Istio。

1.  为了达成这个教学目的，先将微服务的部署规模缩小为 1：

    {{< text bash >}}
    $ kubectl scale deployments --all --replicas 1
    {{< /text >}}

1.  重新部署启用 Istio 的 Bookinfo 应用。`productpage`
    服务不会被重新部署，因为此服务已注入 Istio，并且无需变更此服务的 Pod。
    此时您可以在单个副本的微服务集群中启用 Istio。

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | kubectl apply -l app!=reviews -f -
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | kubectl apply -l app=reviews,version=v2 -f -
    service/details unchanged
    serviceaccount/bookinfo-details unchanged
    deployment.apps/details-v1 configured
    service/ratings unchanged
    serviceaccount/bookinfo-ratings unchanged
    deployment.apps/ratings-v1 configured
    serviceaccount/bookinfo-reviews unchanged
    service/productpage unchanged
    serviceaccount/bookinfo-productpage unchanged
    deployment.apps/productpage-v1 configured
    deployment.apps/reviews-v2 configured
    {{< /text >}}

1.  多次访问应用的网页。需要注意的是，Istio 的添加是**无侵入的**，
    原有的应用不会发生变化。Istio 是在应用的运行过程中被添加的，不需要撤销部署和重新部署整个应用。

1.  检查应用 Pod，并验证现在每个 Pod 有两个容器。
    一个容器是微服务本身，另一个是附加在微服务上的 Sidecar 代理：

    {{< text bash >}}
    $ kubectl get pods
    details-v1-58c68b9ff-kz9lf        2/2       Running   0          2m
    productpage-v1-59b4f9f8d5-d4prx   2/2       Running   0          2m
    ratings-v1-b7b7fbbc9-sggxf        2/2       Running   0          2m
    reviews-v2-dfbcf859c-27dvk        2/2       Running   0          2m
    curl-88ddbcfdd-cc85s              1/1       Running   0          7h
    {{< /text >}}

1.  通过您[之前](/zh/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)在
    `/etc/hosts` 文件中配置的自定义 URL 来访问 Istio 仪表盘：

    {{< text plain >}}
    http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
    {{< /text >}}

1.  在左上角的下拉菜单中，选择 **Istio Mesh Dashboard**。
    注意现在您的命名空间的所有服务都会出现在服务列表中。

    {{< image width="80%"
        link="dashboard-mesh-all.png"
        caption="Istio Mesh Dashboard"
        >}}

1.  在 **Istio Service Dashboard** 仪表盘中检查其他微服务，如 `ratings`：

    {{< image width="80%"
        link="dashboard-ratings.png"
        caption="Istio Service Dashboard"
        >}}

1.  通过 [Kiali](https://www.kiali.io) 控制台的可视化界面来查看您的应用的拓扑结构。
    这个控制台不是 Istio 的一部分，而是作为 `demo` 配置安装的。
    通过您[之前](/zh/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)在
    `/etc/hosts` 文件中配置的自定义 URL 来访问此仪表盘：

    {{< text plain >}}
    http://my-kiali.io/kiali/console
    {{< /text >}}

    如果您的 Kiali 是通过[入门指南](/zh/docs/setup/getting-started/)安装的，
    Kiali 控制台用户名是 `admin`，密码是 `admin`。

1.  在左上角点击 `Graph` 页签，并在 **Namespace**
    下拉菜单中选择您的命名空间。然后在 **Display** 下拉菜单中勾选
    **Traffic Animation** 复选框，就可以看到一些很酷的流量动画。

    {{< image width="80%"
        link="kiali-display-menu.png"
        caption="Kiali Graph 页签和 Display 下拉菜单"
        >}}

1. 尝试在 **Edge Labels** 下拉菜单中选择不同的菜单项。
   可以将鼠标悬停在图表的节点和边框上。注意右侧的流量指标。

    {{< image width="80%"
        link="kiali-edge-labels-menu.png"
        caption="Kiali Graph 页签和 edge labels 下拉菜单"
        >}}

    {{< image width="80%"
        link="kiali-initial.png"
        caption="Kiali Graph 页签"
        >}}

您现在可以去[配置 Istio Ingress Gateway](/zh/docs/examples/microservices-istio/istio-ingress-gateway) 了。
