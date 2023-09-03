---
title: 怎样查看 Istio 的请求都发生了什么？
weight: 80
---

您可以启用 [tracing](/zh/docs/tasks/observability/distributed-tracing/)
以确定 Istio 中的请求是怎样流动的。

另外，您还可以使用如下命令以了解网格中的更多状态信息：

* [`istioctl proxy-config`](/zh/docs/reference/commands/istioctl/#istioctl-proxy-config)：获取 Kubernetes 运行期间的 proxy 配置信息：

    {{< text plain >}}
    # 在指定的 pod 中 Envoy 实例的启动（bootstrap）配置信息。
    $ istioctl proxy-config bootstrap productpage-v1-bb8d5cbc7-k7qbm

    # 在指定的 pod 中 Envoy 实例的集群（cluster）配置信息。
    $ istioctl proxy-config cluster productpage-v1-bb8d5cbc7-k7qbm

    # 在指定的 pod 中 Envoy 实例的监听器（listener）配置信息。
    $ istioctl proxy-config listener productpage-v1-bb8d5cbc7-k7qbm

    # 在指定的 pod 中 Envoy 实例的路由（route）配置信息。
    $ istioctl proxy-config route productpage-v1-bb8d5cbc7-k7qbm

    # 在指定的 pod 中 Envoy 实例的端点（endpoint）配置信息。
    $ istioctl proxy-config endpoints productpage-v1-bb8d5cbc7-k7qbm

    # 查看更多 proxy-config 的用法可用如下命令
    $ istioctl proxy-config --help
    {{< /text >}}

* `kubectl get`：通过路由配置获取网格中不同资源的信息：

    {{< text plain >}}
    # 列出所有的 virtual services
    $ kubectl get virtualservices
    {{< /text >}}
