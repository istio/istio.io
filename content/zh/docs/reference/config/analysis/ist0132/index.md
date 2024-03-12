---
title: VirtualServiceHostNotFoundInGateway
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当一个 VirtualService 声明了 `host` 但无法找到相应的网关时，会出现此消息。

## 示例 {#example}

当您的集群中包含以下 VirtualService 时：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: testing-service
  namespace: default
spec:
  gateways:
  - istio-system/testing-gateway
  hosts:
  - wrong.com
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: ratings
{{< /text >}}

同时还包含如下 Gateway:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: testing-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - testing.com
    port:
      name: http
      number: 80
      protocol: HTTP
{{< /text >}}

您将会收到以下消息：

{{< text plain >}}
Warning [IST0132] (VirtualService testing-service.default testing.yaml:8) one or more host [wrong.com] defined in VirtualService default/testing-service not found in Gateway istio-system/testing-gateway.
{{< /text >}}

在这个示例中， VirtualService `testing-service` 拥有域名 `wrong.com`，
但是该域名没有声明在网关 `testing-gateway` 中。

## 如何修复 {#how-to-resolve}

确保 VirtualService 中所有 `hosts` 都已绑定到了相应的网关 `hosts` 中。
