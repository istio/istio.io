---
title: VirtualServiceIneffectiveMatch
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当虚拟服务包含一个永远不会使用的匹配规则时，会出现此消息，因为之前的规则中指定了相同的匹配规则。

## 示例{#example}

您将会收到一下信息：

{{< text plain >}}
Info [IST0131] (VirtualService tls-routing.default) VirtualService rule #1 match #0 is not used (duplicates a match in rule #0).
{{< /text >}}

当您的集群中包含下列虚拟服务时：

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
      
在这个示例中，虚拟服务对两个不同的目的地指定了相同的匹配规则。Istio 会使用第一个匹配规则，并且不会转发任何流量到第二个目的地。 

## 解决方案{#how-to-resolve}

如果你需要流量能够流向多个目的地，请使用 `mirror`。

重新排列您的路线，将最具体的路由放在前面。请在最后配置 'catch all' 路线。