---
title: 多集群服务网格中的分版本路由
description: 在多集群服务网格环境中配置 Istio 的路由规则。
publishdate: 2019-02-07
subtitle:
attribution: Frank Budinsky (IBM)
keywords: [traffic-management,multicluster]
target_release: 1.0
---

如果花一点时间对 Istio 进行了解，你可能会注意到，大量的功能都可以在单一的 Kubernetes 集群中，用简单的 [任务](/zh/docs/tasks) 和 [示例](/zh/docs/examples/) 所表达的方式来运行。但是真实世界中的云计算和基于微服务的应用往往不是这么简单的，会需要在不止一个地点分布运行，用户难免会产生怀疑，生产环境中是否还能这样运行？

幸运的是，Istio 提供了多种服务网格的配置方式，应用能够用近乎透明的方式加入一个跨越多个集群运行的服务网格之中，也就是 [多集群服务网格](/zh/docs/ops/deployment/deployment-models/#multiple-clusters) 。最简单的设置多集群网格的方式，就是使用 [多控制平面拓扑](/zh/docs/ops/deployment/deployment-models/#control-plane-models) ，这种方式不需要特别的网络依赖。在这种条件下，每个 Kubernetes 集群都有自己的控制平面，但是每个控制平面都是同步的，并接受统一的管理。

本文中，我们会在多控制平面拓扑形式的多集群网格中尝试一下 Istio 的 [流量管理](/zh/docs/concepts/traffic-management/) 功能。我们会展示如何配置 Istio 路由规则，在多集群服务网格中部署 [Bookinfo 示例]({{<github_tree>}}/samples/bookinfo)，`reviews` 服务的 `v1` 版本运行在一个集群上，而 `v2` 和 `v3` 运行在另一个集群上，并完成远程服务调用。

## 集群部署 {#setup-clusters}

首先需要部署两个 Kubernetes 集群，并各自运行一个做了轻度定制的 Istio。

* 依照[使用 Gateway 连接多个集群](/zh/docs/setup/install/multicluster/gateways/)中提到的步骤设置一个多集群环境。

* `kubectl` 命令可以使用 `--context` 参数访问两个集群。
    使用下面的命令列出所有 `context`：

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME       CLUSTER    AUTHINFO       NAMESPACE
    *         cluster1   cluster1   user@foo.com   default
              cluster2   cluster2   user@foo.com   default
    {{< /text >}}

* 将配置文件中的 `context` 名称赋值给两个环境变量：

    {{< text bash >}}
    $ export CTX_CLUSTER1=<cluster1 context name>
    $ export CTX_CLUSTER2=<cluster2 context name>
    {{< /text >}}

## 在 `cluster1` 中部署 `bookinfo` 的 `v1` 版本{#deploy-in-cluster-1}

在 `cluster1` 中运行 `productpage` 和 `details` 服务，以及 `reviews` 服务的 `v1` 版本。

{{< text bash >}}
$ kubectl label --context=$CTX_CLUSTER1 namespace default istio-injection=enabled
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: productpage
  labels:
    app: productpage
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: productpage
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: productpage-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: productpage
        version: v1
    spec:
      containers:
      - name: productpage
        image: istio/examples-bookinfo-productpage-v1:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: v1
kind: Service
metadata:
  name: details
  labels:
    app: details
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: details
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: details-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: details
        version: v1
    spec:
      containers:
      - name: details
        image: istio/examples-bookinfo-details-v1:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: v1
kind: Service
metadata:
  name: reviews
  labels:
    app: reviews
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: reviews
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v1
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v1:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
EOF
{{< /text >}}

## 在 `cluster2` 中部署 `bookinfo` 的 `v2` 和 `v3`{#deploy-in-cluster-2}

在 `cluster2` 中运行 `ratings` 服务以及 `reviews` 服务的 `v2` 和 `v3` 版本：

{{< text bash >}}
$ kubectl label --context=$CTX_CLUSTER2 namespace default istio-injection=enabled
$ kubectl apply --context=$CTX_CLUSTER2 -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ratings
  labels:
    app: ratings
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: ratings
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ratings-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: ratings
        version: v1
    spec:
      containers:
      - name: ratings
        image: istio/examples-bookinfo-ratings-v1:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: v1
kind: Service
metadata:
  name: reviews
  labels:
    app: reviews
spec:
  ports:
  - port: 9080
    name: http
  selector:
    app: reviews
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v2
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v2:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: reviews-v3
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: reviews
        version: v3
    spec:
      containers:
      - name: reviews
        image: istio/examples-bookinfo-reviews-v3:1.10.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9080
EOF
{{< /text >}}

## 访问 `bookinfo` 应用{#access-the-application}

和平常一样，我们需要使用一个 Istio gateway 来访问 `bookinfo` 应用。

* 在 `cluster1` 中创建 `bookinfo` 的网关：

    {{< text bash >}}
    $ kubectl apply --context=$CTX_CLUSTER1 -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    {{< /text >}}

* 遵循 [Bookinfo 示例应用](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port)中的步骤，确定 Ingress 的 IP 和端口，用浏览器打开 `http://$GATEWAY_URL/productpage`。

这里会看到 `productpage`，其中包含了 `reviews` 的内容，但是没有出现 `ratings`，这是因为只有 `reviews` 服务的 `v1` 版本运行在 `cluster1` 上，我们还没有配置到 `cluster2` 的访问。

## 在 `cluster1` 上为远端的 `reviews` 服务创建 `ServiceEntry` 以及 `DestinationRule`

根据 [配置指南](/zh/docs/setup/install/multicluster/gateways/#setup-DNS) 中的介绍，远程服务可以用一个 `.global` 的 DNS 名称进行访问。在我们的案例中，就是 `reviews.default.global`，所以我们需要为这个主机创建 `ServiceEntry` 和 `DestinationRule`。`ServiceEntry` 会使用 `cluster2` 网关作为端点地址来访问服务。可以使用网关的 DNS 名称或者公共 IP：

{{< text bash >}}
$ export CLUSTER2_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER2 svc --selector=app=istio-ingressgateway \
    -n istio-system -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
{{< /text >}}

用下面的命令来创建 `ServiceEntry` 和 `DestinationRule`：

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: reviews-default
spec:
  hosts:
  - reviews.default.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 9080
    protocol: http
  resolution: DNS
  addresses:
  - 240.0.0.3
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    labels:
      cluster: cluster2
    ports:
      http1: 15443 # 不要修改端口值
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-global
spec:
  host: reviews.default.global
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v2
    labels:
      cluster: cluster2
  - name: v3
    labels:
      cluster: cluster2
EOF
{{< /text >}}

`ServiceEntry` 的地址 `240.0.0.3` 可以是任意的未分配 IP。在 `240.0.0.0/4` 的范围里面进行选择是个不错的主意。阅读 [通过网关进行连接的多集群](/zh/docs/setup/install/multicluster/gateways/#configure-the-example-services) 一文，能够获得更多相关信息。

注意 `DestinationRule` 中的 `subset` 的标签，`cluster: cluster2` 对应的是 `cluster2` 网关。一旦流量到达目标集群，就会由本地目的 `DestinationRule` 来鉴别实际的 Pod 标签（`version: v1` 或者 `version: v2`）

## 在所有集群上为本地 `reviews` 服务创建 `DestinationRule`

技术上来说，我们只需要为每个集群定义本地的 `subset` 即可（`cluster1` 中的 `v1`，`cluster2` 中的 `v2` 和 `v3`），但是定义一个用不到的并未部署的版本也没什么大碍，为了清晰一点，我们会在两个集群上都创建全部三个 `subset`。

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews.default.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER2 -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews.default.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
EOF
{{< /text >}}

## 创建 `VirtualService` 来路由 `reviews` 服务的流量{#create-a-destination-rule-on-both-clusters-for-the-local-reviews-service}

目前所有调用 `reviews` 服务的流量都会进入本地的 `reviews` Pod，也就是 `v1`，如果查看一下远吗，会发现 `productpage` 的实现只是简单的对  `http://reviews:9080` （也就是 `reviews.default.svc.cluster.local`）发起了请求，也就是本地版本。对应的远程服务名称为 `reviews.default.global`，所以需要用路由规则来把请求转发到远端集群。

{{< tip >}}
注意如果所有版本的 `reviews` 服务都在远端，也就是说本地没有 `reviews` 服务，那么 DNS 就会把 `reviews` 直接解析到 `reviews.default.global`，在本文的环境里，无需定义任何路由规则就可以发起对远端集群的请求。
{{< /tip >}}

创建下列的 `VirtualService`，把 `jason` 的流量转发给运行在 `cluster2` 上的 `v2` 和 `v3` 版本的 `reviews`，两个版本各负责一半流量。其他用户的流量还是会发给 `v1` 版本的 `reviews`。

{{< text bash >}}
$ kubectl apply --context=$CTX_CLUSTER1 -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews.default.svc.cluster.local
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews.default.global
        subset: v2
      weight: 50
    - destination:
        host: reviews.default.global
        subset: v3
      weight: 50
  - route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v1
EOF
{{< /text >}}

{{< tip >}}
这种平均分配的规则并不实际，只是一种用于演示远端服务多版本之间流量分配的方便手段。
{{< /tip >}}

回到浏览器，用 `jason` 的身份登录。刷新页面几次，会看到星形图标在红黑两色之间切换（`v2` 和 `v3`）。如果登出，就只会看到没有 `ratings` 的 `reviews` 服务了。

## 总结{#summary}

本文中，我们看到在多控制平面拓扑的多集群网格中，如何使用 Istio 路由规则进行跨集群的流量分配。
这里我们手工配置了 `.global` 的 `ServiceEntry` 以及 `DestinationRule`，用于进行对远端集群中 `reviews` 服务的访问。实际上如果我们想要的话，可以让任何服务都在远端或本地运行，当然需要为远端服务配置 `.global` 的相关资源。幸运的是，这个过程可以自动化，并且可能在 Istio 的未来版本中实现。
