---
title: GatewayPortNotOnWorkload
layout: analysis-message
---

当网关（通常为 `istio-ingressgateway`）提供了一个端口，而该端口并非由网关选择的 Kubernetes service 工作负载提供时，将触发此消息。

例如，您的 Istio 配置包含以下值:

{{< text yaml >}}
# Gateway with bogus port

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
  - port:
      number: 8004
      name: http2
      protocol: HTTP
    hosts:
    - "*"
{{< /text >}}

在本例中，出现 `GatewayPortNotOnWorkload` 消息是因为此配置使用了端口8004，但默认的 `IngressGateway` 仅打开了端口80、443、31400和15443。

要解决此问题，请更改网关配置，在工作负载上使用有效端口，然后重试。
