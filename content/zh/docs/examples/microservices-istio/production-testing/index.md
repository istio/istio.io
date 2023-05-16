---
title: 生产测试
overview: 在生产环境中测试微服务的新版本。
weight: 40
owner: istio/wg-docs-maintainers
test: no
---

{{< boilerplate work-in-progress >}}

在生产环境中测试您的微服务！

## 测试单个微服务 {#testing-individual-microservices}

1. 从测试 pod 中向服务之一发起 HTTP 请求：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl http://ratings:9080/ratings/7
    {{< /text >}}

## 混乱测试 {#chaos-testing}

在生产环境中执行一些[混沌测试](http://www.boyter.org/2016/07/chaos-testing-engineering/)，
并查看您的应用程序如何反应。进行每次混乱的操作后，请访问应用程序的网页，查看是否有任何更改。
使用 `kubectl get pods` 检查 Pod 状态。

1. 在 `details` 服务的一个 Pod 中终止它。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pods -l app=details -o jsonpath='{.items[0].metadata.name}') -- pkill ruby
    {{< /text >}}

1. 检查 Pod 状态：

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   1          47m
    details-v1-6d86fd9949-mksv7     1/1     Running   0          47m
    details-v1-6d86fd9949-q8rrf     1/1     Running   0          48m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          47m
    productpage-v1-c9965499-nccwq   1/1     Running   0          47m
    productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          47m
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          47m
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          47m
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          47m
    sleep-88ddbcfdd-l9zq4           1/1     Running   0          47m
    {{< /text >}}

    请注意第一个 Pod 重启了一次。

1. 在 `details` 的所有 Pod 中终止它：

    {{< text bash >}}
    $ for pod in $(kubectl get pods -l app=details -o jsonpath='{.items[*].metadata.name}'); do echo terminating $pod; kubectl exec -it $pod -- pkill ruby; done
    {{< /text >}}

1. 检查应用的页面：

    {{< image width="80%"
        link="bookinfo-details-unavailable.png"
        caption="Bookinfo Web Application，详情不可用"
        >}}

    请注意详情部分显示的是错误信息而不是书籍详情。

1. 检查 Pod 状态：

    {{< text bash >}}
    $ kubectl get pods
    NAME                            READY   STATUS    RESTARTS   AGE
    details-v1-6d86fd9949-fr59p     1/1     Running   2          48m
    details-v1-6d86fd9949-mksv7     1/1     Running   1          48m
    details-v1-6d86fd9949-q8rrf     1/1     Running   1          49m
    productpage-v1-c9965499-hwhcn   1/1     Running   0          48m
    productpage-v1-c9965499-nccwq   1/1     Running   0          48m
    productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
    ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          48m
    ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          48m
    ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          49m
    reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          48m
    reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          49m
    reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          48m
    sleep-88ddbcfdd-l9zq4           1/1     Running   0          48m
    {{< /text >}}

    第一个 Pod 重启了两次，其它两个 `details` Pod 重启了一次。
    您可能会看到 `Error` 和 `CrashLoopBackOff` 状态，直到 Pod 变为 `Running` 状态。

1. 在终端中使用 Ctrl-C 停止正在运行的无限循环，以模拟流量。

在这两种情况下，应用程序都没有崩溃。
`details` 微服务中的崩溃并未导致其他微服务失败。
该行为表示您在这种情况下没有**级联失败**。
相反，您的服务会**逐渐降级**：尽管一个微服务崩溃了，该应用仍可以提供有用的功能。
它显示了有关书的评论和基本信息。

您已准备好[添加评论应用程序的新版本](/zh/docs/examples/microservices-istio/add-new-microservice-version)。
