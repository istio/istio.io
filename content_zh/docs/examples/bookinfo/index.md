---
title: Bookinfo 应用
description: 部署一个用于演示多种 Istio 特性的应用，由四个单独的微服务构成。
weight: 10
aliases:
    - /docs/samples/bookinfo.html
    - /docs/guides/bookinfo/index.html
---

部署一个样例应用，它由四个单独的微服务构成，用来演示多种 Istio 特性。这个应用模仿在线书店的一个分类，显示一本书的信息。页面上会显示一本书的描述，书籍的细节（ISBN、页数等），以及关于这本书的一些评论。

Bookinfo 应用分为四个单独的微服务：

* `productpage` ：`productpage` 微服务会调用 `details` 和 `reviews` 两个微服务，用来生成页面。
* `details` ：这个微服务包含了书籍的信息。
* `reviews` ：这个微服务包含了书籍相关的评论。它还会调用 `ratings` 微服务。
* `ratings` ：`ratings` 微服务中包含了由书籍评价组成的评级信息。

`reviews` 微服务有 3 个版本：

* v1 版本不会调用 `ratings` 服务。
* v2 版本会调用 `ratings` 服务，并使用 1 到 5 个黑色星形图标来显示评分信息。
* v3 版本会调用 `ratings` 服务，并使用 1 到 5 个红色星形图标来显示评分信息。

下图展示了这个应用的端到端架构。

{{< image width="80%" ratio="68.52%"
    link="/docs/examples/bookinfo/noistio.svg"
    caption="Istio 注入之前的 Bookinfo 应用"
    >}}

Bookinfo 是一个异构应用，几个微服务是由不同的语言编写的。这些服务对 Istio 并无依赖，但是构成了一个有代表性的服务网格的例子：它由多个服务、多个语言构成，并且 `reviews` 服务具有多个版本。

## 开始之前

如果还没开始，首先要遵循[安装指南](/zh/docs/setup/)的指导，根据所在平台完成 Istio 的部署工作。

## 部署应用

要在 Istio 中运行这一应用，无需对应用自身做出任何改变。我们只要简单的在 Istio 环境中对服务进行配置和运行，具体一点说就是把 Envoy sidecar 注入到每个服务之中。这个过程所需的具体命令和配置方法由运行时环境决定，而部署结果较为一致，如下图所示：

{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="Bookinfo 应用"
    >}}

所有的微服务都和 Envoy sidecar 集成在一起，被集成服务所有的出入流量都被 sidecar 所劫持，这样就为外部控制准备了所需的 Hook，然后就可以利用 Istio 控制平面为应用提供服务路由、遥测数据收集以及策略实施等功能。

接下来可以根据 Istio 的运行环境，按照下面的讲解完成应用的部署。

### 如果在 Kubernetes 中运行

> 如果运行的是 GKE，请确认你的集群具有至少四个 GKE 节点。如果使用的是 Minikube，应该有 4G 以上的内存。

1. 进入 Istio 安装目录。

