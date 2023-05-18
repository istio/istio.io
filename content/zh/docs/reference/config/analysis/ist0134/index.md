---
title: ServiceEntryAddressesRequired
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 ServiceEntry 的 `protocol` 字段未设置、设置为 `TCP` 或未定义 `addresses` 时，会出现此消息。

## 示例 {#example}

您将收到以下消息：

{{< text plain >}}
Warning [IST0134] (ServiceEntry service-entry.default serviceentry.yaml:13) ServiceEntry addresses are required for this protocol.
{{< /text >}}

当集群的 `ServiceEntry` 未设置 `protocol` 且缺少 `addresses` 时：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: service-entry
  namespace: default
spec:
  hosts:
    - 'istio.io'
  exportTo:
    - "."
  ports:
    - number: 443
      name: https
  location: MESH_EXTERNAL
  resolution: DNS
{{< /text >}}

这种分析器的另一个例子是 `ServiceEntry` 设置了 `protocol: TCP` 但缺少 `addresses` 时：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: service-entry
  namespace: default
spec:
  hosts:
    - 'istio.io'
  exportTo:
    - "."
  ports:
    - number: 443
      name: https
      protocol: TCP
  location: MESH_EXTERNAL
  resolution: DNS
{{< /text >}}

## 解决方案 {#how-to-resolve}

请确保在 `protocol` 未设置或设置为 TCP 时，在 ServiceEntry 中设置 `addresses`。
如果未设置 `addresses`，则将匹配 ServiceEntry 所定义的端口上的所有流量，与主机无关。
