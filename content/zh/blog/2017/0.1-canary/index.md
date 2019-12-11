---
title: 使用 Istio 进行金丝雀部署
description: 使用 Istio 创建自动缩放的金丝雀部署。
publishdate: 2017-06-14
last_update: 2018-05-16
attribution: Frank Budinsky
keywords: [traffic-management,canary]
aliases:
    - /zh/blog/canary-deployments-using-istio.html
---

{{< tip >}}
本篇博客最后更新时间 2018 年 5 月 16 号，采用了最新版本的流量管理模型。
{{< /tip >}}

采用 [Istio](/zh/) 项目的一大好处就是为服务金丝雀方式部署提供了控制便利。金丝雀部署（或上线）背后的想法是通过让一小部分用户流量引入的新版本进行测试，如果一切顺利，则可以增加（可能逐渐增加）百分比，逐步替换旧版本。如在过程中出现任何问题，则可以中止并回滚到旧版本。最简单的方式，是随机选择百分比请求到金丝雀版本，但在更复杂的方案下，则可以基于请求的区域，用户或其他属性。

基于领域的专业水平，您可能想知道为什么需要 Istio 来支持金丝雀部署，因为像 Kubernetes 这样的平台已经提供了进行 [版本上线](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment) 和 [金丝雀部署](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments) 的方法。问题解决了吗 ？不完全是。虽然以这种方式进行部署可以在简单的情况下工作，但功能非常有限，特别是在大规模自动缩放的云环境中大流量的情况下。

## Kubernetes 中的金丝雀部署{#canary-deployment-in-Kubernetes}

