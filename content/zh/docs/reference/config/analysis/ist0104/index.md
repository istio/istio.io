---
title: GatewayPortNotOnWorkload
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 Gateway（通常为 `istio-ingressgateway`）提供了一个端口，而该端口并非 Kubernetes service 工作负载选择的端口时，将触发此消息。

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

在本例中，出现 `GatewayPortNotOnWorkload` 消息是因为此配置使用了 8004 端口，但默认的 `IngressGateway` 仅打开了 80、443、31400 和 15443 端口。

要解决此问题，请更改网关配置，在工作负载上使用有效端口，然后重试。
