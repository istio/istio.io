---
title: 在 productpage 启用 Istio
overview: 在一个微服务上部署 Istio 控制平面并启用 Istio。
weight: 60

owner: istio/wg-docs-maintainers
test: no
---

正如您在上一个模块所见，Istio 通过增强 Kubernetes 功能，让您能更高效的操作微服务。

在这个模块中，您可以在 `productpage` 微服务中，启用 Istio。
这个应用的其他部分会继续照原样运行。注意您可以一个微服务一个微服务的逐步启用 Istio。
启用 Istio 在微服务中是无侵入的，您不用修改微服务代码或者破坏您的应用，
它也能够持续运行并且为用户请求服务。

1. 应用默认目标规则：

    {{< text bash >}}
    $ kubectl apply -f {{< github_file >}}/samples/bookinfo/networking/destination-rule-all.yaml
    {{< /text >}}

1. 重新部署 `productpage` 微服务，启用 Istio：

    {{< tip >}}
    本教程为了教学目的将会逐步演示如何手动注入 Sidecar 启用 Istio，
    但是[自动注入 Sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
    更加便捷。
    {{< /tip >}}

    {{< text bash >}}
    $ curl -s {{< github_file >}}/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | sed 's/replicas: 1/replicas: 3/g' | kubectl apply -l app=productpage,version=v1 -f -
    deployment.apps/productpage-v1 configured
    {{< /text >}}

1. 进入应用的网页去验证应用是否在工作。Istio 是在没有改变原应用代码的情况下添加的。

1. 检查 `productpage` 的 Pod 并且查看每个副本的两个容器。第一个容器是微服务本身的，
   第二个是连接到它的 Sidecar 代理：

    {{< text bash >}}
    $ kubectl get pods
    details-v1-68868454f5-8nbjv       1/1       Running   0          7h
    details-v1-68868454f5-nmngq       1/1       Running   0          7h
    details-v1-68868454f5-zmj7j       1/1       Running   0          7h
    productpage-v1-6dcdf77948-6tcbf   2/2       Running   0          7h
    productpage-v1-6dcdf77948-t9t97   2/2       Running   0          7h
    productpage-v1-6dcdf77948-tjq5d   2/2       Running   0          7h
    ratings-v1-76f4c9765f-khlvv       1/1       Running   0          7h
    ratings-v1-76f4c9765f-ntvkx       1/1       Running   0          7h
    ratings-v1-76f4c9765f-zd5mp       1/1       Running   0          7h
    reviews-v2-56f6855586-cnrjp       1/1       Running   0          7h
    reviews-v2-56f6855586-lxc49       1/1       Running   0          7h
    reviews-v2-56f6855586-qh84k       1/1       Running   0          7h
    sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
    {{< /text >}}

1. Kubernetes 采取无侵入的和逐步的[滚动更新](https://kubernetes.io/zh-cn/docs/tutorials/kubernetes-basics/update/update-intro/)
   方式用启用 Istio 的 Pod 替换了原有的 Pod。Kubernetes 只有在新的 Pod
   开始运行的时候才会终止老的 Pod， 它透明地将流量一个一个地切换到新的 Pod 上。
   也就是说，它不会在声明一个新的 Pod 之前结束一个或者以上的 Pod。
   这些操作都是为了防止破坏您的应用，因此在注入 Istio 的过程中应用能够持续工作。

1. 检查 `productpage` Istio Sidecar 的日志：

    {{< text bash >}}
    $ kubectl logs -l app=productpage -c istio-proxy | grep GET
    ...
    [2019-02-15T09:06:04.079Z] "GET /details/0 HTTP/1.1" 200 - 0 178 5 3 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "details:9080" "172.30.230.51:9080" outbound|9080||details.tutorial.svc.cluster.local - 172.21.109.216:9080 172.30.146.104:58698 -
    [2019-02-15T09:06:04.088Z] "GET /reviews/0 HTTP/1.1" 200 - 0 379 22 22 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "reviews:9080" "172.30.230.27:9080" outbound|9080||reviews.tutorial.svc.cluster.local - 172.21.185.48:9080 172.30.146.104:41442 -
    [2019-02-15T09:06:04.053Z] "GET /productpage HTTP/1.1" 200 - 0 5723 90 83 "10.127.220.66" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "tutorial.bookinfo.com" "127.0.0.1:9080" inbound|9080|http|productpage.tutorial.svc.cluster.local - 172.30.146.104:9080 10.127.220.66:0 -
    {{< /text >}}

1. 输出命名空间，您将会在 Istio 仪表盘中通过它来识别您的微服务：

    {{< text bash >}}
    $ echo $(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
    tutorial
    {{< /text >}}

1. 检查 Istio 仪表盘，通过自定义的 URL，它配置在[您之前配置](/zh/docs/examples/microservices-istio/bookinfo-kubernetes/#update-your-etc-hosts-configuration-file)的
   `/etc/hosts` 文件中：

    {{< text plain >}}
    http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
    {{< /text >}}

    在左上角的下拉菜单中，选择 **Istio Mesh Dashboard**。

    {{< image width="80%"
        link="dashboard-select-dashboard.png"
        caption="在左上角的下拉菜单中，选择 Istio Mesh Dashboard"
        >}}

    注意命名空间中的 `productpage` 服务，它的命名应该是 `productpage.<your namespace>.svc.cluster.local`。

    {{< image width="80%"
        link="dashboard-mesh.png"
        caption="Istio Mesh Dashboard"
        >}}

1. 在 Istio Mesh 仪表盘中，在 `Service` 列下，单击 `productpage` 服务。

    {{< image width="80%"
        link="dashboard-service-select-productpage.png"
        caption="Istio Service Dashboard, `productpage` selected"
        >}}

    向下滚动到 **Service Workloads** 部分。观察到仪表盘图表已经更新。

    {{< image width="80%"
        link="dashboard-service.png"
        caption="Istio Service Dashboard"
        >}}

这是在一个微服务中应用 Istio 的直接优点，您可以收到进出微服务的流量日志，
包括时间、HTTP 方法、路径和响应代码。您可以用 Istio 仪表盘监控您的微服务。

在下一个模块，您将会学习到关于 Istio 可以为您的应用提供的功能。当 Istio
的功能对微服务是有益的时候，您将学习如何在整个应用程序上使用 Istio 来实现其全部潜力。

您已经准备好[所有微服务上启用 Istio](/zh/docs/examples/microservices-istio/enable-istio-all-microservices)。