1. 启动应用容器：

    * 如果集群用的是[手工 Sidecar 注入](/zh/docs/setup/kubernetes/sidecar-injection/#手工注入-sidecar)，使用如下命令：

        {{< text bash >}}
        $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo.yaml@)
        {{< /text >}}

        [`istioctl kube-inject`](/docs/reference/commands/istioctl/#istioctl-kube-inject) 命令用于在在部署应用之前修改 `bookinfo.yaml`，

    * 如果集群使用的是[自动 Sidecar 注入](/zh/docs/setup/kubernetes/sidecar-injection/#sidecar-的自动注入)，只需简单的 `kubectl` 就能完成服务的部署。

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
        {{< /text >}}

    上面的命令会启动全部的四个服务，其中也包括了 `reviews` 服务的三个版本（`v1`、`v2` 以及 `v3`）

    > 在实际部署中，微服务版本的启动过程需要持续一段时间，并不是同时完成的。

1. 给应用定义 Ingress gateway：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    {{< /text >}}

1. 确认所有的服务和 Pod 都已经正确的定义和启动：

    {{< text bash >}}
    $ kubectl get services
    NAME                       CLUSTER-IP   EXTERNAL-IP   PORT(S)              AGE
    details                    10.0.0.31    <none>        9080/TCP             6m
    kubernetes                 10.0.0.1     <none>        443/TCP              7d
    productpage                10.0.0.120   <none>        9080/TCP             6m
    ratings                    10.0.0.15    <none>        9080/TCP             6m
    reviews                    10.0.0.170   <none>        9080/TCP             6m
    {{< /text >}}

    还有：

    {{< text bash >}}
    $ kubectl get pods
    NAME                                        READY     STATUS    RESTARTS   AGE
    details-v1-1520924117-48z17                 2/2       Running   0          6m
    productpage-v1-560495357-jk1lz              2/2       Running   0          6m
    ratings-v1-734492171-rnr5l                  2/2       Running   0          6m
    reviews-v1-874083890-f0qf0                  2/2       Running   0          6m
    reviews-v2-1343845940-b34q5                 2/2       Running   0          6m
    reviews-v3-1813607990-8ch52                 2/2       Running   0          6m
    {{< /text >}}

#### 确定 Ingress 的 IP 和端口

1. 根据[文档](/zh/docs/tasks/traffic-management/ingress/#使用外部负载均衡器时确定-ip-和端口)设置 `INGRESS_HOST` 和 `INGRESS_PORT` 变量。

1. 设置 `GATEWAY_URL`：

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1. 进入[下一步](#下一步)。

### 如果在 Docker 和 Consul 环境中运行

1. 进入 Istio 安装目录。

1. 启动应用容器。

    运行下面的目录，测试 Consul：

    {{< text bash >}}
    $ docker-compose -f @samples/bookinfo/platform/consul/bookinfo.yaml@ up -d
    $ docker-compose -f samples/bookinfo/platform/consul/bookinfo.sidecars.yaml up -d
    {{< /text >}}

1. 确认所有的容器都在运行：

    {{< text bash >}}
    $ docker ps -a
    {{< /text >}}

    > 如果 Istio Pilot 容器已经终止，重新运行上一步即可。

1. 设置 `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=localhost:9081
    {{< /text >}}

## 下一步

可以用 `curl` 命令来确认 Bookinfo 应用的运行情况：

{{< text bash >}}
$ curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
200
{{< /text >}}

还可以用浏览器打开网址 `http://$GATEWAY_URL/productpage`，来浏览应用的 Web 页面。如果刷新几次应用的页面，就会看到页面中会随机展示 `reviews` 服务的不同版本的效果（红色、黑色的星形或者没有显示）。`reviews` 服务出现这种情况是因为我们还没有使用 Istio 来控制版本的路由。

现在就可以使用这一应用来体验 Istio 的特性了，其中包括了流量的路由、错误注入、速率限制等。接下来可以个人爱好去阅读和演练 [Istio 实例](/zh/docs/examples)。这里为新手推荐[智能路由](/zh/docs/examples/intelligent-routing/)功能作为起步课程。

## 清理

结束对 Bookinfo 示例应用的体验之后，就可以使用下面的命令来完成应用的删除和清理了。

### 在 Kubernetes 环境中完成删除

1. 删除路由规则，并终结应用的 Pod

    {{< text bash >}}
    $ @samples/bookinfo/platform/kube/cleanup.sh@
    {{< /text >}}

1. 确认应用已经关停

    {{< text bash >}}
    $ istioctl get gateway           #-- 此处应该已经没有 Gateway
    $ istioctl get virtualservices   #-- 此处应该已经没有 VirtualService
    $ kubectl get pods               #-- Bookinfo 的所有 Pod 应该都已经被删除
    {{< /text >}}

### 在 Docker 环境中完成删除

1. 删除路由规则和应用容器

    在 Consul 设置中，运行如下命令：

    {{< text bash >}}
    $ @samples/bookinfo/platform/consul/cleanup.sh@
    {{< /text >}}

1. 确认应用已经关停

    {{< text bash >}}
    $ istioctl get virtualservices   #-- 此处应该已经没有 VirtualService
    $ docker ps -a                   #-- Bookinfo 的所有容器应该都已经被删除
    {{< /text >}}
