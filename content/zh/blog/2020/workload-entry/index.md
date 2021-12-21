---
title: 介绍工作负载条目
subtitle: 桥接 Kubernetes 和 VM
description: 描述了工作负载条目的新功能。
publishdate: 2020-05-21
attribution: Cynthia Coan (Tetrate), Shriram Rajagopalan (Tetrate), Tia Louden (Tetrate), John Howard (Google), Sven Mawson (Google)
keywords: [vm, workloadentry, migration, '1.6', baremetal, serviceentry, discovery]
---

## 工作负载条目简介：桥接 Kubernetes 和 VM{#introducing-workload-entries-bridging-Kubernetes-and-VMs}

从历史上看，Istio 为在 Kubernetes 上运行的工作负载提供了很好的体验，但对于其他类型的工作负载，如虚拟机（VM）和裸机，则不太顺利。这些差距包括无法在 VM 上以声明方式指定 Sidecar 的属性，无法正确响应工作负载的生命周期变化（例如，从启动到未准备就绪，或健康检查），以及在工作负载迁移到 Kubernetes 时繁琐的 DNS 解决方法，仅此而已。

Istio 1.6 在如何管理非 Kubernetes 工作负载方面引入了一些变化，其驱动力是希望在容器之外的用例中更容易获得 Istio 的好处，比如在 Kubernetes 之外的平台上运行传统数据库，或者在不重写现有应用的情况下采用 Istio 的功能。

### 背景{#background}

在 Istio 1.6 之前，非容器化工作负载可以简单地配置为 `ServiceEntry` 中的一个IP地址，这意味着它们只作为服务的一部分存在。Istio 缺乏对这些非容器化工作负载的一流抽象，类似于 Kubernetes 将 Pod 视为计算的基本单位--一个命名对象，作为与工作负载相关的所有事物的集合点--名称、标签、安全属性、生命周期状态事件等。输入 `WorkloadEntry`。

考虑下面的 `ServiceEntry`，描述一个由几十个有 IP 地址的虚拟机实现的服务：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc1
spec:
  hosts:
  - svc1.internal.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  endpoints:
  - address: 1.1.1.1
  - address: 2.2.2.2
  ....
{{< /text >}}

如果您想以主动-主动的方式将这个服务迁移到 Kubernetes 中--即启动一堆 Pod，通过 Istio 双向 TLS（mTLS）将一部分流量发送到 Pod，并将其余的流量发送到没有 Sidecar 的 VM 上--您会怎么做？您需要使用 Kubernetes 服务、虚拟服务和目标规则的组合来实现这一行为。现在，假设您决定将 Sidecar 逐一添加到这些 VM 上，这样您就希望只有到有 Sidecar 的 VM 的流量才会使用 Istio mTLS。如果任何其他服务条目碰巧在其地址中包括相同的 VM，事情就开始变得非常复杂和容易出错。

这些复杂情况的主要来源是 Istio 缺乏对非容器化工作负载的一流定义，其工作负载的属性可以独立于其所属的服务来描述。

{{< image
    link="./workload-entry-first-example.svg"
    alt="Service Entries Pointing to Workload Entries"
    caption="The Internal of Service Entries Pointing to Workload Entries"
    >}}

### 工作负载条目{#workload-entry-a-non-Kubernetes-endpoint}

`WorkloadEntry` 是专门为解决这个问题而创建的。`WorkloadEntry` 允许您描述非 Pod 端点，这些端点应该仍然是网格的一部分，并将其与 Pod 同等对待。从这里开始，一切都变得简单了，比如在工作负载之间启用 `MUTUAL_TLS`，无论它们是否是容器化的。

要创建一个 [`WorkloadEntry`](/zh/docs/reference/config/networking/workload-entry/) 并将其附加到一个 [`ServiceEntry`](/zh/docs/reference/config/networking/service-entry/)上，您可以这样做：

{{< text yaml >}}
---
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  name: vm1
  namespace: ns1
spec:
  address: 1.1.1.1
  labels:
    app: foo
    instance-id: vm-78ad2
    class: vm
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc1
  namespace: ns1
spec:
  hosts:
  - svc1.internal.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  workloadSelector:
    labels:
      app: foo
{{< /text >}}

这将创建一个带有一组标签和地址的新 `WorkloadEntry`，以及使用 `WorkloadSelector` 来选择所有带有所需标签的端点的 `ServiceEntry`，在这种情况下包括为 VM 创建的 `WorkloadEntry`。

{{< image width="75%"
    link="./workload-entry-final.svg"
    alt="Service Entries Pointing to Workload Entries"
    caption="The Internal of Service Entries Pointing to Workload Entries"
    >}}

注意 `ServiceEntry` 可以同时引用 Pod 和 `WorkloadEntry`，使用相同的选择器。现在 Istio 可以对 VM 和 Pod 进行相同的处理，而不是将它们分开。

如果要将一些工作负载迁移到 Kubernetes，且选择保留大量的 VM，则 `WorkloadSelector` 可以同时选择 Pod 和 VM，Istio 会自动在它们之间进行负载平衡。1.6 的变化还意味着 `WorkloadSelector` 可以在 Pod 和 VM 之间同步配置，并且无需手动要求以重复的策略（例如mTLS和授权）将两个基础结构作为目标。Istio 1.6 版本为 Istio 的未来发展提供了一个伟大的起点。能够像描述 Pod 那样描述网状结构之外的东西，会带来更多的好处，比如改善启动体验。然而，这些好处仅仅是副作用。核心的好处是您现在可以让 VM 和 Pod 共存，而不需要任何配置来将两者连接起来。
