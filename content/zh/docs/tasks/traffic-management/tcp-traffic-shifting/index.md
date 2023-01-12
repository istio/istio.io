---
title: TCP 流量转移
description: 展示如何将一个服务的 TCP 流量从旧版本迁移到新版本。
weight: 31
keywords: [traffic-management,tcp-traffic-shifting]
aliases:
    - /zh/docs/tasks/traffic-management/tcp-version-migration.html
owner: istio/wg-networking-maintainers
test: yes
---

本任务展示了如何将 TCP 流量从微服务的一个版本迁移到另一个版本。

一个常见的用例是将 TCP 流量从微服务的旧版本逐步迁移到新版本。
在 Istio 中，您可以通过配置一系列路由规则来实现此目标，这些规则将一定比例的 TCP 流量从一个目的地重定向到另一个目的地。

在此任务中，您将会把 100% 的 TCP 流量分配到 `tcp-echo:v1`。
接着，再通过配置 Istio 路由权重把 20% 的 TCP 流量分配到 `tcp-echo:v2`。

## 开始之前{#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

* 查看[流量管理](/zh/docs/concepts/traffic-management)概念文档。

## 设置测试环境{#set-up-the-test-environment}

1.  首先，创建一个命名空间用于测试 TCP 流量迁移，并将其标记为使用自动注入 Sidecar 方式。

    {{< text bash >}}
    $ kubectl create namespace istio-io-tcp-traffic-shifting
    $ kubectl label namespace istio-io-tcp-traffic-shifting istio-injection=enabled
    {{< /text >}}

1. 部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用程序，作为发送请求的测试源。

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

1. 部署 `tcp-echo` 微服务的 `v1` 和 `v2` 版本。

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-services.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

1. 根据[确定 Ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)中的说明，定义 `TCP_INGRESS_PORT` 和 `INGRESS_HOST` 环境变量。

## 应用基于权重的 TCP 路由{#apply-weight-based-TCP-routing}

1. 将所有 TCP 流量路由到微服务 `tcp-echo` 的 `v1` 版本。

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

1. 通过从 `sleep` 客户端发送一些 TCP 流量，确认 `tcp-echo` Service 已经启动并运行。

    {{< text bash >}}
    $ for i in {1..20}; do \
    kubectl exec "$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})" \
    -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
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
    ...
    {{< /text >}}

    请注意，所有时间戳都有一个前缀 “_one_”，说明所有流量都被路由到 `tcp-echo` Service 的 `v1` 版本。

1. 通过以下命令，将 20% 流量从 `tcp-echo:v1` 迁移到 `tcp-echo:v2`：

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-20-v2.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

    等待几秒钟，让新规则在集群中生效。

1. 确认规则已经被替换：

    {{< text bash yaml >}}
    $ kubectl get virtualservice tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
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

1. 发送更多 TCP 流量到微服务 `tcp-echo`。

    {{< text bash >}}
    $ for i in {1..20}; do \
    kubectl exec "$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})" \
    -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
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
    ...
    {{< /text >}}

    请注意，大约 20% 的时间戳带有前缀 “_two_”，说明 80% 的 TCP 流量被路由到 `tcp-echo` Service 的 `v1` 版本，而 20% 的流量被路由到 `v2`版本。

## 理解原理{#understanding-what-happened}

这个任务中，使用 Istio 路由权重特性将 `tcp-echo` 服务的 TCP 流量从旧版本迁移到了新版本。请注意，这与使用容器编排平台的部署功能进行版本迁移完全不同，后者（容器编排平台）使用了实例扩容来管理流量。

在 Istio 中，可以对 `tcp-echo` 服务的两个版本进行独立扩容和缩容，这个过程不会影响两个服务版本之间的流量分配。

有关不同版本间流量管理及自动扩缩的更多信息，请查看[使用 Istio 进行金丝雀部署](/zh/blog/2017/0.1-canary/)这篇博文。

## 清理{#cleanup}

1. 删除 `sleep` 示例、`tcp-echo` 应用程序和路由规则：

    {{< text bash >}}
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-services.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete namespace istio-io-tcp-traffic-shifting
    {{< /text >}}
