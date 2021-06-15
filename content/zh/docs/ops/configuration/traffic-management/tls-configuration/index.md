---
title: 理解 TLS 配置
linktitle: TLS 配置
description: 如何使用 TLS 配置设置安全的网络流量。
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers
test: n/a
---

Istio 非常重要的一个功能是能够锁定并且保护网格内的来往流量。然而配置 TLS 设置可能会令人困惑，并且是配置错误的常见来源。这篇文章尝试去说明在 Istio 内发送请求时，其涉及到的各种相关联系，以及怎样去配置其 TLS 的相关设置。
参考[TLS 配置错误](/zh/docs/ops/common-problems/network-issues/#tls-configuration-mistakes)，该文章总结了一些 TLS 配置的常见问题。

## Sidecars

Sidecar 流量有各种相关的连接，让我们一个个把它们分解开。

{{< image width="100%"
    link="sidecar-connections.svg"
    alt="Sidecar 代理网络连接"
    title="Sidecar 连接"
    caption="Sidecar 代理网络连接"
    >}}

1. **外部入站流量**
    这是被 Sidecar 捕获的来自外部客户端的流量。
    如果客户端在网格外面，该流量可能被 Istio 双向 TLS 加密。
    Sidecar 默认配置 `PERMISSIVE` （宽容）模式：接受 mTLS 和 non-mTLS 的流量。
    该模式能够变更为 `STRICT` （严格）模式，该模式下的流量流量必须是 mTLS；或者变更为 `DISABLE` （禁用）模式，该模式下的流量必须为明文。
    mTLS 模式使用 [`PeerAuthentication` 资源](/zh/docs/reference/config/security/peer_authentication/) 配置。

1. **内部入站流量**
    这是从 Sidecar 流出并引入您的应用服务的流量。流量会保持原样转发。
    注意这并不意味着它总是明文状态，Sidecar 可能也通过 TLS 连接。
    这只意味着一个新的 TLS 连接将不会从 Sidecar 中产生。

1. **内部出站流量**
    这是被 Sidecar 拦截的来自您的应用服务的流量。
    您的应用可能发送明文或者 TLS 的流量。
    如果 [自动选择协议](/zh/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection) 已开启，Istio 将能够自动地选择协议。
    否则您可以在目标服务内使用端口名[手动指定协议](/zh/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)。

1. **外部出站流量**
    这是离开 Sidecar 到一些外部目标的流量。流量会报错原样转发，也可以启动一个 TLS 连接（mTLS 或者标准 TLS）。
    这可以通过 [`DestinationRule` 资源](/zh/docs/reference/config/networking/destination-rule/)中的 `trafficPolicy` 来控制使用的 TLS 模式。
    模式设置为 `DISABLE` 将发生明文，而 `SIMPLE`，`MUTUAL`，和 `ISTIO_MUTUAL` 模式将会发起一个 TLS 连接。

关键要点是：

- `PeerAuthentication` 用于配置 Sidecar 接收的 mTLS 流量类型。
- `DestinationRule` 用于配置 Sidecar 发送的 TLS 流量类型。
- 端口名，或者自动选择协议，决定 sidecar 解析流量的协议。

## 自动 mTLS{#auto-mTLS}

综上所述，`DestinationRule` 控制传出流量是否使用 mTLS。
然而，给每个工作负载配置它非常的枯燥。通常，您希望 Istio 始终使用 mTLS。
在可能的情况下，只将明文发送到不属于网格的工作负载（即没有 Sidecar 的工作负载）。

Istio 通过名为“自动 mTLS”的功能使得配置更改容易。自动 mTLS 将原理如下：
如果在 `DestinationRule` 中没有明确配置 TLS 设置，Sidecar 将会自动选择是否发送 [Istio 双向 TLS](/zh/about/faq/#difference-between-mutual-and-istio-mutual)。
这意味着没有任何配置，所有网格内部的流量将会被 mTLS 加密。

## 网关{#gateways}

通过网关的任何请求都将有两个连接：

{{< image width="100%"
    link="gateway-connections.svg"
    alt="网关网络连接"
    title="网关连接"
    caption="网络连接"
    >}}

1. 入站请求由客户端发起，例如 `curl` 或者 Web 浏览器等。这通常称为“下游”连接。

1. 出站请求由网关向某个后端发起，这通常称为“上游”连接。

这两个连接都有独立的 TLS 配置。

请注意入口与出口网关配置是相同的。
`istio-ingress-gateway` 和 `istio-egress-gateway` 是两个定制化的网关部署。
不同之处在于入口网关的客户端运行在网格之外，而在出口网关的目的地运行在网格之外。

### 入站{#inbound}

作为入站请求的一部分，网关必须对流量进行解码才能应用路由规则。
网关根据 [`Gateway` 资源](/zh/docs/reference/config/networking/gateway/)中的服务配置解码。
例如，如果入站连接是明文的 HTTP，则端口协议配置成 `HTTP`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
...
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
{{< /text >}}

同样，对于原始 TCP 流量，协议将设置为 `TCP`。

对于 TLS 连接，还有更多选项：

1. 封装了什么协议？
    如果连接是 HTTPS，服务协议应该配置成 `HTTPS`。
    反之，对于使用 TLS 封装的原始 TCP 连接，协议应设置为 `TLS`。

1. TLS 连接是终止还是通过？
    对于直通流量，将 TLS 模式字段配置为 `PASSTHROUGH`：

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1beta1
    kind: Gateway
    ...
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH
    {{< /text >}}

    在这种模式下，Istio 将根据 SNI 信息进行路由并将请求按原样转发到目的地。

1. 是否应该使用双向 TLS ？
    相互 TLS 可以通过 TLS 模式 `MUTUAL` 进行配置。配置后，客户端证书将根据配置的 `caCertificates` 或 `credentialName` 请求和验证：

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1beta1
    kind: Gateway
    ...
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: MUTUAL
          caCertificates: ...
    {{< /text >}}

### 出站{#outbound}

出站配置控制会根据入站配置预期的流量类型以及其处理方式来决定网关发送什么类型的流量。TLS 配置在 `DestinationRule` 中，
就像 [Sidecars](#sidecars) 外部出站流量，或者默认[自动 mTLS](#auto-mTLS)。

唯一的区别是您在配置它时，应该小心考虑 `Gateway` 的配置。例如，如果 `Gateway` 配置了 TLS `PASSTHROUGH` 而 `DestinationRule` 配置了 TLS 源，
最终的结果是[双重加密](/zh/docs/ops/common-problems/network-issues/#double-tls)。虽然这是有效的配置，但是这样的行为不是常规配置。

绑定到网关的 `VirtualService` 也需要与 `Gateway` 的定义[确保一致性](/zh//docs/ops/common-problems/network-issues/#gateway-mismatch)
