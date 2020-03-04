---
title: 使用 Admiral 管理 Istio 多集群的配置和服务发现 
subtitle: Istio 多集群部署的配置自动化
description: 为 Istio deployment（cluster）提供自动化 Istio 配置，并让其像单个网格一样工作。
publishdate: 2020-01-05
attribution: Anil Attuluri (Intuit), Jason Webb (Intuit)
keywords: [traffic-management,automation,configuration,multicluster,multi-mesh,gateway,federated,globalidentifer]
target_release: 1.5
---

在 Intuit 公司，我们看到了博客 [用于隔离和边界保护的多网格部署](/zh/blog/2019/isolated-clusters/)，其中提到的某些问题与我们有关系。我们意识到，即使我们想要配置单网格多集群，而不是博客中描述的多个网格联邦，也会在我们的环境中遇到相同的非统一命名问题。这篇博客介绍了我们如何使用 [Admiral](https://github.com/istio-ecosystem/admiral) 解决这些问题，该项目是 GitHub 组织 `istio-ecosystem` 下的一个开源项目。

## 背景{#background}

使用 Istio，我们意识到多集群的配置很复杂，并且随着时间的推移很难维护。结果就是，出于可伸缩性和其他操作可行性的考虑，我们选择了[具有控制平面副本集的多集群 Istio 服务网格](/zh/docs/setup/install/multicluster/gateways/#deploy-the-Istio-control-plane-in-each-cluster)中描述的模型。遵循此模型，在大范围使用 Istio 服务网格之前，我们必须解决这些关键要求：

- 如[多网格部署的功能](/zh/blog/2019/isolated-clusters/#features-of-multi-mesh-deployments)中所描述的，创建与命名空间分离的服务 DNS。
- 跨集群的服务发现。
- 支持双活以及 HA/DR 部署。我们还必须通过在分散的群集中的全局唯一命名空间中部署服务来支持这些关键的弹性模式。

我们拥有超过 160 个的 Kubernetes 集群以及跨集群的全局唯一命名空间。基于这样的配置，我们可以根据命名空间名称，将相同的服务 workload 部署到不同区域中。
结果是，我们根据[多集群网格中的分版本路由](/zh/blog/2019/multicluster-version-routing)中的路由策略，示例中的 `foo.namespace.global` 无法跨集群工作。我们需要通过全局唯一的、可发现的 service DNS，该 DNS 可以解析多个群集中的服务实例，每个实例都可以使用其唯一 Kubernetes FQDN 进行寻址/运行。
例如，如果 `foo` 以不同的名称，同时运行在两个 Kubernetes 集群中，则 `foo.global` 应该同时解析为 `foo.uswest2.svc.cluster.local` 和 `foo.useast2.svc.cluster.local`。并且，我们的服务需要其他具有不同解析度和全局路由属性的 DNS 名称。例如，`foo.global` 应首先在本地解析，然后使用拓扑路由，将其路由到远程实例，而`foo-west.global` 和 `foo-east.global`（用于测试的名称）始终应解析到相应地区。

## 上下文配置{#contextual-configuration}

经过进一步的调查，很明显，配置需要根据上下文来确定：每个集群都需要根据其场景定制配置。

例如，我们有一个被订单和报告消费的支付服务。支付服务在 `us-east`（集群 3）和 `us-west`（集群 2）之间进行了 HA/DR 部署。支付服务部署在两个区域不同名的命名空间中。订单服务作为支付方式，部署在 `us-west` 另一个集群中（集群 1）。报告服务与 `us-west` 中的支付服务部署在同一群集中（群集2）。

{{< image width="75%"
    link="./Istio_mesh_example.svg"
    alt="Istio 多集群调用 workload 的示例"
    caption="Istio 中的 workload 跨集群通信"
    >}}

当集群 1 和集群 2 中的其它服务想要使用支付服务时，下面的 Istio `ServiceEntry` yaml 说明了其需要使用的上下文配置：

集群 1 Service Entry

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: payments.global-se
spec:
  addresses:
  - 240.0.0.10
  endpoints:
  - address: ef394f...us-east-2.elb.amazonaws.com
    locality: us-east-2
    ports:
      http: 15443
  - address: ad38bc...us-west-2.elb.amazonaws.com
    locality: us-west-2
    ports:
      http: 15443
  hosts:
  - payments.global
  location: MESH_INTERNAL
  ports:
  - name: http
    number: 80
    protocol: http
  resolution: DNS
{{< /text >}}

集群 2 Service Entry

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: payments.global-se
spec:
  addresses:
  - 240.0.0.10
  endpoints:
  - address: ef39xf...us-east-2.elb.amazonaws.com
    locality: us-east-2
    ports:
      http: 15443
  - address: payments.default.svc.cluster.local
    locality: us-west-2
    ports:
      http: 80
  hosts:
  - payments.global
  location: MESH_INTERNAL
  ports:
  - name: http
    number: 80
    protocol: http
  resolution: DNS
{{< /text >}}

从集群 2 中报告服务的角度来看，支付 `ServiceEntry`（Istio CRD）应将 `us-west` 指向本地 Kubernetes FQDN，将 `us-east` 指向群集 3 的 `istio-ingressgateway`（负载均衡器）。从群集 1 中订单服务的角度来看，支付 `ServiceEntry` 应将 `us-west` 指向群集 2 的 `istio-ingressgateway` 以及将 `us-east` 指向集群 3 的 `istio-ingressgateway`。

但是，还有更复杂的情况：如果 `us-west` 的支付服务想进行计划维护，现在要将流量转移到 `us-east` 的支付服务，此时该怎么办？这要求支付服务更改其所有客户群集中的 Istio 配置。如果没有自动化，这几乎不可能。

## Admiral 的方案：Admiral 自动化{#admiral-to-the-rescue-admiral-is-that-automation}

Admiral 是一个 Istio 控制平面的控制器。

{{< image width="75%"
    link="./Istio_mesh_example_with_admiral.svg"
    alt="使用 Admiral 在 Istio 多集群中调用 workload 的示例"
    caption="Istio 和 Admiral 上的跨集群 workload 通信"
    >}}

Admiral 基于服务唯一标识符，为跨多个群集的 Istio 网格提供自动化配置，使其像单个网格一样工作，该标识符将多个群集上运行的 workload 和服务进行关联。它还为跨集群的 Istio 配置提供了自动同步功能。这同时减轻了开发人员和网格运维人员的负担，并有助于集群的扩展。

## Admiral CRD

### 全局流量路由{#global-traffic-routing}

基于 Admiral 的全局流量策略 CRD，支付服务可以更新区域流量权重，而 Admiral 可以在使用支付服务的所有群集中更新 Istio 配置。

{{< text yaml >}}
apiVersion: admiral.io/v1alpha1
kind: GlobalTrafficPolicy
metadata:
  name: payments-gtp
spec:
  selector:
    identity: payments
  policy:
  - dns: default.payments.global
    lbType: 1
    target:
    - region: us-west-2/*
      weight: 10
    - region: us-east-2/*
      weight: 90
{{< /text >}}

在上面的示例中，支付服务 90% 的流量被路由到 `us-east` 地区。该全局流量配置会自动转换为 Istio 配置，并在上下文中映射到 Kubernetes 群集中，从而为网格中的支付服务客户端启用多群集全局路由。

全局流量路由依赖于 Istio 每个可用服务的本地负载均衡，这需要使用 Istio 1.5 或更高版本。

### Dependency{#dependency}

Admiral `Dependency` CRD 允许我们基于服务标识符指定服务的依赖关系。这优化了 Admiral 配置的传递，仅向运行服务的依赖客户端的必需群集传递生成的配置（而无需将其传递到所有群集）。Admiral 还会在客户端 workload 的命名空间中配置 `并/或` 更新 Sidecar Istio CRD，以将 Istio 配置限制为仅依赖于它。我们使用记录在其他地方的 service-to-service 授权信息来生成此 `Dependency` 记录，以供 Admiral 使用。

订单服务依赖关系的示例：

{{< text yaml >}}
apiVersion: admiral.io/v1alpha1
kind: Dependency
metadata:
  name: dependency
  namespace: admiral
spec:
  source: orders
  identityLabel: identity
  destinations:
  - payments
{{< /text >}}

`Dependency` 是可选的，没有服务的依赖关系，只是会导致该服务的 Istio 配置被推送到全部的群集。

## 总结{#summary}

Admiral 提供了新的全局流量路由和唯一服务命名功能，致力于解决由[具有控制平面副本集的多集群部署](/zh/docs/setup/install/multicluster/gateways/#deploy-the-Istio-control-plane-in-each-cluster)带来的挑战。它消除了集群之间手动配置同步的需求，并为每个集群生成上下文配置。这样或许就可以操作由许多 Kubernetes 集群组成的服务网格了。

我们认为 Istio/Service Mesh 社区将从这种方法中受益，因此我们开源了 [Admiral](https://github.com/istio-ecosystem/admiral)，我们很高兴收到您的反馈和支持！

