---
title: 增量式应用 Istio 第一部分，流量管理
description: 如何在不部署 Sidecar 代理的情况下使用 Istio 进行流量管理。
publishdate: 2018-11-21
subtitle:
attribution: Sandeep Parikh
twitter: crcsmnky
keywords: [traffic-management, gateway]
---

流量管理是 Istio 提供的重要优势之一。Istio 流量管理的核心是在将通信流量和基础设施的伸缩进行解耦。如果没有 Istio 这样的服务网格，这种流量控制方式是不可能实现的。

例如，您希望执行一次[金丝雀发布](https://martinfowler.com/bliki/CanaryRelease.html)。当使用 Istio 时，您可以指定 service 的 **v1** 版本接收 90% 的传入流量，而该 service **v2** 版本仅接收 10%。如果使用标准的 Kubernetes deployment，实现此目的的唯一方法是手动控制每个版本的可用 Pod 数量，例如使 9 个 Pod 运行 v1 版本，使 1 个 Pod 运行 v2 版本。这种类型的手动控制难以实现，并且随着时间的推移可能无法扩展。有关更多信息，请查看[使用 Istio 进行金丝雀发布](/zh/blog/2017/0.1-canary/)。

部署现有 service 的更新时存在同样的问题。虽然您可以使用 Kubernetes 更新 deployment，但它需要将 v1 Pod 替换为 v2 Pod。使用 Istio，您可以部署 service 的 v2 版本，并使用内置流量管理机制在网络层面将流量转移到更新后的 service，然后删除 v1 版本的 Pod。

除了金丝雀发布和一般流量转移之外，Istio 还使您能够实现动态请求路由（基于 HTTP header）、故障恢复、重试、断路器和故障注入。有关更多信息，请查看[流量管理文档](/zh/docs/concepts/traffic-management/)。

这篇文章介绍的技术重点突出了一种特别有用的方法，可以逐步实现 Istio（在这种情况下，只有流量管理功能），而无需单独更新每个 Pod。

## 设置：为什么要实施 Istio 流量管理功能？

当然，第一个问题是：为什么要这样做？

如果你是众多拥有大量团队和大型集群的组织中的一员，那么答案是很清楚的。假设 A 团队正在开始使用 Istio，并希望在 service A 上开始一些金丝雀发布，但是 B 团队还没有开始使用 Istio，所以他们没有部署 sidecar。

使用 Istio，A 团队仍然可以让 service B 通过 Istio 的 ingress gateway 调用 service A 来实现他们的金丝雀发布。

## 背景：Istio 网格中的流量路由

但是，如何在不更新每个应用程序的 Pod 的情况下，使用 Istio 的流量管理功能来包含 Istio sidecar？在回答这个问题之前，让我们以高层视角，快速地看看流量如何进入 Istio 网格以及如何被路由。

Pod 包含一个 sidecar 代理，该代理作为 Istio 网格的一部分，负责协调 Pod 的所有入站和出站流量。在 Istio 网格中，Pilot 负责将高级路由规则转换为配置并将它们传播到 sidecar 代理。这意味着当服务彼此通信时，它们的路由决策是由客户端确定的。

假设您有 service A 和 service B 两个服务，他们是 Istio 网格的一部分。当 A 想要与 B 通信时，Pod A 的 sidecar 代理负责将流量引导到 service B。例如，如果你希望到 service B v1 版本和 v2 版本之间的流量按 50/50 分割，流量将按如下方式流动：

{{< image width="60%" link="./fifty-fifty.png" caption="50/50 流量分割" >}}

如果 service A 和 B 不是 Istio 网格的一部分，则没有 sidecar 代理知道如何将流量路由到 service B 的不同版本。在这种情况下，您需要使用另一种方法来使 service A 到 service B 的流量遵循您设置的 50/50 规则。

幸运的是，标准的 Istio 部署已经包含了一个 [Gateway](/zh/docs/concepts/traffic-management/#gateway)，它专门处理 Istio 网格之外的入口流量。此 Gateway 用于允许通过外部负载均衡器进入的集群外部入口流量；或来自 Kubernetes 集群，但在服务网格之外的入口流量。网关可以进行配置，对没有 Sidecar 支持的入口流量进行代理，引导流量进入相应的 Pod。这种方法允许您利用 Istio 的流量管理功能，其代价是通过入口网关的流量将产生额外的跃点。

{{< image width="60%" link="./fifty-fifty-ingress-gateway.png" caption="使用 Ingress Gateway 的 50/50 流量分割" >}}

## 实践：Istio 流量路由

一种实践的简单方法是首先按照[平台设置](/zh/docs/setup/kubernetes/platform-setup/)说明设置 Kubernetes 环境，然后使用 [Helm](/zh/docs/setup/kubernetes/minimal-install/) 安装仅包含流量管理组件（ingress gateway、egress gateway、Pilot）的 Istio。下面的示例使用 [Google Kubernetes Engine](https://cloud.google.com/gke)。

首先，**安装并配置 [GKE](/zh/docs/setup/kubernetes/platform-setup/gke/)**：

{{< text bash >}}
$ gcloud container clusters create istio-inc --zone us-central1-f
$ gcloud container clusters get-credentials istio-inc
$ kubectl create clusterrolebinding cluster-admin-binding \
   --clusterrole=cluster-admin \
   --user=$(gcloud config get-value core/account)
{{< /text >}}

然后，**[安装 Helm](https://docs.helm.sh/using_helm/#installing-helm) 并[生成 Istio 最小配置安装](/zh/docs/setup/kubernetes/minimal-install/)** -- 只有流量管理组件：

{{< text bash >}}
$ helm template install/kubernetes/helm/istio \
  --name istio \
  --namespace istio-system \
  --set security.enabled=false \
  --set galley.enabled=false \
  --set sidecarInjectorWebhook.enabled=false \
  --set mixer.enabled=false \
  --set prometheus.enabled=false \
  --set global.proxy.envoyStatsd.enabled=false \
  --set pilot.sidecar=false > istio-minimal.yaml
{{< /text >}}

然后**创建 `istio-system` namespace 并部署 Istio**：

{{< text bash >}}
$ kubectl create namespace istio-system
$ kubectl apply -f istio-minimal.yaml
{{< /text >}}

然后，在没有 Istio sidecar 容器的前提下**部署 Bookinfo 示例**：

{{< text bash >}}
$ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
{{< /text >}}

现在，**配置一个新的 Gateway** 允许从 Istio 网格外部访问 reviews service；一个新的 `VirtualService` 用于平均分配到 reviews service v1 和 v2 版本的流量；以及一系列新的、将目标子集与服务版本相匹配的 `DestinationRule` 资源：

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: reviews-gateway
spec:
  selector:
    istio: ingressgateway # 使用 istio 默认控制器
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - "*"
  gateways:
  - reviews-gateway
  http:
  - match:
    - uri:
        prefix: /reviews
    route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v2
      weight: 50
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
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

最后，使用 `curl` **部署一个用于测试的 Pod**（没有 Istio sidecar 容器）：

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml
{{< /text >}}

## 测试您的部署

现在就可以通过 Sleep pod 使用 curl 命令来测试不同的行为了。

第一个示例是使用标准 Kubernetes service DNS 行为向 reviews service 发出请求（**注意**：下面的示例中使用了 [`jq`](https://stedolan.github.io/jq/) 来过滤 `curl` 的输出）：

{{< text bash >}}
$ export SLEEP_POD=$(kubectl get pod -l app=sleep \
  -o jsonpath={.items..metadata.name})
$ for i in `seq 3`; do \
  kubectl exec -it $SLEEP_POD curl http://reviews:9080/reviews/0 | \
  jq '.reviews|.[]|.rating?'; \
  done
{{< /text >}}

{{< text json >}}
{
  "stars": 5,
  "color": "black"
}
{
  "stars": 4,
  "color": "black"
}
null
null
{
  "stars": 5,
  "color": "red"
}
{
  "stars": 4,
  "color": "red"
}
{{< /text >}}

请注意我们是如何从 reviews service 的所有三个版本获得响应（`null` 来自 reviews v1 版本，它没有评级数据）并且流量没有在 v1 和 v2 版本间平均拆分。这是预期的行为，因为 `curl` 命令在 reviews service 所有三个版本之间进行 Kubernetes service 负载均衡。为了以 50/50 的流量拆分形式访问 reviews，我们需要通过 ingress Gateway 访问 service：

{{< text bash >}}
$ for i in `seq 4`; do \
  kubectl exec -it $SLEEP_POD curl http://istio-ingressgateway.istio-system/reviews/0 | \
  jq '.reviews|.[]|.rating?'; \
  done
{{< /text >}}

{{< text json >}}
{
  "stars": 5,
  "color": "black"
}
{
  "stars": 4,
  "color": "black"
}
null
null
{
  "stars": 5,
  "color": "black"
}
{
  "stars": 4,
  "color": "black"
}
null
null
{{< /text >}}

任务完成！这篇文章展示了如何部署仅包含流量管理组件（Pilot、ingress Gateway）的 Istio 的最小安装，然后使用这些组件将流量定向到特定版本的 reviews service。由于不是必须通过部署 Istio sidecar 代理来获得这些功能，因此几乎没有给现有工作负载或应用程序造成中断。

这篇文章展示了如何利用 Istio 及内置的 ingress Gateway（以及一些 `VirtualService` 和 `DestinationRule` 资源），轻松实现集群外部入口流量和集群内部服务到服务的流量管理。这种技术是增量式应用 Istio 的一个很好的例子，在 Pod 由不同团队拥有，或部署到不同命名空间的现实案例中尤其有用。