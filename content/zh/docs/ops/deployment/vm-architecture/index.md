---
title: 虚拟机架构
description: 阐述 Istio 针对虚拟机的高级架构。
weight: 25
keywords:
- virtual-machine
test: n/a
owner: istio/wg-environments-maintainers
---

阅读本文之前，请先阅读 [Istio 架构](/zh/docs/ops/deployment/architecture/)和[部署模型](/zh/docs/ops/deployment/deployment-models/)。
本页内容的编撰基础为上述这些文档，本文阐述了如何扩展 Istio 将虚拟机接入到网格中。

Istio 对虚拟机的支持允许将 Kubernetes 集群外的工作负载接入到网格。
这能够让传统应用或不适合在容器化环境中运行的应用取得 Istio 为 Kubernetes 内所运行的应用提供的全部优势。

对于在 Kubernetes 上运行的工作负载，Kubernetes 平台本身提供了服务发现、DNS 解析和健康检查等诸多特性，
但这些特性通常不可用于虚拟机环境。Istio 使得虚拟机上运行的工作负载能够具备这些特性，
此外还允许这些工作负载利用 mTLS、富遥测和高级流量管理等 Istio 专属功能。

下图显示了使用虚拟机时的网格架构：

{{< tabset category-name="network-mode" >}}

{{< tab name="单网络" category-value="single" >}}

在这个网格中，存在一个单独的[网络](/zh/docs/ops/deployment/deployment-models/#network-models)，
其中 Pod 和虚拟机彼此之间可以直接通信。

包括 XDS 配置和证书签名在内的控制面流量在集群中通过 Gateway 进行发送。
Pod 和虚拟机彼此之间可以直接通信，无需任何中间 Gateway。

{{< image width="75%"
    link="single-network.svg"
    alt="有单个网络和多个虚拟机的服务网格"
    title="单个网络"
    caption="有单个网络和多个虚拟机的服务网格"
    >}}

{{< /tab >}}

{{< tab name="多网络" category-value="multiple" >}}

在这个网格中，存在多个[网络](/zh/docs/ops/deployment/deployment-models/#network-models)，
其中 Pod 和虚拟机彼此之间不能直接通信。

包括 XDS 配置和证书签名在内的控制面流量在集群中通过 Gateway 进行发送。
类似的，Pod 和虚拟机的所有通信流经作为两个网络之间桥梁的 Gateway。

{{< image width="75%"
    link="multi-network.svg"
    alt="有多个网络和多个虚拟机的服务网格"
    title="多个网络"
    caption="有多个网络和多个虚拟机的服务网格"
    >}}

{{< /tab >}}

{{< /tabset >}}

## 服务关联{#service-association}

Istio 提供了两种机制来表示虚拟机工作负载：

* [`WorkloadGroup`](/zh/docs/reference/config/networking/workload-group/)
  表示共享通用属性的虚拟机工作负载逻辑组合。这类似于 Kubernetes 中的 `Deployment`。
* [`WorkloadEntry`](/zh/docs/reference/config/networking/workload-entry/)
  表示虚拟机工作负载的单个实例。这类似于 Kubernetes 中的 `Pod`。

创建这些资源（`WorkloadGroup` 和 `WorkloadEntry`）不会造成任何资源的制备，也不会运行任何虚拟机负载。
这些资源只是引用这些负载并通知 Istio 如何合理地配置网格。

将虚拟机工作负载添加到网格时，您将需要创建 `WorkloadGroup`，作为每个 `WorkloadEntry` 实例的模板：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: product-vm
spec:
  metadata:
    labels:
      app: product
  template:
    serviceAccount: default
  probe:
    httpGet:
      port: 8080
{{< /text >}}

一旦虚拟机已[被配置并添加到网格](/zh/docs/setup/install/virtual-machine/#configure-the-virtual-machine)，
相应的 `WorkloadEntry` 将被 Istio 控制面自动创建。例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: WorkloadEntry
metadata:
  annotations:
    istio.io/autoRegistrationGroup: product-vm
  labels:
    app: product
  name: product-vm-1.2.3.4
spec:
  address: 1.2.3.4
  labels:
    app: product
  serviceAccount: default
{{< /text >}}

`WorkloadEntry` 资源描述了工作负载的单个实例，类似于 Kubernetes 中的 Pod。
当从网格中移除工作负载时，`WorkloadEntry` 资源将被自动移除。
另外，如果在 `WorkloadGroup` 资源中配置了任何探针，
Istio 控制面将自动更新关联的 `WorkloadEntry` 实例的健康状态。

为了让消费者可靠地调用工作负载，建议声明 `Service` 关联。
这允许客户端到达 `product.default.svc.cluster.local` 这类稳定的主机名，
而不再是一个临时的 IP 地址。这还能让您在 Istio 中通过 `DestinationRule`
和 `VirtualService` API 使用高级的路由能力。

所有 Kubernetes 服务都可以通过分别与 Pod 和 `WorkloadEntry`
标签匹配的选择算符字段在 Pod 和虚拟机之间选择工作负载。

例如，名为 `product` 的 `Service` 由 `Pod` 和 `WorkloadEntry` 组成：

{{< image width="30%"
    link="service-selector.svg"
    title="服务选择"
    >}}

使用此配置，对 `product` 的请求将在 Pod 和虚拟机工作负载实例之间进行负载均衡。

## DNS

Kubernetes 在 Pod 中为 `Service` 名称提供了 DNS 解析，允许 Pod 通过稳定的主机名在彼此之间轻松通信。

对于虚拟机扩展，Istio 通过 [DNS 代理](/zh/docs/ops/configuration/traffic-management/dns-proxy/)提供了类似的功能。
此特性会将来自虚拟机工作负载的所有 DNS 查询重定向至 Istio 代理，保持主机名到 IP 地址的映射。

因此虚拟机上运行的工作负载可以透明地调用 `Service`（类似于 Pod），无需任何其他配置。
