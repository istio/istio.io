---
title: ConflictingMeshGatewayVirtualServiceHosts
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 Istio 检测到因 [VirtualService](/zh/docs/reference/config/networking/virtual-service)
资源重复而导致冲突时，会出现此消息。比如，多个 VirtualService 使用相同的主机名且连接网格 Gateway 时，
会出现一条错误消息。需要注意的是，Istio 支持合并挂接到入口网关的 VirtualService。

## 解决方案 {#resolution}

解决该问题，有如下几个方法：

* 将冲突的 VirtualService 合并为一个
* 连接 Gateway 的 VirtualService 使用唯一的主机名
* 通过设置 `exportTo` 字段，将资源范围限定到指定的命名空间。

## 示例 {#examples}

命名空间 `team1` 的 VirtualService `productpage` 与命名空间 `team2` 的 VirtualService `custom` 存在冲突的原因如下：

* 因为自定义 Gateway 未被指定，所以 VirtualService 挂接到了默认的 "mesh" Gateway。
* VirtualService 都定义了相同的主机 `productpage.default.svc.cluster.local`。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
  namespace: team-1
spec:
  hosts:
  - productpage.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: productpage
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: custom
  namespace: team-2
spec:
  hosts:
  - productpage.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: productpage.team-2.svc.cluster.local
---
{{< /text >}}

您可以通过设置 `exportTo` 字段为 `.` 来解决此问题，让每个 VirtualService 都只限定在自己的命名空间：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productpage
  namespace: team-1
spec:
  exportTo:
  - "."
  hosts:
  - productpage.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: productpage
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: custom
  namespace: team-2
spec:
  exportTo:
  - "."
  hosts:
  - productpage.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: productpage.team-2.svc.cluster.local
---
{{< /text >}}
