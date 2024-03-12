---
title: GatewayPortNotDefinedOnService
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 Gateway（通常是 `istio-ingressgateway`）
提供的端口与网关实例关联的 Kubernetes 服务（Service）
定义的端口不匹配时，`GatewayPortNotDefinedOnService` 消息将会出现。

例如，您的配置定义如下：

{{< text yaml >}}
# 端口定义错误的 Gateway

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-ingressgateway
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
---

# 默认的网关 Service

apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
spec:
  selector:
    istio: ingressgateway
  ports:
  - name: status-port
    port: 15021
    protocol: TCP
    targetPort: 15021
  - name: http2
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    port: 443
    protocol: TCP
    targetPort: 8443
{{< /text >}}

在此示例中，因为配置使用了端口 `8004`，但默认的 `IngressGateway`
（名称为 `istio-ingressgateway`）只定义了目标端口 15021、8080 和 8443，
所以 `GatewayPortNotDefinedOnService` 消息出现。

要解决此问题，请更改网关配置以使用工作负载上的有效端口，然后重试。

以下是已更正的示例：

{{< text yaml >}}
# 端口定义正确的 Gateway

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-ingressgateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 8080
      name: http2
      protocol: HTTP
    hosts:
    - "*"
  - port:
      number: 8443
      name: https
      protocol: HTTP
    hosts:
    - "*"
{{< /text >}}
