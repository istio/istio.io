---
title: 部署和配置指南
description: 提供特定的部署和配置指南。
weight: 5
---

本节提供了特定的部署或配置指南，以避免网络或流量管理问题。

## 同一主机的多个 `VirtualServices` 和 `DestinationRules`

在以下情况下中最好为指定主机以增量的方式配置多个资源。
1. 不方便定义完整的路由规则
1. 单个 `VirtualService` 或 `DestinationRule` 资源中特定主机策略，

从 Istio 1.0.1 开始，添加了一个实验性功能，在绑定到网关时来合并这些 `VirtualService` 的目标规则。

考虑绑定到 ingress gateway 的 `VirtualService` 情况，该 ingress gateway 暴露了一个应用程序主机，
该主机使用基于路径的委托的多个实现服务，如下所示：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

这种配置的缺点是，任何底层微服务的其他配置（例如，路由规则）也需要包含在该配置文件中，
而不是包含在与之相关联并且可能由各个服务团队拥有的单独配置文件中。有关详细信息，
请参阅[路由规则对 ingress gateway 请求不生效](#路由规则对-ingress-gateway-请求不生效)。

为了避免这个问题，可能最好将 `myapp.com` 的配置分解为几个 `VirtualService` 片段，每个后端服务一个。例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-service1
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service1
    route:
    - destination:
        host: service1.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-service2
spec:
  hosts:
  - myapp.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /service2
    route:
    - destination:
        host: service2.default.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp-...
{{< /text >}}

当应用现有主机的第二个和后续的 `VirtualService` 时，`istio-pilot` 会将其他路由规则合并到主机的现有配置中。但是，有一些注意事项，使用时必须仔细考虑。

1. 虽然将保留任何给定源 `VirtualService` 中规则的评估顺序，但跨资源顺序是 UNDEFINED。换句话说，
   对于片段配置中的规则没有保证的评估顺序，因此只有在跨资源的规则资源之间没有规则冲突或顺序依赖的情况下，
   合并后的行为才是可预测的。
1. 片段中应该只有一个“全部捕获”规则（即，匹配任何请求路径或 header 的规则）。所有这些“全部捕获”规则会被移动到合并配置列表的末尾，由于它们捕获所有请求，
   最先应用的规则会覆盖和禁用其他所有的规则
1. sidecar 不支持主机合并，只有绑定到网关支持 `VirtualService` 分段方式。

`DestinationRule` 也可以使用类似的合并语义和限制进行分段。

1. 对于同一主机，跨多个目标规则应该只有一个给定子集的定义。如果存在多个具有相同名称的定义，则使用第一个定义，其他重复项将失效。不支持合并子集内容。
1. 对于同一主机，应该只有一个顶级的 `trafficPolicy`。在多个目标规则中定义顶级流量策略时，将使用第一个。任何以下顶级 `trafficPolicy` 配置都将失效。
1. 不同于 `VirtualService` 的合并，目标规则合并在 sidecar 和网关中都有效。

## 重新配置服务路由时出现 503 错误

在设置路由规则以将流量路由到服务的特定版本（子集）时，必须注意确保子集在路由使用之前可用。否则，
在重新配置期间，调用服务可能返回 503 错误。

调用单个 `kubectl` 命令（例如，`kubectl apply -f myVirtualServiceAndDestinationRule.yaml`）来同时创建对应子集中的 `VirtualServices` 和 `DestinationRule` 是不够的，这是因为配置（从配置服务器，即 Kubernetes API 服务器）传播到 Pilot 实例是以最终一致的方式进行的。如果子集中的 `VirtualService` 在 `DestinationRule` 之前生效，Pilot 生成的 Envoy 配置将引用不存在的上游服务池。在所有配置对象都可用于 Pilot 之前，请求调用将导致 HTTP 503 错误。

要确保在使用子集配置路由时保证服务零停机时间，请按照 “make-before-break” 过程进行操作，如下所述：

* 添加新子集时：

    1. 首先将 `DestinationRules` 添加到新子集，然后再更新 `VirtualServices` 配置去使用 `DestinationRules`。使用 `kubectl` 或特定于平台的工具应用规则。

    1. 等待几秒钟，以便 `DestinationRule` 配置传播至 Envoy sidecar。

    1. 更新 `VirtualService` 使用新添加的子集。

* 删除子集时：

    1. 在将 `DestinationRule` 从子集删除之前，首先更新 `VirtualServices` 以保证其不再引用即将删除的 `DestinationRule`。

    1. 等待几秒钟，以便 `VirtualService` 配置传播至 Envoy sidecar。

    1. 在未使用的子集中删除 `DestinationRule`。

## 路由规则对 ingress gateway 请求不生效

假设正在使用入口 `Gateway` 和对应的 `VirtualService` 来访问内部服务。
例如， `VirtualService` 看起来像这样：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # 或者如果您使用入口网关 IP 进行无 DNS 验证，则可能值为"*"（例如，http：//1.2.3.4/hello）
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
  - match:
    ...
{{< /text >}}

同时我们还有另外一个 `VirtualService`，用于将 helloworld 服务的流量路由到特定子集：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.default.svc.cluster.local
    http:
  - route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

在这种情况下，通过 ingress gateway 向 helloworld 服务发出的请求不会被定向到子集 v1，而是继续使用默认的轮询路由。

入口请求正在使用网关主机（例如，`myapp.com`），该主机将使用 myapp 中 `VirtualService` 的规则，路由请求到 helloworld 服务中的任一端点。主机 `helloworld.default.svc.cluster.local` 的内部请求将使用 helloworld 中 `VirtualService`，将流量定向到子集 v1。

要控制来自网关的流量，需要在 myapp 中的 `VirtualService` 中包含子集规则：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - "myapp.com" # 或者如果您使用 ingress gateway  IP 进行无 DNS 验证，则可能值为"*"（例如，http：//1.2.3.4/hello）
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    ...
{{< /text >}}

或者，如果可能，可以将两个 `VirtualServices` 组合到一个单元中：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.com # 这里不能使用"*"，因为它与网格服务相结合
  - helloworld.default.svc.cluster.local
  gateways:
  - mesh # 适用于内部和外部
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /hello
      gateways:
      - myapp-gateway # 此限制规则仅适用于 ingress gateway
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
  - match:
    - gateways:
      - mesh # 适用于网格内的所有服务
    route:
    - destination:
        host: helloworld.default.svc.cluster.local
        subset: v1
{{< /text >}}

## 路由规则对应用程序不生效

如果路由规则对 [Bookinfo](/zh/docs/examples/bookinfo/) 示例正常运行，但类似的版本路由规则对自己的应用程序没有生效，则可能需要更改 Kubernetes 服务。

Kubernetes 服务必须遵守某些限制才能利用 Istio 的 L7 路由功能。有关详细信息，请参阅 [Pod 和服务的要求](/zh/docs/setup/kubernetes/spec-requirements)。

## Envoy 无法连接到 HTTP/1.0 服务

Envoy 需要使用 `HTTP/1.1` 或 `HTTP/2` 与上游服务通信。例如，当使用 [NGINX](https://www.nginx.com/)  作为 Envoy 后端提供流量服务时，需要将 NGINX 配置中的  [proxy_http_version](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_http_version)  指令设置为 “1.1”，因为 NGINX 默认值为 1.0。

配置样例如下：

{{< text plain >}}
upstream http_backend {
    server 127.0.0.1:8080;

    keepalive 16;
}

server {
    ...

    location /http/ {
        proxy_pass http://http_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        ...
    }
}
{{< /text >}}

## Headless TCP 服务失去连接

如果部署了 `istio-citadel`，则 Envoy 每 15 分钟会进行一次重新启动来刷新证书。这会导致 TCP 连接或服务之间长连接被断开。

在应用程序中应为此类断开连接进行弹性处理，但如果仍希望防止断开连接发生，则需要禁用双向 TLS 和 `istio-citadel` 部署。

首先，编辑 `istio` 配置以禁用双向 TLS：

{{< text bash >}}
$ kubectl edit configmap -n istio-system istio
$ kubectl delete pods -n istio-system -l istio=pilot
{{< /text >}}

接着，缩减 `istio-citadel` 部署来禁止 Envoy 重启：

{{< text bash >}}
$ kubectl scale --replicas=0 deploy/istio-citadel -n istio-system
{{< /text >}}

通过以上步骤则可以防止 Istio 重新启动 Envoy 导致的 TCP 连接断开。