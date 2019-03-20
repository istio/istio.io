---
title: TCP 流量转移
description: 展示如何将一个 TCP 服务的流量从老版本迁移到新版本。
weight: 26
keywords: [traffic-management,tcp-traffic-shifting]
---

本任务展示了如何优雅的将微服务中的 TCP 流量从一个版本迁移到另一个版本。例如将 TCP 流量从旧版本迁移到一个新版本。这是一个常见的场景。在 Istio 中可以通过定义一组规则，将 TCP 流量在不同服务之间进行分配。在这一任务中，首先把 100% 的 TCP 流量发送到 `tcp-echo:v1`；下一步就是使用 Istio 的路由分配能力，把 20% 的流量分配到 `tcp-echo:v2` 服务之中。

## 开始之前 {#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

* 熟悉[流量管理](/zh/docs/concepts/traffic-management)中的相关概念。

## 应用基于权重的 TCP 路由 {#apply-weight-based-tcp-routing}

1. 第一个步骤是部署 `tcp-echo` 微服务的 `v1` 版本。

    * 如果使用的是[手工 Sidecar 注入](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#手工注入-sidecar)，使用如下命令：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/tcp-echo/tcp-echo-services.yaml@)
        {{< /text >}}

    `istioctl kube-inject` 的作用如[文档](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject)所言，是在提交 `tcp-echo-services.yaml` 之前进行修改。

    * 如果使用的是一个启用了 [Sidecar 自动注入](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#sidecar-的自动注入)的集群，可以给 `default` 命名空间打上 `istio-injection=enabled` 标签：

        {{< text bash >}}
        $ kubectl label namespace default istio-injection=enabled
        {{< /text >}}

        然后简单的使用 `kubectl` 进行服务部署即可：

        {{< text bash >}}
        $ kubectl apply -f @samples/tcp-echo/tcp-echo-services.yaml@
        {{< /text >}}

1. 下一步，把所有目标是 `tcp-echo` 微服务的 TCP 流量路由到 `v1` 版本：

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-all-v1.yaml@
    {{< /text >}}

1. 确认 `tcp-echo` 服务已经启动并开始运行。

    下面的 `$INGRESS_HOST` 变量中保存了 Ingress 的外部 IP 地址（[Bookinfo](/zh/docs/examples/bookinfo/#确定-ingress-的-ip-和端口) 文档中描写了这一部分的相关内容）。可以使用下面的命令来获取 `$INGRESS_PORT` 的值：

    {{< text bash >}}
    $ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
    {{< /text >}}

    向 `tcp-echo` 微服务发送一些 TCP 流量：

    {{< text bash >}}
    $ for i in {1..10}; do \
    docker run -e INGRESS_HOST=$INGRESS_HOST -e INGRESS_PORT=$INGRESS_PORT -it --rm busybox sh -c "(date; sleep 1) | nc $INGRESS_HOST $INGRESS_PORT"; \
    done
    one Mon Nov 12 23:24:57 UTC 2018
    one Mon Nov 12 23:25:00 UTC 2018
    one Mon Nov 12 23:25:02 UTC 2018
    one Mon Nov 12 23:25:05 UTC 2018
    one Mon Nov 12 23:25:07 UTC 2018
    one Mon Nov 12 23:25:10 UTC 2018
    one Mon Nov 12 23:25:12 UTC 2018
    one Mon Nov 12 23:25:15 UTC 2018
    one Mon Nov 12 23:25:17 UTC 2018
    one Mon Nov 12 23:25:19 UTC 2018
    {{< /text >}}

    不难发现，所有的时间戳都有一个 `one` 前缀，这代表所有访问 `tcp-echo` 服务的流量都被路由到了 `v1` 版本。

1. 用下面的命令把 20% 的流量从 `tcp-echo:v1` 转移到 `tcp-echo:v2`：

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-20-v2.yaml@
    {{< /text >}}

    需要一定时间完成新规则的传播和生效。

1. 确认该规则已经完成替换：

    {{< text bash yaml >}}
    $ kubectl get virtualservice tcp-echo -o yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: tcp-echo
      ...
    spec:
      ...
      tcp:
      - match:
        - port: 31400
        route:
        - destination:
            host: tcp-echo
            port:
              number: 9000
            subset: v1
          weight: 80
        - destination:
            host: tcp-echo
            port:
              number: 9000
            subset: v2
          weight: 20
    {{< /text >}}

1. 向 `tcp-echo` 微服务发送更多 TCP 流量：

    {{< text bash >}}
    $ for i in {1..10}; do \
    docker run -e INGRESS_HOST=$INGRESS_HOST -e INGRESS_PORT=$INGRESS_PORT -it --rm busybox sh -c "(date; sleep 1) | nc $INGRESS_HOST $INGRESS_PORT"; \
    done
    one Mon Nov 12 23:38:45 UTC 2018
    two Mon Nov 12 23:38:47 UTC 2018
    one Mon Nov 12 23:38:50 UTC 2018
    one Mon Nov 12 23:38:52 UTC 2018
    one Mon Nov 12 23:38:55 UTC 2018
    two Mon Nov 12 23:38:57 UTC 2018
    one Mon Nov 12 23:39:00 UTC 2018
    one Mon Nov 12 23:39:02 UTC 2018
    one Mon Nov 12 23:39:05 UTC 2018
    one Mon Nov 12 23:39:07 UTC 2018
    {{< /text >}}

    现在应该会看到，输出内容中有 20% 的时间戳前缀为 `two`，这意味着 80% 的流量被路由到 `tcp-echo:v1`，其余 20% 流量被路由到了 `v2`。

## 理解原理 {#understanding-what-happened}

这个任务里，用 Istio 的权重路由功能，把一部分访问 `tcp-echo` 服务的 TCP 流量被从旧版本迁移到了新版本。容器编排平台中的版本迁移使用的是对特定组别的实例进行伸缩来完成对流量的控制的，两种迁移方式显然大相径庭。

在 Istio 中可以对两个版本的 `tcp-echo` 服务进行独立的扩缩容，伸缩过程中不会对流量的分配结果造成影响，可以阅读博客：[使用 Istio 进行金丝雀部署](/zh/blog/2017/0.1-canary/)，进一步了解相关内容。

## 清理 {#clean-up}

1. 删除 `tcp-echo` 应用和路由规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-all-v1.yaml@
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-services.yaml@
    {{< /text >}}
