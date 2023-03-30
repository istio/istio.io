---
title: Kubernetes Gateway API
description: 描述在 Istio 中如何配置 Kubernetes Gateway API。
weight: 50
aliases:
    - /zh/docs/tasks/traffic-management/ingress/service-apis/
    - /latest/zh/docs/tasks/traffic-management/ingress/service-apis/
keywords: [traffic-management,ingress, gateway-api]
owner: istio/wg-networking-maintainers
test: yes
---

本文描述 Istio 和 Kubernetes API 之间的差异，并提供了一个简单的例子，
向您演示如何配置 Istio 以使用 Gateway API 在服务网格集群外部暴露服务。
请注意，这些 API 是 Kubernetes [Service](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/)
和 [Ingress](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/) API 的积极发展演进。

{{< tip >}}
许多 Istio 流量管理文档均囊括了 Istio 或 Kubernetes API 的使用说明
（例如请参阅[控制入站流量](/zh/docs/tasks/traffic-management/ingress/ingress-control)）。
通过参照[入门指南](/zh/docs/setup/additional-setup/getting-started/)，
您甚至从一开始就可以使用 Gateway API。
{{< /tip >}}

## 设置 {#setup}

1. 在大多数 Kubernetes 集群中，默认情况下不会安装 Gateway API。如果 Gateway API CRD 不存在，请安装：

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

1. 使用 `minimal` 配置安装 Istio:

    {{< text bash >}}
    $ istioctl install --set profile=minimal -y
    {{< /text >}}

## 与 Istio API 的区别{#differences-from-istio-apis}

Gateway API 与 Istio API （如 Gateway 和 VirtualService）有很多相似之处。
主资源使用相同的`Gateway`名称，并且这些资源服务于相类似的目标。

新的 Gateway API 致力于从 Kubernetes 的各种 Ingress 实现（包括 Istio）中吸取经验，
以构建标准化的，独立于供应商的 API。
这些 API 通常与 Istio Gateway 和 VirtualService 具有相同的用途，但有一些关键的区别：

