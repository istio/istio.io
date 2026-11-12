---
title: GatewayDuplicateCertificate
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当选择同一网关工作负载的两个或多个 `Gateway` 资源使用相同的 TLS 证书时，会出现此消息。

浏览器等客户端可以对证书覆盖的所有主机使用同一个 HTTP/2 连接。
如果这些主机位于不同的 `Gateway` 资源中，网关可能会在为另一个 `Gateway`
打开的连接上收到某个主机的请求，此时网关会返回 `404` 响应。

当服务器使用相同的 `credentialName`，或相同的 `serverCertificate` 和 `privateKey` 时，
分析器会将其识别为相同的证书。

## 示例 {#example}

假设有两个 `Gateway` 资源选择了同一个工作负载，并使用相同的 `credentialName`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway-a
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - a.example.com
    tls:
      mode: SIMPLE
      credentialName: example-com-cert
---
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: gateway-b
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - b.example.com
    tls:
      mode: SIMPLE
      credentialName: example-com-cert
{{< /text >}}

您将收到以下消息：

{{< text plain >}}
Warning [IST0138] (Gateway default/gateway-a) Duplicate certificate in multiple gateways [default/gateway-a default/gateway-b] may cause 404s if clients re-use HTTP2 connections.
{{< /text >}}

## 如何修复 {#how-to-resolve}

执行以下操作之一：

- 将共享该证书的所有主机放在同一个 `Gateway` 的同一个服务器中。
- 为每个 `Gateway` 使用不同的证书。
