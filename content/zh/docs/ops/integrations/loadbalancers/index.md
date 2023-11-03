---
title: 第三方负载均衡器
description: Istio 如何集成第三方负载均衡器。
weight: 90
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: n/a
---

Istio 提供了 Ingress 和服务网格实现，可以一起使用，也可以分开使用。
尽管它们设计为无缝协同工作，但有时需要与第三方 Ingress 集成。
这可能是出于迁移目的、功能要求或个人偏好。

## 集成模式 {#integration-modes}

在“独立（standalone）”模式下，第三方 Ingress 直接发送到后端。
在这种情况下，后端可能已注入了 Istio Sidecar。

{{< mermaid >}}
graph LR
    cc((客户端))
    tpi(第三方 Ingress)
    a(后端)
    cc-->tpi-->a
{{< /mermaid >}}

在这种模式下，大部分工作都是正常的。
服务网格中的客户端无需知道它们连接的后端是否具有 Sidecar。
但是，Ingress 将不使用 mTLS，这可能会导致非预期的行为。
因此，此设置的大部分配置都与启用 mTLS 有关。

在“链路（chained）”模式下，我们按顺序使用第三方 Ingress 和 Istio
自己的 Gateway。这对于想要两层功能的情况会很有用。特别是，
这在托管云负载均衡器中非常有用，因为云负载均衡器具有全局地址和托管证书等特性。

{{< mermaid >}}
graph LR
    cc((客户端))
    tpi(第三方 Ingress)
    ii(Istio Gateway)
    a(后端)
    cc-->tpi
    tpi-->ii
    ii-->a
{{< /mermaid >}}

## 云负载均衡器 {#cloud-load-balancers}

通常情况下，云负载均衡器在独立模式下无需使用 mTLS 即可正常工作。
需要特定的供应商配置才能支持链路模式或启用 mTLS 的独立模式。

### Google HTTP 和 HTTPS 负载均衡器 {#google-https-load-balancer}

Google HTTP 和 HTTPS 负载均衡器的集成只适用于独立模式，
如果不需要 mTLS，则可以直接使用，因为不支持 mTLS。

链路模式是可能的。有关设置说明，请参见
[Google 文档](https://cloud.google.com/architecture/exposing-service-mesh-apps-through-gke-ingress)。

## 集群中负载均衡器 {#in-cluster-load-balancers}

通常，集群中的负载均衡器在独立模式下无需使用 mTLS 即可正常工作。

可以通过将 Sidecar 插入到集群中负载均衡器的 Pod 中来实现带 mTLS 的独立模式。
这通常需要超出标准 Sidecar 注入的两个步骤：

1. 禁用入站流量重定向。
   虽然不是必需的，但通常我们只想使用 Sidecar 处理**出站**流量。
   来自客户端的入站连接已由负载均衡器本身处理。
   这还允许保留原始客户端 IP 地址，否则该地址将丢失在 Sidecar 中。
   可以通过在负载均衡器 `Pod` 上插入 `traffic.sidecar.istio.io/includeInboundPorts: ""`
   注解来启用此模式。
1. 启用服务路由。
   当请求发送到服务而不是特定的 Pod IP 时，Istio Sidecar 才能正常工作。
   大多数负载均衡器默认会发送到特定的 Pod IP，从而破坏 mTLS。
   执行此操作的步骤是特定于供应商的；下面列出了一些示例，但建议查阅具体供应商的文档。

   另外将 `Host` 标头设置为服务名称也可以起作用。
   但是，这可能会导致意外行为；负载均衡器将选择特定的 Pod，但 Istio 将忽略它。
   有关为什么这样做的更多信息，
   请参见[此处](/zh/docs/ops/configuration/traffic-management/traffic-routing/#http)。

### ingress-nginx

可以通过在 `Ingress` 资源上插入注解来配置 `ingress-nginx` 以执行服务路由：

{{< text yaml >}}
nginx.ingress.kubernetes.io/service-upstream: "true"
{{< /text >}}

### Emissary-Ingress

Emissary-ingress 默认使用服务路由，因此无需其他步骤。
