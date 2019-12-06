---
title: TCP 流量转移
description: 展示如何将一个服务的 TCP 流量从旧版本迁移到新版本。
weight: 31
keywords: [traffic-management,tcp-traffic-shifting]
aliases:
    - /zh/docs/tasks/traffic-management/tcp-version-migration.html
---

本任务展示了如何逐步将 TCP 流量从微服务的一个版本迁移到另一个版本。例如，将 TCP 流量从旧版本迁移到新版本。

在 Istio 中，您可以通过配置一系列规则来实现此目标，这些规则按指定的百分比将流量路由到不同的服务。在此任务
中，将先把 100% 的 TCP 流量分配到 `tcp-echo:v1`，然后，再通过配置 Istio 路由权重把 20% 的 TCP 流量分
配到 `tcp-echo:v2`。

## 开始之前{#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

* 回顾[流量管理](/zh/docs/concepts/traffic-management) 概念文档。

## 应用基于权重的 TCP 路由{#apply-weight-based-tcp-routing}

1.  首先，部署微服务 `tcp-echo` 的 `v1` 版本。

    * 如果使用[手动注入 sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#manual-sidecar-injection)，请使用下面命令：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/tcp-echo/tcp-echo-services.yaml@)
        {{< /text >}}

        [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject) 命令用于在创建 deployments 之前
        修改 `tcp-echo-services.yaml` 文件。

    * 如果您使用的是启用了[自动注入 sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) 的集群，可以将 `default` namespace 标记为 `istio-injection=enabled` 。

        {{< text bash >}}
        $ kubectl label namespace default istio-injection=enabled
        {{< /text >}}

        然后，只需使用 `kubectl` 部署服务即可。

        {{< text bash >}}
        $ kubectl apply -f @samples/tcp-echo/tcp-echo-services.yaml@
        {{< /text >}}

1.  接下来, 将目标为微服务 `tcp-echo` 的 TCP 流量全部路由到 `v1` 版本。

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-all-v1.yaml@
    {{< /text >}}

1.  确认 `tcp-echo` 服务已启动并开始运行。

    下面的 `$INGRESS_HOST` 变量是 ingress 的外部 IP 地址，可参考 [Ingress Gateways](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports) 文档。要获取 `$INGRESS_PORT` 变量的值，请使用以下命令。

    {{< text bash >}}
    $ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
    {{< /text >}}

    向微服务 `tcp-echo` 发送一些 TCP 流量。

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

    {{< warning >}}
    可能需要通过 `sudo` 执行 `docker` 命令，这取决于您的 Docker 安装。
    {{< /warning >}}

    您应该注意到，所有时间戳的前缀都是 _one_ ，这意味着所有流量都被路由到了 `tcp-echo` 服务的 `v1` 版本。

1.  使用以下命令将 20% 的流量从 `tcp-echo:v1` 转移到 `tcp-echo:v2`：

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-20-v2.yaml@
    {{< /text >}}

    等待几秒钟，以使新规则在集群中传播和生效。

1.  确认规则配置已替换完成：

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

1.  向 `tcp-echo` 服务发送更多 TCP 流量。

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

    {{< warning >}}
    可能需要通过 `sudo` 执行 `docker` 命令，这取决于您的 Docker 安装。
    {{< /warning >}}

    现在应该发现，有大约 20% 的流量时间戳前缀是 _two_ ，这意味着有 80% 的 TCP 流量路由到了 `tcp-echo` 服务的
     `v1` 版本，与此同时有 20% 流量路由到了 `v2` 版本。

## 理解原理{#understanding-what-happened}

这个任务中，使用 Istio 路由权重特性将 `tcp-echo` 服务的 TCP 流量从旧版本迁移到了新版本。请注意，这与使用容
器编排平台的 deployment 进行版本迁移非常不同，后者（容器编排平台）是通过对特定组别的实例进行伸缩实现的。

在 Istio 中可以对 `tcp-echo` 服务的两个版本进行独立扩容和缩容，这个过程不会影响服务版本之间的流量分配。

有关不同版本间流量管理及自动伸缩的更多信息，请查看博客文章[使用 Istio 进行金丝雀部署](/zh/blog/2017/0.1-canary/)。

## 清理{#cleanup}

1. 删除 `tcp-echo` 应用程序和路由规则。

    {{< text bash >}}
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-all-v1.yaml@
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-services.yaml@
    {{< /text >}}
