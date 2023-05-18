---
title: Bookinfo 应用
description: 部署一个用于演示多种 Istio 特性的应用，由四个单独的微服务构成。
weight: 10
aliases:
    - /zh/docs/samples/bookinfo.html
    - /zh/docs/guides/bookinfo/index.html
    - /zh/docs/guides/bookinfo.html
owner: istio/wg-docs-maintainers
test: yes
---

这个示例部署了一个用于演示多种 Istio 特性的应用，该应用由四个单独的微服务构成。

{{< tip >}}
如果您使用[入门](/zh/docs/setup/getting-started/)安装了 Istio，说明您已经安装了 Bookinfo，
您可以跳过以下大多数步骤，直接跳到[定义服务版本](/zh/docs/examples/bookinfo/#define-the-service-versions)。
{{< /tip >}}

这个应用模仿在线书店的一个分类，显示一本书的信息。
页面上会显示一本书的描述，书籍的细节（ISBN、页数等），以及关于这本书的一些评论。

Bookinfo 应用分为四个单独的微服务：

* `productpage`：这个微服务会调用 `details` 和 `reviews` 两个微服务，用来生成页面。
* `details`：这个微服务中包含了书籍的信息。
* `reviews`：这个微服务中包含了书籍相关的评论。它还会调用 `ratings` 微服务。
* `ratings`：这个微服务中包含了由书籍评价组成的评级信息。

`reviews` 微服务有 3 个版本：

* v1 版本不会调用 `ratings` 服务。
* v2 版本会调用 `ratings` 服务，并使用 1 到 5 个黑色星形图标来显示评分信息。
* v3 版本会调用 `ratings` 服务，并使用 1 到 5 个红色星形图标来显示评分信息。

下图展示了这个应用的端到端架构。

{{< image width="80%" link="./noistio.svg" caption="Bookinfo Application without Istio" >}}

Bookinfo 应用中的几个微服务是由不同的语言编写的。
这些服务对 Istio 并无依赖，但是构成了一个有代表性的服务网格的例子：
它由多个服务、多个语言构成，并且 `reviews` 服务具有多个版本。

## 开始之前{#before-you-begin}

如果您还没有开始，请遵循[安装指南](/zh/docs/setup/)完成 Istio 的部署工作。

{{< boilerplate gateway-api-support >}}

## 部署应用{#deploying-the-application}

要在 Istio 中运行这一应用，无需对应用自身做出任何改变。
您只要简单的在 Istio 环境中对服务进行配置和运行，具体一点说就是把 Envoy Sidecar 注入到每个服务之中。
最终的部署结果将如下图所示：

{{< image width="80%" link="./withistio.svg" caption="Bookinfo Application" >}}

所有的微服务都和 Envoy Sidecar 集成在一起，被集成服务所有的出入流量都被 Sidecar 所劫持，
这样就为外部控制准备了所需的 Hook，然后就可以利用 Istio 控制平面为应用提供服务路由、遥测数据收集以及策略实施等功能。

### 启动应用服务{#start-the-application-services}

{{< tip >}}
如果运行的是 GKE，请确您的集群具有至少四个标准 GKE 节点。如果使用的是 Minikube，应该有 4G 以上的内存。
{{< /tip >}}

1. 进入 Istio 安装目录。

1. Istio 默认[自动注入 Sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection).
    请为 `default` 命名空间打上标签 `istio-injection=enabled`：

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    {{< /text >}}

    {{< warning >}}
    如果您使用 OpenShift，请确保按照
    [OpenShift 设置页面](/zh/docs/setup/platform-setup/openshift/#privileged-security-context-constraints-for-application-sidecars)
    中所述为命名空间上的服务帐户授予适当的权限
    {{< /warning >}}

1. 使用 `kubectl` 部署应用：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您在安装过程中禁用了 Sidecar
    自动注入功能而选择[手动注入 Sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#manual-sidecar-injection)，
    请在部署应用之前使用 [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject)
    命令修改 `bookinfo.yaml` 文件。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo.yaml@)
    {{< /text >}}

    {{< /warning >}}

    上面的命令会启动全部的四个服务，其中也包括了 reviews 服务的三个版本（v1、v2 以及 v3）。

    {{< tip >}}
    在实际部署中，微服务版本的启动过程需要持续一段时间，并不是同时完成的。
    {{< /tip >}}

1. 确认所有的服务和 Pod 都已经正确的定义和启动：

    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.31    <none>        9080/TCP   6m
    kubernetes    ClusterIP   10.0.0.1     <none>        443/TCP    7d
    productpage   ClusterIP   10.0.0.120   <none>        9080/TCP   6m
    ratings       ClusterIP   10.0.0.15    <none>        9080/TCP   6m
    reviews       ClusterIP   10.0.0.170   <none>        9080/TCP   6m
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

1. 要确认 Bookinfo 应用是否正在运行，请在某个 Pod 中用 `curl` 命令对应用发送请求，例如 `ratings`：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

### 确定 Ingress 的 IP 和端口{#determine-the-ingress-IP-and-port}

现在 Bookinfo 服务启动并运行中，您需要使应用程序可以从外部访问 Kubernetes 集群，
例如使用浏览器。可以使用网关实现这个目标。

1. 为 Bookinfo 应用程序定义一个网关：

    {{< tabset category-name="config-api" >}}

    {{< tab name="Istio classic" category-value="istio-classic" >}}

    使用以下命令创建 [Istio Gateway](/zh/docs/concepts/traffic-management/#gateways)：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    gateway.networking.istio.io/bookinfo-gateway created
    virtualservice.networking.istio.io/bookinfo created
    {{< /text >}}

    确认网关创建完成：

    {{< text bash >}}
    $ kubectl get gateway
    NAME               AGE
    bookinfo-gateway   32s
    {{< /text >}}

    遵循[这些指示说明](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
    设置 `INGRESS_HOST` 和 `INGRESS_PORT` 变量来访问网关。设置好变量后，返回此处。

    {{< /tab >}}

    {{< tab name="Gateway API" category-value="gateway-api" >}}

    {{< boilerplate external-loadbalancer-support >}}

    使用以下命令创建 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/)：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    因为创建 Kubernetes `Gateway` 资源也会
    [部署关联的代理服务](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)，
    所以运行以下命令等待网关就绪：

    {{< text bash >}}
    $ kubectl wait --for=condition=programmed gtw bookinfo-gateway
    {{< /text >}}

    从 bookinfo 网关资源处获取网关地址和端口：

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
    $ export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  设置 `GATEWAY_URL`：

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

## 确认可以从集群外部访问应用{#confirm-the-app-is-accessible-from-outside-the-cluster}

可以用 `curl` 命令来确认是否能够从集群外部访问 Bookinfo 应用程序：

{{< text bash >}}
$ curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

还可以用浏览器打开网址 `http://$GATEWAY_URL/productpage`，来浏览应用的 Web 页面。
如果刷新几次应用的页面，就会看到 `productpage` 页面中会随机展示 `reviews` 服务的不同版本的效果
（红色、黑色的星形或者没有显示）。`reviews` 服务出现这种情况是因为我们还没有使用 Istio 来控制版本的路由。

## 定义服务版本{#define-the-service-versions}

在可以使用 Istio 控制 Bookinfo 版本路由之前，您需要定义可用的版本。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio classic" category-value="istio-classic" >}}

Istio 在[目标规则](/zh/docs/concepts/traffic-management/#destination-rules)中使用
**subsets** 定义服务的版本。运行以下命令为 Bookinfo 服务创建默认的目标规则：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
{{< /text >}}

{{< tip >}}
`default` 和 `demo` 的[配置文件](/zh/docs/setup/additional-setup/config-profiles/)默认情况下启用了
[自动双向 TLS](/zh/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls)。
要强制执行双向 TLS，请使用 `samples/bookinfo/networking/destination-rule-all-mtls.yaml` 中的目标规则。
{{< /tip >}}

等待几秒钟，以使目标规则生效。

您可以使用以下命令查看目标规则：

{{< text bash >}}
$ kubectl get destinationrules -o yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

不同于 Istio API 使用 `DestinationRule` 子集来定义服务的版本，
Kubernetes Gateway API 将为此使用后端服务定义。

运行以下命令为三个版本的 `reviews` 服务创建后端服务定义：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 下一步{#what-s-next}

现在就可以使用这一应用来体验 Istio 的特性了，其中包括了流量的路由、错误注入、速率限制等。
接下来可以根据个人爱好去阅读和演练 [Istio 实例](/zh/docs/tasks)。
这里为新手推荐[智能路由](/zh/docs/tasks/traffic-management/request-routing/)功能作为起步课程。

## 清理{#cleanup}

结束对 Bookinfo 示例应用的体验之后，就可以使用下面的命令来完成应用的删除和清理了：

{{< text bash >}}
$ @samples/bookinfo/platform/kube/cleanup.sh@
{{< /text >}}
