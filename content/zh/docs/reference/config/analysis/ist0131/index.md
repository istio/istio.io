---
title: VirtualServiceIneffectiveMatch
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 VirtualService 包含一条因为旧规则指定了相同的匹配而永远不会使用的匹配规则时，会出现此消息。

## 示例 {#example}

当您的集群中包含下列 VirtualService 时：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tls-routing
spec:
  hosts:
  - www1.googleapis.com
  - api1.facebook.com
  tls:
  - match:
    - port: 2443
      sniHosts:
      - www1.googleapis.com
    route:
    - destination:
        host: www1.googleapis.com
  - match:
    - port: 2443
      sniHosts:
      - www1.googleapis.com
    route:
    - destination:
        host: api1.facebook.com
{{< /text >}}

您将会收到以下消息：

{{< text plain >}}
Info [IST0131] (VirtualService tls-routing.default) VirtualService rule #1 match #0 is not used (duplicates a match in rule #0).
{{< /text >}}

在这个示例中，VirtualService 对两个不同的目的地指定了相同的匹配规则。
Istio 会使用第一个匹配规则，并且不会转发任何流量到第二个目的地。

## 如何修复 {#how-to-resolve}

如果您需要流量能够流向多个目的地，请使用 `mirror`。

重新排列您的路由，将最具体的路由放在第一个，将 'catch all' 路由放到最后。