* Istio API 中的 `Gateway` 仅配置已部署的现有网关 Deployment/Service，
  而在 Gateway API 中的 `Gateway` 资源不仅配置也会部署网关。
  有关更多信息，请参阅具体[部署方法](#deployment-methods) 。
* 在 Istio `VirtualService` 中，所有协议都在单一的资源中配置，
* 而在 Gateway API 中，每种协议类型都有自己的资源，例如 `HTTPRoute` 和 `TCPRoute`。
* 虽然 Gateway API  提供了大量丰富的路由功能，但它还没有涵盖 Istio 的全部特性。
  因此，正在进行的工作是扩展 API 以覆盖这些用例，以及利用 API
  的[可拓展性](https://gateway-api.sigs.k8s.io/#gateway-api-concepts)
  来更好地暴露 Istio 的功能。

## 配置网关 {#configuring-a-gateway}

有关 API 的信息，请参阅 [Gateway API](https://gateway-api.sigs.k8s.io/) 文档。

在本例中，我们将部署一个简单的应用程序，并使用 `Gateway` 将其暴露到外部。

1. 首先部署一个 `httpbin` 测试应用：

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. 部署 Gateway API 配置，包括单个暴露的路由（即 `/get`）：

    {{< text bash >}}
    $ kubectl create namespace istio-ingress
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: Gateway
    metadata:
      name: gateway
      namespace: istio-ingress
    spec:
      gatewayClassName: istio
      listeners:
      - name: default
        hostname: "*.example.com"
        port: 80
        protocol: HTTP
        allowedRoutes:
          namespaces:
            from: All
    ---
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-ingress
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: PathPrefix
            value: /get
        backendRefs:
        - name: httpbin
          port: 8000
    EOF
    {{< /text >}}

1.  设置主机 Ingress 环境变量：

    {{< text bash >}}
    $ kubectl wait -n istio-ingress --for=condition=programmed gateways.gateway.networking.k8s.io gateway
    $ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[0].value}')
    {{< /text >}}

1.  使用 *curl* 访问 `httpbin` 服务：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/get"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    请注意，使用 `-H` 标志可以将 *Host* HTTP 标头设置为
    "httpbin.example.com"。这一步是必需的，因为 `HTTPRoute` 已配置为处理 "httpbin.example.com" 的请求，
    但是在测试环境中，该主机没有 DNS 绑定，只是将请求发送到入口 IP。

1.  访问其他没有被显式暴露的 URL 时，将看到 HTTP 404 错误：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

1.  更新路由规则也会暴露 `/headers` 并为请求添加标头：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-ingress
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: PathPrefix
            value: /get
        - path:
            type: PathPrefix
            value: /headers
        filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
            - name: my-added-header
              value: added-value
        backendRefs:
        - name: httpbin
          port: 8000
    EOF
    {{< /text >}}

1.  再次访问 `/headers`，注意到 `My-Added-Header` 标头已被添加到请求：

    {{< text bash >}}
    $ curl -s -HHost:httpbin.example.com "http://$INGRESS_HOST/headers"
    {
      "headers": {
        "Accept": "*/*",
        "Host": "httpbin.example.com",
        "My-Added-Header": "added-value",
    ...
    {{< /text >}}

## 部署方法{#deployment-methods}

在上面的示例中，在配置网关之前，您不需要安装 Ingress 网关 `Deployment`。
因为在默认配置中会根据 `Gateway` 配置自动分发网关 `Deployment` 和 `Service`。
但是对于高级别的用例，仍然允许手动部署。

### 自动部署{#automated-deployment}

默认情况下，每个 `Gateway` 将自动提供相同名称的 `Service` 和 `Deployment`。
如果 `Gateway` 发生变化（例如添加了一个新端口），这些配置将会自动更新。

这些资源可以通过以下几种方式进行定义：

* 将`Gateway` 上的注释和标签复制到 `Service` 和 `Deployment`。
  这就允许配置从上述字段中读取到的内容，
  如配置[内部负载均衡器](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#internal-load-balancer)等。
* Istio 提供了一个额外的注释来配置生成的资源：

    |注解 | 用途                                                         |
    |----------|-------|
    |`networking.istio.io/service-type`|控制 `Service.spec.type` 字段。 例如，设置 `ClusterIP` 为不对外暴露服务，将会默认为`LoadBalancer`。|

* 通过配置 `addresses` 字段可以显式设置 `Service.spec.loadBalancerIP` 字段：

    {{< text yaml >}}
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: Gateway
    metadata:
      name: gateway
    spec:
      addresses:
      - value: 192.0.2.0
        type: IPAddress
    ...
    {{< /text >}}

    请注意：仅能指定一个地址。

* （高级用法）生成的 Pod 配置可以通过[自定义注入模板](/zh/docs/setup/additional-setup/sidecar-injection/#custom-templates-experimental)进行配置。

#### 资源附加和扩缩{#resource-attachment-and-scaling}

{{< warning >}}
资源附加目前是实验性的功能。
{{< /warning >}}

资源可以附加到 `Gateway` 进行自定义。
然而，大多数 Kubernetes 资源目前不支持直接附加到 `Gateway`，
但这些资源可以转为直接被附加到相应生成的 `Deployment` 和 `Service`。
这个操作比较简单，因为这两种资源被生成时名称为 `<gateway name>-<gateway class name>`
且带有标签 `istio.io/gateway-name: <gateway name>`。

例如，参照以下部署类别为 `HorizontalPodAutoscaler` 和 `PodDisruptionBudget` 的 `Gateway`：

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: default
    hostname: "*.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gateway
spec:
  # 通过引用与生成的 Deployment 匹配
  # 注意不要使用 `kind: Gateway`
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gateway-istio
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: gateway
spec:
  minAvailable: 1
  selector:
    # Match the generated Deployment by label
    matchLabels:
      istio.io/gateway-name: gateway
{{< /text >}}

### 手动部署{#manual-deployment}

如果您不希望使用自动部署，可以进行[手动配置](/zh/docs/setup/additional-setup/gateway/) `Deployment` 和 `Service`。

完成此选项后，您将需要手动将 `Gateway` 链接到 `Service`，并保持它们的端口配置同步。

要将 `Gateway` 链接到 `Service`，需要将 `addresses` 字段配置为指向**单个** `Hostname`。

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway
spec:
  addresses:
  - value: ingress.istio-gateways.svc.cluster.local
    type: Hostname
...
{{< /text >}}

## 网格流量{#mesh-traffic}

{{< warning >}}
使用 Gateway API 配置内部网格流量目前是一个还在开发的[实验性特性](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)，
[上游协议](https://gateway-api.sigs.k8s.io/contributing/gamma/)还处于未决（pending）状态。
{{< /warning >}}

Gateway API 也可以用来配置网格流量。
具体做法是配置 `parentRef` 指向一个服务，而不是指向一个 Gateway。

例如，要将所有调用的头部添加到一个名为 `example` 的集群内 `Service`：

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: mesh
spec:
  parentRefs:
  - kind: Service
    name: example
  rules:
  - filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        add:
        - name: my-added-header
          value: added-value
  - backendRefs:
    - name: example
      port: 80
{{< /text >}}

有关更多详情和示例，请参阅其他[流量管理](/zh/docs/tasks/traffic-management/)。

## 清理{#cleanup}

1. 卸载 Istio 和 `httpbin` 示例：

    {{< text bash >}}
    $ kubectl delete -f @samples/httpbin/httpbin.yaml@
    $ kubectl delete httproute http
    $ kubectl delete gateways.gateway.networking.k8s.io gateway -n istio-ingress
    $ istioctl uninstall -y --purge
    $ kubectl delete ns istio-system
    $ kubectl delete ns istio-ingress
    {{< /text >}}

1. 如果不再需要这些 Gateway API CRD 资源，请移除：

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