假设我们有一个已部署的 **helloworld** 服务 **v1** 版本，我们想要测试（或简单上线）新版本 **v2**。使用 Kubernetes，您可以通过简单地更新服务的 [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 中的镜像并自动进行部署来 [上线](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment) 新版本的 **helloworld** 服务。如果我们特能够小心保证在启动并且在仅启动一个或两个 v2 副本[暂停](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#pausing-and-resuming-a-deployment)上线时有足够的 **v1** 副本运行，则能够保持金丝雀发布对系统的影响非常小。后续我们可以观察效果，或在必要时进行[回滚](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)。最好，我们也能够对 Deployment 设置 [HPA](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment)，在上线过程中减少或增加副本以处理流量负载时，也能够保持副本比例一致。

尽管这种机制能够很好工作，但这种方式只适用于部署的经过适当测试的版本，也就是说，更多的是蓝/绿发布，又称红/黑发布，而不是 “蜻蜓点水“ 式的金丝雀部署。实际上，对于后者（例如，并没有完全准备好或者无意对外暴露的版本），Kubernetes 中的金丝雀部署将使用具有 [公共 pod 标签](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#using-labels-effectively) 的两个 Deployment 来完成。在这种情况下，我们不能再使用自动缩放器，因为是有由两个独立的自动缩放器来进行控制，不同负载情况下，副本比例（百分比）可能与所需的比例不同。

无论我们使用一个或者两个部署，使用 Docker，Mesos/Marathon 或 Kubernetes 等容器编排平台进行的金丝雀发布管理都存在一个根本问题：使用实例扩容来管理流量；版本流量分发和副本部署在上述平台中并独立。所有 pod 副本，无论版本如何，在 `kube-proxy` 循环池中都被一视同仁地对待，因此管理特定版本接收的流量的唯一方法是控制副本比例。以小百分比维持金丝雀流量需要许多副本（例如，1％ 将需要至少 100 个副本）。即使我们可以忽略这个问题，部署方式功能仍然非常有限，因为它只支持简单（随机百分比）金丝雀部署。如果我们想根据某些特定规则将请求路由到金丝雀版本上，我们仍然需要另一种解决方案。

## 使用 Istio{#enter-Istio}

使用 Istio，流量路由和副本部署是两个完全独立的功能。服务的 pod 数量可以根据流量负载灵活伸缩，与版本流量路由的控制完全正交。这在自动缩放的情况下能够更加简单地管理金丝雀版本。事实上，自动缩放管理器仍然独立运行，其在响应因流量路由导致的负载变化与其他原因导致负载变化的行为上没有区别。

Istio 的 [路由规则](/zh/docs/concepts/traffic-management/#routing-rules) 也带来了其他的便利；你可以轻松实现细粒度控制流量百分比（例如，路由 1％ 的流量而不需要 100 个 pod），当然也可以使用其他规则来控制流量（例如，将特定用户的流量路由到金丝雀版本）。作为展示，让我们看一下采用这种方式部署 **helloworld** 服务的简单便捷。

首先我们定义 **helloworld** 服务，和普通 **Kubernetes** 服务一样，如下所示：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
name: helloworld
labels:
  app: helloworld
spec:
  selector:
    app: helloworld
  ...
{{< /text >}}

然后我们添加 2 个 Deployment，分别为版本 **v1** 和 **v2**，这两个版本都包含服务选择标签 `app：helloworld` ：

{{< text yaml >}}
kind: Deployment
metadata:
  name: helloworld-v1
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: helloworld
        version: v1
    spec:
      containers:
      - image: helloworld-v1
        ...
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: helloworld-v2
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: helloworld
        version: v2
    spec:
      containers:
      - image: helloworld-v2
        ...
{{< /text >}}

需要注意的是，这与使用普通 Kubernetes 进行 [金丝雀部署](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments) 的方式完全相同，但是在 Kubernetes 方式下控制流量分配需要调整每个 Deployment 的副本数目。例如，将 10％ 的流量发送到金丝雀版本（v2），v1 和 v2 的副本可以分别设置为 9 和 1。

但是在 [启用 Istio](/zh/docs/setup/) 的集群中，我们可以通过设置路由规则来控制流量分配。如将 10％ 的流量发送到金丝雀版本本，我们可以使用 `kubectl` 来设置以下的路由规则：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - helloworld
  http:
  - route:
    - destination:
        host: helloworld
        subset: v1
        weight: 90
    - destination:
        host: helloworld
        subset: v2
        weight: 10
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF
{{< /text >}}

当规则设置生效后，Istio 将确保只有 10% 的请求发送到金丝雀版本，无论每个版本的运行副本数量是多少。

## 部署中的自动缩放{#autoscaling-the-deployments}

由于我们不再需要保持副本比例，所以我们可以安全地设置 Kubernetes [HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) 来管理两个版本 Deployment 的副本：

{{< text bash >}}
$ kubectl autoscale deployment helloworld-v1 --cpu-percent=50 --min=1 --max=10
deployment "helloworld-v1" autoscaled
{{< /text >}}

{{< text bash >}}
$ kubectl autoscale deployment helloworld-v2 --cpu-percent=50 --min=1 --max=10
deployment "helloworld-v2" autoscaled
{{< /text >}}

{{< text bash >}}
$ kubectl get hpa
NAME           REFERENCE                 TARGET  CURRENT  MINPODS  MAXPODS  AGE
Helloworld-v1  Deployment/helloworld-v1  50%     47%      1        10       17s
Helloworld-v2  Deployment/helloworld-v2  50%     40%      1        10       15s
{{< /text >}}

如果现在对 **helloworld** 服务上产生一些负载，我们会注意到，当扩容开始时，**v1** 扩容副本数目远高于 **v2** ，因为 **v1** pod 正在处理 90％ 的负载。

{{< text bash >}}
$ kubectl get pods | grep helloworld
helloworld-v1-3523621687-3q5wh   0/2       Pending   0          15m
helloworld-v1-3523621687-73642   2/2       Running   0          11m
helloworld-v1-3523621687-7hs31   2/2       Running   0          19m
helloworld-v1-3523621687-dt7n7   2/2       Running   0          50m
helloworld-v1-3523621687-gdhq9   2/2       Running   0          11m
helloworld-v1-3523621687-jxs4t   0/2       Pending   0          15m
helloworld-v1-3523621687-l8rjn   2/2       Running   0          19m
helloworld-v1-3523621687-wwddw   2/2       Running   0          15m
helloworld-v1-3523621687-xlt26   0/2       Pending   0          19m
helloworld-v2-4095161145-963wt   2/2       Running   0          50m
{{< /text >}}

如果更改路由规则将 50％ 的流量发送到 **v2**，我们则可以在短暂的延迟后注意到 **v1** 副本数的减少，而 **v2** 副本数相应地增加。

{{< text bash >}}
$ kubectl get pods | grep helloworld
helloworld-v1-3523621687-73642   2/2       Running   0          35m
helloworld-v1-3523621687-7hs31   2/2       Running   0          43m
helloworld-v1-3523621687-dt7n7   2/2       Running   0          1h
helloworld-v1-3523621687-gdhq9   2/2       Running   0          35m
helloworld-v1-3523621687-l8rjn   2/2       Running   0          43m
helloworld-v2-4095161145-57537   0/2       Pending   0          21m
helloworld-v2-4095161145-9322m   2/2       Running   0          21m
helloworld-v2-4095161145-963wt   2/2       Running   0          1h
helloworld-v2-4095161145-c3dpj   0/2       Pending   0          21m
helloworld-v2-4095161145-t2ccm   0/2       Pending   0          17m
helloworld-v2-4095161145-v3v9n   0/2       Pending   0          13m
{{< /text >}}

最终结果与 Kubernetes Deployment 上线非常相似，只是整个流程并不是集中地进行编排和管理。相反，我们看到几个组件独立完成工作，虽然它们有因果关系。

有一点不同的是，当我们停止负载时，无论设置路由规则如何，两个版本的副本数最终都会缩小到最小值（1）。

{{< text bash >}}
$ kubectl get pods | grep helloworld
helloworld-v1-3523621687-dt7n7   2/2       Running   0          1h
helloworld-v2-4095161145-963wt   2/2       Running   0          1h
{{< /text >}}

## 聚焦金丝雀测试{#focused-canary-testing}

如上所述，Istio 路由规则可用于根据特定规则准进行流量路由，从而能够提供更复杂的金丝雀部署方案。例如，与简单通过将金丝雀版本暴露给任意百分比的用户方式不同，我们希望在内部用户上尝试，甚至可能只是内部用户的一部分。

以下命令可将特定网站上 50％ 的用户流量路由到金丝雀版本，而其他用户则不受影响：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
    - helloworld
  http:
  - match:
    - headers:
        cookie:
          regex: "^(.*?;)?(email=[^;]*@some-company-name.com)(;.*)?$"
    route:
    - destination:
        host: helloworld
        subset: v1
        weight: 50
    - destination:
        host: helloworld
        subset: v2
        weight: 50
  - route:
    - destination:
        host: helloworld
        subset: v1
EOF
{{< /text >}}

和以前一样，绑定到 2 个版本 Deployment 的自动缩放器会相应地自动管理副本，但这对流量分配没有影响。

## 总结{#summary}

本文中，我们看到了 Istio 如何支持通用可扩展的金丝雀部署，以及与 Kubernetes 部署的差异。Istio 服务网格提供了管理流量分配所需的基础控制，并完全独立于部署缩放。这允许简单而强大的方式来进行金丝雀测试和上线。

支持金丝雀部署的智能路由只是 Istio 的众多功能之一，它将使基于大型微服务的应用程序的生产部署变得更加简单。查看 [istio.io](/zh/) 了解更多信息。

可在 [此处]({{< github_tree >}}/samples/helloworld) 查看示例代码。
