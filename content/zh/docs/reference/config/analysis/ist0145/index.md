---
title: ConflictingGateways
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当两个或多个 `Gateway` 资源选择了同一个网关工作负载、使用相同的端口，
并且其主机相同或存在重叠时，会出现此消息。这些服务器中只有一个可以被使用。

## 示例 {#example}

假设有以下两个 `Gateway` 资源：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: alpha
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "foo.example.com"
---
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: beta
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*.example.com"
{{< /text >}}

您将收到以下消息：

{{< text plain >}}
Error [IST0145] (Gateway default/alpha) Conflict with gateways default/beta (workload selector istio=ingressgateway, port 80, hosts foo.example.com).
{{< /text >}}

## 如何修复 {#how-to-resolve}

执行以下操作之一：

- 将这些主机放在同一个 `Gateway` 资源中。
- 确保主机之间不存在重叠。
- 为其中一个 `Gateway` 资源使用不同的端口或不同的网关工作负载。
