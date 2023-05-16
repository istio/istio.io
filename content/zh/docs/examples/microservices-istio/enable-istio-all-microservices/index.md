---
title: 在所有微服务中启用 Istio
overview: 在您的整个应用中启用 Istio
weight: 70

owner: istio/wg-docs-maintainers
test: no
---

之前，您在 `productpage` 微服务中启用了 Istio。为了在微服务中获取更多的
Istio 功能，您可以逐步的在微服务中启用 Istio。
本教程的教学目的是让您能够在其余所有微服务上一步到位的启用 Istio。

1.  为了教学目的，将微服务的部署规模缩小为1：

    {{< text bash >}}
    $ kubectl scale deployments --all --replicas 1
    {{< /text >}}

1.  重新部署启用 Istio 的 Bookinfo 应用。`productpage`
    服务不会被重新部署，因为它被 Istio 注入，并且它的 Pod 不会发生改变。
    在这您可以在单个副本的微服务集群中启用 Istio。

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

1.  多次访问应用的网页。需要注意的是 Istio 的添加是无侵入的，
    原有的应用不会发生变化。它是在运行过程中添加的，不需要撤销和重新部署整个应用程序。

1.  检查应用程序 Pod，并验证现在每个 Pod 的两个容器。
    一个容器是微服务本身，另一个是连接到它的 Sidecar 代理。

    {{< text bash >}}
    $ kubectl get pods
    details-v1-58c68b9ff-kz9lf        2/2       Running   0          2m
    productpage-v1-59b4f9f8d5-d4prx   2/2       Running   0          2m
    ratings-v1-b7b7fbbc9-sggxf        2/2       Running   0          2m
    reviews-v2-dfbcf859c-27dvk        2/2       Running   0          2m
    sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
    {{< /text >}}

1.  通过自定义的 URL 检查 Istio 仪表盘，
    它配置在您[之前配置](/zh/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)的
    `/etc/hosts` 文件中：

    {{< text plain >}}
    http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
    {{< /text >}}

1.  在左上角的下拉菜单中，选择 **Istio Mesh Dashboard**。
    注意现在您的命名空间的所有服务都会出现在服务列表中。

    {{< image width="80%"
        link="dashboard-mesh-all.png"
        caption="Istio Mesh Dashboard"
        >}}

1.  在 **Istio Service Dashboard** 仪表盘中检查其他微服务，如 `ratings` 等：

    {{< image width="80%"
        link="dashboard-ratings.png"
        caption="Istio Service Dashboard"
        >}}

1.  通过 [Kiali](https://www.kiali.io) 控住台的可视化界面来查看您的应用程序的拓扑结构，
    它不是 Istio 的一部分，而是作为 `demo` 配置安装的一部分。通过自定义的 URL 进入仪表盘，
    它配置在您[之前配置](/zh/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)
    的 `/etc/hosts` 文件中：

    {{< text plain >}}
    http://my-kiali.io/kiali/console
    {{< /text >}}

    如果您的 Kiali 是通过 [入门指南](/zh/docs/setup/getting-started/) 安装的，Kiali 控制台用户名是 `admin`，密码是 `admin`。

1.  点击 `Graph` 按钮，并且在顶部角落的 **Namespace**
    下拉菜单中选择您的命名空间。然后在 **Display** 下拉菜单中选中
    **Traffic Animation** 复选框，就可以看到一些很酷的流量动画。

    {{< image width="80%"
        link="kiali-display-menu.png"
        caption="Kiali Graph Tab, display drop-down menu"
        >}}

1. 尝试在 **Edge Labels** 下拉菜单中选择不同的选项。
   将鼠标悬停在图的节点和边上。注意右边的流量指标。

    {{< image width="80%"
        link="kiali-edge-labels-menu.png"
        caption="Kiali Graph Tab, edge labels drop-down menu"
        >}}

    {{< image width="80%"
        link="kiali-initial.png"
        caption="Kiali Graph Tab"
        >}}

您已经准备好[配置 Istio Ingress Gateway](/zh/docs/examples/microservices-istio/istio-ingress-gateway)。
