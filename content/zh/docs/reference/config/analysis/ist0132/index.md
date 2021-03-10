---
title: VirtualServiceHostNotFoundInGateway
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当一个虚拟服务声明了 `host`，但是无法找到相应的网关时，会出现此消息。

## 示例{#example}

您将会收到一下信息：

{{< text plain >}}
Warning [IST0132] (VirtualService testing-service.default testing.yaml:8) one or more host [wrong.com] defined in VirtualService default/testing-service not found in Gateway istio-system/testing-gateway.
{{< /text >}}

当您的集群中包含以下虚拟服务时：

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

同时还包含如下网关:

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
      
在这个示例中，虚拟服务 `testing-service` 拥有域名 `wrong.com` ，但是该域名没有声明在网关 `testing-gateway` 中。

## 解决方案{#How to resolve}

确保虚拟服务中所有 `hosts` 都已绑定到了相应的网关 `hosts` 中。
