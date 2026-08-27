---
title: 使用 agentgateway
description: 将 agentgateway 配置为入口网关和 Ambient 模式下的 waypoint。
weight: 40
owner: istio/wg-networking-maintainers
test: yes
---

{{< boilerplate experimental-feature-warning >}}

[agentgateway](https://agentgateway.dev) 是一个数据平面代理，
可用作 Envoy 的替代品。它专为 AI 代理和[模型上下文协议 (MCP)](https://modelcontextprotocol.io) 流量而构建，
同时还支持通用 L7 路由。启用 agentgateway 后，Istio 可以对其进行编程，
以代替 Envoy 在 {{< gloss "ambient" >}}ambient 网格{{< /gloss >}}中扮演两个角色：

* 作为**入口网关**，处理进入网格的南北流量，以及
* 作为一个 {{< gloss >}}waypoint{{< /gloss >}} 代理，处理一组工作负载的东西向 L7 处理。

本指南介绍了集成的工作原理、支持的 API，
以及如何安装 Istio 并针对每种角色配置 agentgateway。

## 集成是如何运作的 {#how-the-integration-works}

Istiod **仅通过 Kubernetes Gateway API 资源**配置 agentgateway，
并通过 xDS 将其传递给代理。代理是与 Envoy 不同的 {{< gloss >}}data plane{{< /gloss >}} 实现：
当 `Gateway` 选择一个 agentgateway
[`GatewayClass`](https://gateway-api.sigs.k8s.io/api-types/gatewayclass/) 时，
Istiod 为其配置和管理 agentgateway `Deployment` 和 `Service`，
就像管理 Istio 基于 Envoy 的那样网关。

Enabling agentgateway registers two `GatewayClass` resources:
启用 agentgateway 会注册两个 `GatewayClass` 资源：

| `GatewayClass` | 控制器 | 角色 |
| -------------- | ---------- | ---- |
| `istio-agentgateway` | `istio.io/agentgateway-controller` | 入口网关 |
| `istio-agentgateway-waypoint` | `istio.io/agentgateway-waypoint-controller` | waypoint 代理 |

由于数据平面是通过 `gatewayClassName` 字段针对每个 `Gateway` 选择的，
因此 agentgateway 和 Istio 默认的基于 Envoy 的网关和 waypoint 可以在同一集群中共存。
您只需引用上述类之一即可为特定网关或 waypoint 选择 agentgateway。

## 受支持与不受支持的配置 {#supported-and-unsupported-configuration}

Istio 支持 agentgateway 的以下 [Gateway API](https://gateway-api.sigs.k8s.io/) 资源：

* `Gateway`（使用 `istio-agentgateway` 或 `istio-agentgateway-waypoint` 类）
* `HTTPRoute`、`GRPCRoute`、`TCPRoute` 和 `TLSRoute`
* `InferencePool`，来自 [Gateway API 推理扩展](https://gateway-api-inference-extension.sigs.k8s.io/)，用于路由到 AI 推理工作负载

{{< warning >}}
Istio **仅**通过上面列出的 Gateway API 资源配置 agentgateway。
Istio 自己的配置 API — 例如 `VirtualService`、`DestinationRule`、`Sidecar`、
`AuthorizationPolicy`、`PeerAuthentication`、`RequestAuthentication`、
`Telemetry`、`WasmPlugin` 和 `EnvoyFilter` — **不**应用于 agentgateway 代理。
请改用 Gateway API 来表达路由和策略。

agentgateway 自己的本机配置格式和自定义资源同样不由 Istio 管理；
Istio 仅通过本指南中描述的 Gateway API 资源对代理进行编程。
{{< /warning >}}

## 开始之前 {#before-you-begin}

{{< boilerplate gateway-api-install-crds >}}

### 安装启用了 agentgateway 的 Istio {#install-istio-with-agentgateway-enabled}

agentgateway 支持在 istiod 上的 `PILOT_ENABLE_AGENTGATEWAY` 功能标志后面进行门控，
默认情况下处于禁用状态。使用 `ambient` 配置文件并启用该标志来安装 Istio。
需要 `ambient` 配置文件，以便也注册 waypoint `GatewayClass`：

{{< text syntax=bash snip_id=install_istio >}}
$ istioctl install --set profile=ambient --set values.pilot.env.PILOT_ENABLE_AGENTGATEWAY=true -y
{{< /text >}}

{{< tip >}}
使用 Helm 安装时，使用 `--set pilot.env.PILOT_ENABLE_AGENTGATEWAY=true`
在 `istiod` Chart 上设置相同的标志。
{{< /tip >}}

确认两个 agentgateway `GatewayClass` 资源均已注册：

{{< text syntax=bash snip_id=verify_gateway_classes >}}
$ kubectl get gatewayclass istio-agentgateway istio-agentgateway-waypoint
NAME                          CONTROLLER                                  ACCEPTED   AGE
istio-agentgateway            istio.io/agentgateway-controller            True       30s
istio-agentgateway-waypoint   istio.io/agentgateway-waypoint-controller   True       30s
{{< /text >}}

### 部署示例应用程序 {#deploy-a-sample-application}

部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序，本指南中的示例将使用该应用程序：

{{< text syntax=bash snip_id=deploy_bookinfo >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
{{< /text >}}

## 将 agentgateway 配置为入口网关 {#configure-agentgateway-as-an-ingress-gateway}

要将 agentgateway 用作入口网关，请创建一个引用 `istio-agentgateway` 类的 `Gateway`。
Istiod 自动配置和管理相应的 agentgateway 部署。

{{< text syntax=bash snip_id=deploy_ingress_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bookinfo-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio-agentgateway
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

`gatewayClassName: istio-agentgateway` 字段用于选择 agentgateway 数据平面而不是 Envoy。
默认情况下，Istio 为网关创建一个 `LoadBalancer` 服务；
`networking.istio.io/service-type: ClusterIP` 注解请求 `ClusterIP` 服务，
以便可以使用本指南中的 `kubectl port-forward` 访问网关。

附加一个 `HTTPRoute` 以通过网关公开 `productpage` 服务：

{{< text syntax=bash snip_id=deploy_ingress_route >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookinfo
spec:
  parentRefs:
  - name: bookinfo-gateway
  rules:
  - matches:
    - path:
        type: Exact
        value: /productpage
    - path:
        type: PathPrefix
        value: /static
    - path:
        type: Exact
        value: /login
    - path:
        type: PathPrefix
        value: /api/v1/products
    backendRefs:
    - name: productpage
      port: 9080
EOF
{{< /text >}}

确认网关已配置并编程。`CLASS` 列显示 agentgateway 类：

{{< text syntax=bash snip_id=verify_ingress_gateway >}}
$ kubectl get gateway bookinfo-gateway
NAME               CLASS                ADDRESS                                      PROGRAMMED   AGE
bookinfo-gateway   istio-agentgateway   bookinfo-gateway.default.svc.cluster.local   True         30s
{{< /text >}}

您现在可以通过 agentgateway 入口网关访问应用程序。
将本地端口转发到网关服务并在浏览器中打开 `http://localhost:8080/productpage`：

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway 8080:80
{{< /text >}}

## 将 agentgateway 配置为 waypoint {#configure-agentgateway-as-a-waypoint}

waypoint 代理将 L7 处理添加到 Ambient 网格中的一组工作负载。
要使用 agentgateway 担任此角色，请部署引用 `istio-agentgateway-waypoint` 类的 `Gateway`。

首先，确认命名空间已在 Ambient 数据平面中注册：

{{< text syntax=bash snip_id=label_ambient >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
namespace/default labeled
{{< /text >}}

{{< warning >}}
`istioctl waypoint` 子命令（`apply`、`generate`、`list` 和 `status`）目前仅支持默认的基于
Envoy 的 `istio-waypoint` 类。要部署 agentgateway waypoint，请直接应用 `Gateway` 资源，如下所示。
{{< /warning >}}

部署 waypoint。与所有 waypoint 一样，它必须使用 `HBONE` 协议在端口
`15008` 上定义一个名为 `mesh` 的监听器；与 Envoy waypoint 的唯一区别是 `gatewayClassName`：

{{< text syntax=bash snip_id=deploy_waypoint >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: agentgateway-waypoint
  labels:
    istio.io/waypoint-for: service
spec:
  gatewayClassName: istio-agentgateway-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

确认 waypoint 已配置：

{{< text syntax=bash snip_id=verify_waypoint >}}
$ kubectl get gateway agentgateway-waypoint
NAME                    CLASS                         ADDRESS        PROGRAMMED   AGE
agentgateway-waypoint   istio-agentgateway-waypoint   10.96.15.112   True         30s
{{< /text >}}

通过添加包含 waypoint 名称的 `istio.io/use-waypoint` 标签来注册服务以使用 waypoint。
例如，要通过 agentgateway waypoint 发送发往 `reviews` 服务的流量：

{{< text syntax=bash snip_id=enroll_waypoint >}}
$ kubectl label service reviews istio.io/use-waypoint=agentgateway-waypoint
service/reviews labeled
{{< /text >}}

从 Ambient 网格中的工作负载到 `reviews` 服务的请求现在通过 agentgateway waypoint 进行路由以进行 L7 处理。
要了解有关注册命名空间、Service 和 Pod 以及 waypoint 如何处理不同流量类型的更多信息，
请参阅[配置 waypoint 代理](/zh/docs/ambient/usage/waypoint/)。

若要在 waypoint 处应用 L7 路由策略，请将 Gateway API 路由关联到 `Service`，
并使用 `kind` 为 `Service` 的 `parentRef`。例如，
以下 `HTTPRoute` 将 `reviews` 服务的 90% 流量发送至 `reviews-v1`，其余 10% 发送至 `reviews-v2`：

{{< text syntax=yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
{{< /text >}}

## 清理 {#cleanup}

删除入口网关及其路由：

{{< text syntax=bash snip_id=cleanup_ingress >}}
$ kubectl delete httproute bookinfo
$ kubectl delete gateway bookinfo-gateway
{{< /text >}}

删除 waypoint 并取消注册 `reviews` 服务：

{{< text syntax=bash snip_id=cleanup_waypoint >}}
$ kubectl label service reviews istio.io/use-waypoint-
$ kubectl delete gateway agentgateway-waypoint
{{< /text >}}

删除示例应用程序和 Ambient 标签：

{{< text syntax=bash snip_id=cleanup_bookinfo >}}
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

卸载 Istio：

{{< text syntax=bash snip_id=uninstall_istio >}}
$ istioctl uninstall --purge -y
$ kubectl delete namespace istio-system
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
